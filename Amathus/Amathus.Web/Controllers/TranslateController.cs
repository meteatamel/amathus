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
using System.Net;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Google.Cloud.Translation.V2;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace Amathus.Web.Controllers
{
    public class TranslateRequest
    {
        public string Title { get; set; }
        public string Summary { get; set; }
        public string Detail { get; set; }
        public string SourceLanguage { get; set; }
        public string TargetLanguage { get; set; }
    }

    public class TranslateResponse
    {
        public string Title { get; set; }
        public string Summary { get; set; }
        public string Detail { get; set; }
        public string SourceLanguage { get; set; }
        public string TargetLanguage { get; set; }
    }

    [Route("api/v1/[controller]")]
    [ApiController]
    public class TranslateController : ControllerBase
    {
        private static readonly HashSet<string> SupportedLanguages = new(StringComparer.OrdinalIgnoreCase)
        {
            "tr", "el", "en"
        };

        private static readonly ConcurrentDictionary<string, TranslateResponse> Cache = new();
        private static readonly HttpClient FallbackHttpClient = new()
        {
            Timeout = TimeSpan.FromSeconds(15)
        };

        private static TranslationClient _translationClient;
        private static bool _clientInitAttempted;
        private static readonly object ClientLock = new();

        private readonly ILogger<TranslateController> _logger;

        public TranslateController(ILogger<TranslateController> logger)
        {
            _logger = logger;
        }

        private TranslationClient GetTranslationClient()
        {
            if (_clientInitAttempted)
            {
                return _translationClient;
            }

            lock (ClientLock)
            {
                if (_clientInitAttempted)
                {
                    return _translationClient;
                }

                try
                {
                    _translationClient = TranslationClient.Create();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Could not initialize Cloud Translation V2 client via ADC, will use Google Translate HTTP endpoint: {ex.Message}");
                    _translationClient = null;
                }
                finally
                {
                    _clientInitAttempted = true;
                }

                return _translationClient;
            }
        }

        [HttpPost]
        public async Task<ActionResult<TranslateResponse>> Post([FromBody] TranslateRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.TargetLanguage))
            {
                return BadRequest("TargetLanguage is required.");
            }

            var targetLang = request.TargetLanguage.Trim().ToLowerInvariant();
            if (!SupportedLanguages.Contains(targetLang))
            {
                return BadRequest("Unsupported TargetLanguage. Use 'tr', 'el', or 'en'.");
            }

            var sourceLang = string.IsNullOrWhiteSpace(request.SourceLanguage)
                ? null
                : request.SourceLanguage.Trim().ToLowerInvariant();
            if (sourceLang != null && !SupportedLanguages.Contains(sourceLang))
            {
                sourceLang = null;
            }

            if (sourceLang == targetLang)
            {
                return Ok(new TranslateResponse
                {
                    Title = request.Title ?? string.Empty,
                    Summary = request.Summary ?? string.Empty,
                    Detail = request.Detail ?? string.Empty,
                    SourceLanguage = sourceLang,
                    TargetLanguage = targetLang
                });
            }

            var cacheKey = ComputeCacheKey(request, sourceLang, targetLang);
            if (Cache.TryGetValue(cacheKey, out var cached))
            {
                return Ok(cached);
            }

            try
            {
                var response = await TranslateContentAsync(request, sourceLang, targetLang);
                if (Cache.Count > 2000)
                {
                    Cache.Clear();
                }
                Cache[cacheKey] = response;
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Translation failed for targetLanguage={targetLang}");
                return StatusCode(500, "Translation failed.");
            }
        }

        private async Task<TranslateResponse> TranslateContentAsync(
            TranslateRequest request,
            string sourceLang,
            string targetLang)
        {
            var client = GetTranslationClient();
            if (client != null)
            {
                try
                {
                    string translatedTitle = string.Empty;
                    string translatedSummary = string.Empty;
                    string translatedDetail = string.Empty;
                    string detectedSource = sourceLang;

                    if (!string.IsNullOrWhiteSpace(request.Title))
                    {
                        var res = await client.TranslateTextAsync(request.Title, targetLang, sourceLang);
                        translatedTitle = WebUtility.HtmlDecode(res.TranslatedText);
                        detectedSource ??= res.DetectedSourceLanguage;
                    }

                    if (!string.IsNullOrWhiteSpace(request.Summary))
                    {
                        var res = await client.TranslateTextAsync(request.Summary, targetLang, sourceLang);
                        translatedSummary = WebUtility.HtmlDecode(res.TranslatedText);
                        detectedSource ??= res.DetectedSourceLanguage;
                    }

                    if (!string.IsNullOrWhiteSpace(request.Detail))
                    {
                        var res = await client.TranslateHtmlAsync(request.Detail, targetLang, sourceLang);
                        translatedDetail = res.TranslatedText;
                        detectedSource ??= res.DetectedSourceLanguage;
                    }

                    return new TranslateResponse
                    {
                        Title = translatedTitle,
                        Summary = translatedSummary,
                        Detail = translatedDetail,
                        SourceLanguage = detectedSource ?? sourceLang ?? "auto",
                        TargetLanguage = targetLang
                    };
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Cloud Translation V2 API call failed, falling back to Google Translate GTX endpoint: {ex.Message}");
                }
            }

            // Fallback to Google Translate endpoint
            var fallbackTitle = !string.IsNullOrWhiteSpace(request.Title)
                ? await TranslateViaGtxAsync(request.Title, sourceLang, targetLang)
                : string.Empty;
            var fallbackSummary = !string.IsNullOrWhiteSpace(request.Summary)
                ? await TranslateViaGtxAsync(request.Summary, sourceLang, targetLang)
                : string.Empty;
            var fallbackDetail = !string.IsNullOrWhiteSpace(request.Detail)
                ? await TranslateViaGtxAsync(request.Detail, sourceLang, targetLang)
                : string.Empty;

            return new TranslateResponse
            {
                Title = fallbackTitle,
                Summary = fallbackSummary,
                Detail = fallbackDetail,
                SourceLanguage = sourceLang ?? "auto",
                TargetLanguage = targetLang
            };
        }

        private static async Task<string> TranslateViaGtxAsync(string text, string sourceLang, string targetLang)
        {
            var sl = string.IsNullOrWhiteSpace(sourceLang) ? "auto" : sourceLang;
            var url = $"https://translate.googleapis.com/translate_a/single?client=gtx&sl={Uri.EscapeDataString(sl)}&tl={Uri.EscapeDataString(targetLang)}&dt=t&q={Uri.EscapeDataString(text)}";
            using var response = await FallbackHttpClient.GetAsync(url);
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
            return sb.ToString();
        }

        private static string ComputeCacheKey(TranslateRequest req, string sourceLang, string targetLang)
        {
            var raw = $"{sourceLang ?? "auto"}->{targetLang}|{req.Title}|{req.Summary}|{req.Detail}";
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(raw));
            return Convert.ToHexString(bytes);
        }
    }
}
