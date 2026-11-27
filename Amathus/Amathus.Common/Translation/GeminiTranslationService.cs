// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Amathus.Common.FeedStore;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Amathus.Common.Translation
{
    public class ArticleTranslationResult
    {
        public string Title { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public string Detail { get; set; } = string.Empty;
        public string SourceLanguage { get; set; } = "auto";
        public string TargetLanguage { get; set; } = string.Empty;
    }

    public class GeminiBatchTranslationOutput
    {
        [JsonProperty("detectedSourceLanguage")]
        public string DetectedSourceLanguage { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; }

        [JsonProperty("summary")]
        public string Summary { get; set; }

        [JsonProperty("detail")]
        public string Detail { get; set; }
    }

    /// <summary>
    /// Shared translation service backed by Gemini 3.5 Flash-Lite (Vertex AI global endpoint)
    /// with per-field L1 in-memory + L2 persistent (Firestore) caching, in-flight deduplication,
    /// HTML sanitization to minimize token usage, and free GTX fallback.
    /// </summary>
    public static class GeminiTranslationService
    {
        public const string DefaultModelId = "gemini-3.5-flash-lite";
        private const string CacheVersion = "v2";
        private const int MaxMemoryCacheEntries = 10000;

        private static readonly HttpClient GeminiHttp = new()
        {
            Timeout = TimeSpan.FromSeconds(45)
        };

        private static readonly HttpClient FallbackHttp = new()
        {
            Timeout = TimeSpan.FromSeconds(15)
        };

        private static readonly ConcurrentDictionary<string, CachedFieldValue> MemoryCache = new();
        private static readonly ConcurrentDictionary<string, Task<CachedFieldValue>> InFlightFields = new();

        private static readonly Regex ScriptStyleRegex = new(
            @"<(script|style|noscript|iframe|svg|object|embed)\b[^>]*>.*?</\1>",
            RegexOptions.IgnoreCase | RegexOptions.Singleline | RegexOptions.Compiled);

        private static readonly Regex HtmlCommentRegex = new(
            @"<!--.*?-->",
            RegexOptions.Singleline | RegexOptions.Compiled);

        private static readonly Regex HtmlTagRegex = new(
            @"<(/?)([a-zA-Z0-9]+)(\s[^>]*)?>",
            RegexOptions.Singleline | RegexOptions.Compiled);

        private static readonly Regex HrefAttrRegex = new(
            @"\bhref\s*=\s*(?:""([^""]*)""|'([^']*)'|([^\s>]+))",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex SrcAttrRegex = new(
            @"\bsrc\s*=\s*(?:""([^""]*)""|'([^']*)'|([^\s>]+))",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex MultiWhitespaceRegex = new(
            @"[ \t\r\n]+",
            RegexOptions.Compiled);

        private static readonly HashSet<string> AllowedHtmlTags = new(StringComparer.OrdinalIgnoreCase)
        {
            "p", "br", "a", "b", "strong", "i", "em", "u",
            "ul", "ol", "li", "blockquote", "h1", "h2", "h3", "h4", "img", "div", "span"
        };

        private static readonly SemaphoreSlim CredentialLock = new(1, 1);
        private static GoogleCredential _cachedCredential;

        private static string _projectId = "events-atamel";
        private static IFeedStore _persistentStore;
        private static ILogger _logger;

        // Optional test hook for unit tests to intercept model calls without hitting the network.
        internal static Func<string, string, string, string, string, Task<GeminiBatchTranslationOutput>> TestBatchTranslator { get; set; }

        private sealed class CachedFieldValue
        {
            public string Text { get; set; } = string.Empty;
            public string SourceLanguage { get; set; } = "auto";
        }

        public static void Configure(string projectId = null, IFeedStore store = null, ILogger logger = null)
        {
            if (!string.IsNullOrWhiteSpace(projectId))
            {
                _projectId = projectId.Trim();
            }
            if (store != null)
            {
                _persistentStore = store;
            }
            if (logger != null)
            {
                _logger = logger;
            }
        }

        internal static void ClearMemoryCacheForTests()
        {
            MemoryCache.Clear();
            InFlightFields.Clear();
        }

        /// <summary>
        /// Strips scripts, styles, comments, and redundant CMS attributes from HTML while keeping
        /// clean semantic tags and links/images so far fewer tokens are sent for translation.
        /// </summary>
        public static string SanitizeHtmlForTranslation(string html)
        {
            if (string.IsNullOrWhiteSpace(html))
            {
                return string.Empty;
            }

            var cleaned = ScriptStyleRegex.Replace(html, " ");
            cleaned = HtmlCommentRegex.Replace(cleaned, " ");
            cleaned = HtmlTagRegex.Replace(cleaned, match =>
            {
                var isClosing = match.Groups[1].Value == "/";
                var tagName = match.Groups[2].Value.ToLowerInvariant();
                var attrs = match.Groups[3].Value;

                if (!AllowedHtmlTags.Contains(tagName))
                {
                    return " ";
                }

                if (isClosing)
                {
                    return tagName == "br" || tagName == "img" ? string.Empty : $"</{tagName}>";
                }

                if (tagName == "br")
                {
                    return "<br>";
                }

                if (tagName == "a" && !string.IsNullOrWhiteSpace(attrs))
                {
                    var hrefMatch = HrefAttrRegex.Match(attrs);
                    if (hrefMatch.Success)
                    {
                        var href = hrefMatch.Groups[1].Success ? hrefMatch.Groups[1].Value
                            : hrefMatch.Groups[2].Success ? hrefMatch.Groups[2].Value
                            : hrefMatch.Groups[3].Value;
                        if (!string.IsNullOrWhiteSpace(href) &&
                            (href.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                             href.StartsWith("https://", StringComparison.OrdinalIgnoreCase)))
                        {
                            return $"<a href=\"{href}\">";
                        }
                    }
                }

                if (tagName == "img" && !string.IsNullOrWhiteSpace(attrs))
                {
                    var srcMatch = SrcAttrRegex.Match(attrs);
                    if (srcMatch.Success)
                    {
                        var src = srcMatch.Groups[1].Success ? srcMatch.Groups[1].Value
                            : srcMatch.Groups[2].Success ? srcMatch.Groups[2].Value
                            : srcMatch.Groups[3].Value;
                        if (!string.IsNullOrWhiteSpace(src) &&
                            (src.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                             src.StartsWith("https://", StringComparison.OrdinalIgnoreCase)))
                        {
                            return $"<img src=\"{src}\">";
                        }
                    }
                    return string.Empty;
                }

                return $"<{tagName}>";
            });

            cleaned = MultiWhitespaceRegex.Replace(cleaned, " ").Trim();
            return cleaned;
        }

        /// <summary>
        /// Translates a single plain-text string (e.g. headline or overview snippet) using the
        /// shared per-field L1 + L2 cache and Gemini 3.5 Flash-Lite.
        /// </summary>
        public static async Task<string> TranslateTextAsync(
            string text,
            string sourceLang,
            string targetLang,
            IFeedStore storeOverride = null,
            ILogger loggerOverride = null)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }

            var normSource = NormalizeLang(sourceLang);
            var normTarget = NormalizeLang(targetLang);
            if (string.IsNullOrEmpty(normTarget) || normSource == normTarget)
            {
                return text;
            }

            var result = await TranslateArticleAsync(
                title: text,
                summary: null,
                detail: null,
                sourceLang: normSource,
                targetLang: normTarget,
                storeOverride: storeOverride,
                loggerOverride: loggerOverride);

            return string.IsNullOrWhiteSpace(result?.Title) ? text : result.Title;
        }

        /// <summary>
        /// Translates an article's Title, Summary, and/or HTML Detail.
        /// Each field is cached independently so opening an article reuses already-cached Title/Summary,
        /// and any uncached fields are translated together in a single Gemini 3.5 Flash-Lite call.
        /// </summary>
        public static async Task<ArticleTranslationResult> TranslateArticleAsync(
            string title,
            string summary,
            string detail,
            string sourceLang,
            string targetLang,
            IFeedStore storeOverride = null,
            ILogger loggerOverride = null)
        {
            var normSource = NormalizeLang(sourceLang);
            var normTarget = NormalizeLang(targetLang);
            var store = storeOverride ?? _persistentStore;
            var logger = loggerOverride ?? _logger;

            if (string.IsNullOrEmpty(normTarget) || normSource == normTarget)
            {
                return new ArticleTranslationResult
                {
                    Title = title ?? string.Empty,
                    Summary = summary ?? string.Empty,
                    Detail = detail ?? string.Empty,
                    SourceLanguage = normSource ?? "auto",
                    TargetLanguage = normTarget ?? string.Empty
                };
            }

            var hasTitle = !string.IsNullOrWhiteSpace(title);
            var hasSummary = !string.IsNullOrWhiteSpace(summary);
            var sanitizedDetail = !string.IsNullOrWhiteSpace(detail)
                ? SanitizeHtmlForTranslation(detail)
                : string.Empty;
            var hasDetail = !string.IsNullOrWhiteSpace(sanitizedDetail);

            var titleKey = hasTitle ? ComputeFieldCacheKey("text", normSource, normTarget, title) : null;
            var summaryKey = hasSummary ? ComputeFieldCacheKey("text", normSource, normTarget, summary) : null;
            var detailKey = hasDetail ? ComputeFieldCacheKey("html", normSource, normTarget, sanitizedDetail) : null;

            // 1. Check L1 in-memory cache and L2 persistent cache independently per field.
            var cachedTitle = hasTitle ? await TryReadFieldCacheAsync(titleKey, store, logger) : null;
            var cachedSummary = hasSummary ? await TryReadFieldCacheAsync(summaryKey, store, logger) : null;
            var cachedDetail = hasDetail ? await TryReadFieldCacheAsync(detailKey, store, logger) : null;

            var needTitle = hasTitle && cachedTitle == null;
            var needSummary = hasSummary && cachedSummary == null;
            var needDetail = hasDetail && cachedDetail == null;

            string detectedSource = normSource
                ?? ValidLangOrNull(cachedTitle?.SourceLanguage)
                ?? ValidLangOrNull(cachedSummary?.SourceLanguage)
                ?? ValidLangOrNull(cachedDetail?.SourceLanguage);

            // 2. If all requested fields were cache hits, return immediately (0 model tokens).
            if (!needTitle && !needSummary && !needDetail)
            {
                return new ArticleTranslationResult
                {
                    Title = cachedTitle?.Text ?? string.Empty,
                    Summary = cachedSummary?.Text ?? string.Empty,
                    Detail = cachedDetail?.Text ?? string.Empty,
                    SourceLanguage = detectedSource ?? "auto",
                    TargetLanguage = normTarget
                };
            }

            // 3. Translate all uncached fields together in ONE Gemini 3.5 Flash-Lite call,
            // deduplicating concurrent requests for the same field.
            var pendingTitle = needTitle ? title : null;
            var pendingSummary = needSummary ? summary : null;
            var pendingDetail = needDetail ? sanitizedDetail : null;

            // If only a single field is uncached, deduplicate directly via InFlightFields.
            int missingCount = (needTitle ? 1 : 0) + (needSummary ? 1 : 0) + (needDetail ? 1 : 0);
            if (missingCount == 1)
            {
                var singleKey = needTitle ? titleKey : (needSummary ? summaryKey : detailKey);
                var singleTask = InFlightFields.GetOrAdd(singleKey, _ => TranslateSingleFieldUncachedAsync(
                    singleKey,
                    pendingTitle,
                    pendingSummary,
                    pendingDetail,
                    normSource,
                    normTarget,
                    store,
                    logger));
                try
                {
                    var singleResult = await singleTask;
                    if (needTitle) cachedTitle = singleResult;
                    else if (needSummary) cachedSummary = singleResult;
                    else cachedDetail = singleResult;
                    detectedSource ??= ValidLangOrNull(singleResult?.SourceLanguage);
                }
                finally
                {
                    InFlightFields.TryRemove(singleKey, out _);
                }
            }
            else
            {
                var batchOutput = await TranslateBatchWithFallbackAsync(
                    pendingTitle,
                    pendingSummary,
                    pendingDetail,
                    normSource,
                    normTarget,
                    logger);

                var resolvedSource = ValidLangOrNull(batchOutput.DetectedSourceLanguage) ?? detectedSource ?? "auto";
                detectedSource ??= ValidLangOrNull(resolvedSource);

                var saveTasks = new List<Task>(3);
                if (needTitle && !string.IsNullOrWhiteSpace(batchOutput.Title))
                {
                    cachedTitle = new CachedFieldValue { Text = batchOutput.Title, SourceLanguage = resolvedSource };
                    saveTasks.Add(SaveFieldCacheAsync(titleKey, cachedTitle, normTarget, store, logger));
                }
                if (needSummary && !string.IsNullOrWhiteSpace(batchOutput.Summary))
                {
                    cachedSummary = new CachedFieldValue { Text = batchOutput.Summary, SourceLanguage = resolvedSource };
                    saveTasks.Add(SaveFieldCacheAsync(summaryKey, cachedSummary, normTarget, store, logger));
                }
                if (needDetail && !string.IsNullOrWhiteSpace(batchOutput.Detail))
                {
                    cachedDetail = new CachedFieldValue { Text = batchOutput.Detail, SourceLanguage = resolvedSource };
                    saveTasks.Add(SaveFieldCacheAsync(detailKey, cachedDetail, normTarget, store, logger));
                }

                if (saveTasks.Count > 0)
                {
                    await Task.WhenAll(saveTasks);
                }
            }

            return new ArticleTranslationResult
            {
                Title = hasTitle ? (cachedTitle?.Text ?? title) : string.Empty,
                Summary = hasSummary ? (cachedSummary?.Text ?? summary) : string.Empty,
                Detail = hasDetail ? (cachedDetail?.Text ?? sanitizedDetail) : string.Empty,
                SourceLanguage = detectedSource ?? "auto",
                TargetLanguage = normTarget
            };
        }

        private static async Task<CachedFieldValue> TranslateSingleFieldUncachedAsync(
            string fieldKey,
            string title,
            string summary,
            string detail,
            string sourceLang,
            string targetLang,
            IFeedStore store,
            ILogger logger)
        {
            var batchOutput = await TranslateBatchWithFallbackAsync(title, summary, detail, sourceLang, targetLang, logger);
            var text = title != null
                ? batchOutput.Title
                : (summary != null ? batchOutput.Summary : batchOutput.Detail);
            var resolvedSource = ValidLangOrNull(batchOutput.DetectedSourceLanguage) ?? sourceLang ?? "auto";

            var value = new CachedFieldValue
            {
                Text = text ?? string.Empty,
                SourceLanguage = resolvedSource
            };

            if (!string.IsNullOrWhiteSpace(value.Text))
            {
                await SaveFieldCacheAsync(fieldKey, value, targetLang, store, logger);
            }

            return value;
        }

        private static async Task<GeminiBatchTranslationOutput> TranslateBatchWithFallbackAsync(
            string title,
            string summary,
            string detail,
            string sourceLang,
            string targetLang,
            ILogger logger)
        {
            if (TestBatchTranslator != null)
            {
                return await TestBatchTranslator(title, summary, detail, sourceLang, targetLang);
            }

            try
            {
                var geminiResult = await TranslateBatchViaGeminiAsync(title, summary, detail, sourceLang, targetLang, logger);
                if (geminiResult != null)
                {
                    return geminiResult;
                }
            }
            catch (Exception ex)
            {
                logger?.LogWarning($"Gemini {DefaultModelId} translation failed, falling back to GTX endpoint: {ex.Message}");
            }

            // Free GTX fallback if Vertex AI / Gemini API is unavailable
            var fallbackTitle = !string.IsNullOrWhiteSpace(title)
                ? await TranslateViaGtxAsync(title, sourceLang, targetLang)
                : null;
            var fallbackSummary = !string.IsNullOrWhiteSpace(summary)
                ? await TranslateViaGtxAsync(summary, sourceLang, targetLang)
                : null;
            var fallbackDetail = !string.IsNullOrWhiteSpace(detail)
                ? await TranslateViaGtxAsync(detail, sourceLang, targetLang)
                : null;

            return new GeminiBatchTranslationOutput
            {
                DetectedSourceLanguage = sourceLang ?? "auto",
                Title = fallbackTitle,
                Summary = fallbackSummary,
                Detail = fallbackDetail
            };
        }

        private static async Task<GeminiBatchTranslationOutput> TranslateBatchViaGeminiAsync(
            string title,
            string summary,
            string detail,
            string sourceLang,
            string targetLang,
            ILogger logger)
        {
            var payload = new JObject();
            if (!string.IsNullOrWhiteSpace(title)) payload["title"] = title;
            if (!string.IsNullOrWhiteSpace(summary)) payload["summary"] = summary;
            if (!string.IsNullOrWhiteSpace(detail)) payload["detail"] = detail;

            var targetName = LanguageDisplayName(targetLang);
            var sourceHint = !string.IsNullOrWhiteSpace(sourceLang)
                ? $"Source language: {LanguageDisplayName(sourceLang)} ({sourceLang})."
                : "Detect the source language automatically (usually Turkish 'tr', Greek 'el', or English 'en').";

            var systemPrompt =
                $"You are a fast, accurate Cyprus news translator. Translate every non-null field in the input JSON into natural {targetName} ({targetLang}). " +
                $"{sourceHint} " +
                "Preserve proper nouns, organization names, numbers, and any HTML tags (such as <p>, <br>, <a>, <b>, <i>, <ul>, <li>, <img>) in the 'detail' field without adding commentary. " +
                "Return ONLY a JSON object with keys: detectedSourceLanguage (2-letter ISO code like 'tr', 'el', or 'en'), and the translated keys present in the input ('title', 'summary', 'detail').";

            var requestBody = new
            {
                systemInstruction = new
                {
                    parts = new[] { new { text = systemPrompt } }
                },
                contents = new[]
                {
                    new
                    {
                        role = "user",
                        parts = new[] { new { text = payload.ToString(Formatting.None) } }
                    }
                },
                generationConfig = new
                {
                    responseMimeType = "application/json",
                    thinkingConfig = new
                    {
                        thinkingLevel = "MINIMAL"
                    }
                }
            };

            string url;
            string bearerToken = null;
            var apiKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
            if (!string.IsNullOrWhiteSpace(apiKey))
            {
                url = $"https://generativelanguage.googleapis.com/v1beta/models/{DefaultModelId}:generateContent?key={Uri.EscapeDataString(apiKey)}";
            }
            else
            {
                bearerToken = await GetAccessTokenAsync();
                if (string.IsNullOrWhiteSpace(bearerToken))
                {
                    return null;
                }
                url = $"https://aiplatform.googleapis.com/v1/projects/{_projectId}/locations/global/publishers/google/models/{DefaultModelId}:generateContent";
            }

            using var req = new HttpRequestMessage(HttpMethod.Post, url)
            {
                Content = new StringContent(JsonConvert.SerializeObject(requestBody), Encoding.UTF8, "application/json")
            };
            if (!string.IsNullOrWhiteSpace(bearerToken))
            {
                req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);
            }

            using var resp = await GeminiHttp.SendAsync(req);
            var body = await resp.Content.ReadAsStringAsync();
            if (!resp.IsSuccessStatusCode)
            {
                throw new HttpRequestException($"HTTP {(int)resp.StatusCode}: {body.Substring(0, Math.Min(body.Length, 300))}");
            }

            var root = JObject.Parse(body);
            var text = root["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]?.ToString();
            if (string.IsNullOrWhiteSpace(text))
            {
                return null;
            }

            var cleanedJson = CleanJsonFence(text);
            var parsed = JsonConvert.DeserializeObject<GeminiBatchTranslationOutput>(cleanedJson);
            if (parsed == null)
            {
                return null;
            }

            // Ensure requested fields were actually returned
            if ((!string.IsNullOrWhiteSpace(title) && string.IsNullOrWhiteSpace(parsed.Title)) ||
                (!string.IsNullOrWhiteSpace(summary) && string.IsNullOrWhiteSpace(parsed.Summary)) ||
                (!string.IsNullOrWhiteSpace(detail) && string.IsNullOrWhiteSpace(parsed.Detail)))
            {
                logger?.LogWarning($"Gemini {DefaultModelId} returned incomplete translation JSON; falling back.");
                return null;
            }

            return parsed;
        }

        private static async Task<string> GetAccessTokenAsync()
        {
            if (_cachedCredential == null)
            {
                await CredentialLock.WaitAsync();
                try
                {
                    if (_cachedCredential == null)
                    {
                        var credential = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("K_SERVICE"))
                            ? GoogleCredential.FromComputeCredential()
                            : await GoogleCredential.GetApplicationDefaultAsync();

                        if (credential.IsCreateScopedRequired)
                        {
                            credential = credential.CreateScoped("https://www.googleapis.com/auth/cloud-platform");
                        }

                        _cachedCredential = credential;
                    }
                }
                finally
                {
                    CredentialLock.Release();
                }
            }

            return await ((ITokenAccess)_cachedCredential).GetAccessTokenForRequestAsync();
        }

        private static async Task<CachedFieldValue> TryReadFieldCacheAsync(string key, IFeedStore store, ILogger logger)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                return null;
            }

            if (MemoryCache.TryGetValue(key, out var memHit))
            {
                return memHit;
            }

            if (store != null)
            {
                try
                {
                    var persisted = await store.ReadTranslationAsync(key);
                    if (persisted != null && !string.IsNullOrEmpty(persisted.Title))
                    {
                        var val = new CachedFieldValue
                        {
                            Text = persisted.Title,
                            SourceLanguage = persisted.SourceLanguage ?? "auto"
                        };
                        StoreInMemory(key, val);
                        return val;
                    }
                }
                catch (Exception ex)
                {
                    logger?.LogWarning($"Failed to read translation from persistent cache: {ex.Message}");
                }
            }

            return null;
        }

        private static async Task SaveFieldCacheAsync(
            string key,
            CachedFieldValue value,
            string targetLang,
            IFeedStore store,
            ILogger logger)
        {
            if (string.IsNullOrWhiteSpace(key) || value == null || string.IsNullOrWhiteSpace(value.Text))
            {
                return;
            }

            StoreInMemory(key, value);

            if (store != null)
            {
                try
                {
                    await store.SaveTranslationAsync(new CachedTranslation
                    {
                        Id = key,
                        Title = value.Text,
                        SourceLanguage = value.SourceLanguage ?? "auto",
                        TargetLanguage = targetLang,
                        CreatedAt = DateTime.UtcNow,
                        ExpiresAt = DateTime.UtcNow.AddDays(7)
                    });
                }
                catch (Exception ex)
                {
                    logger?.LogWarning($"Failed to write translation to persistent cache: {ex.Message}");
                }
            }
        }

        private static void StoreInMemory(string key, CachedFieldValue value)
        {
            if (MemoryCache.Count > MaxMemoryCacheEntries)
            {
                MemoryCache.Clear();
            }
            MemoryCache[key] = value;
        }

        private static async Task<string> TranslateViaGtxAsync(string text, string sourceLang, string targetLang)
        {
            var sl = string.IsNullOrWhiteSpace(sourceLang) ? "auto" : sourceLang;
            var url = $"https://translate.googleapis.com/translate_a/single?client=gtx&sl={Uri.EscapeDataString(sl)}&tl={Uri.EscapeDataString(targetLang)}&dt=t&q={Uri.EscapeDataString(text)}";
            using var response = await FallbackHttp.GetAsync(url);
            response.EnsureSuccessStatusCode();
            var json = await response.Content.ReadAsStringAsync();
            var arr = JArray.Parse(json);
            var sentences = arr[0] as JArray;
            if (sentences == null)
            {
                return text;
            }

            var sb = new StringBuilder();
            foreach (var item in sentences)
            {
                var segment = item?[0]?.ToString();
                if (!string.IsNullOrEmpty(segment))
                {
                    sb.Append(segment);
                }
            }

            var translated = sb.ToString().Trim();
            return string.IsNullOrEmpty(translated) ? text : translated;
        }

        public static string ComputeFieldCacheKey(string kind, string sourceLang, string targetLang, string text)
        {
            var raw = $"{CacheVersion}|{kind}|{sourceLang ?? "auto"}->{targetLang}|{text}";
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(raw));
            return Convert.ToHexString(bytes);
        }

        private static string NormalizeLang(string lang)
        {
            if (string.IsNullOrWhiteSpace(lang))
            {
                return null;
            }
            var trimmed = lang.Trim().ToLowerInvariant();
            return trimmed is "tr" or "el" or "en" ? trimmed : null;
        }

        private static string ValidLangOrNull(string lang)
        {
            return NormalizeLang(lang);
        }

        private static string LanguageDisplayName(string code)
        {
            return code switch
            {
                "tr" => "Turkish",
                "el" => "Greek",
                "en" => "English",
                _ => code
            };
        }

        private static string CleanJsonFence(string text)
        {
            var trimmed = text.Trim();
            if (trimmed.StartsWith("```"))
            {
                var firstNewline = trimmed.IndexOf('\n');
                if (firstNewline >= 0)
                {
                    trimmed = trimmed.Substring(firstNewline + 1);
                }
                if (trimmed.EndsWith("```"))
                {
                    trimmed = trimmed.Substring(0, trimmed.Length - 3);
                }
            }
            return trimmed.Trim();
        }
    }
}
