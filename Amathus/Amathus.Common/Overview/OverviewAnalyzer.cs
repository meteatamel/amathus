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
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Amathus.Common.Feeds;
using Amathus.Common.Util;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Translation.V2;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Amathus.Common.Overview
{
    public class OverviewAnalyzer : IOverviewAnalyzer
    {
        private static readonly HttpClient Http = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(180)
        };

        private static readonly HttpClient TranslateHttp = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(15)
        };

        private static readonly ConcurrentDictionary<string, string> TranslationCache = new();
        private static readonly Regex GreekScriptRegex = new(@"[\u0370-\u03FF\u1F00-\u1FFF]", RegexOptions.Compiled);
        private static readonly Regex TurkishSpecificRegex = new(@"[ğĞşŞıİ]", RegexOptions.Compiled);
        private static readonly Regex LegacyReportsPrefixRegex = new(@"(?:^|\s)[^:.]{1,40}\s+reports:\s*", RegexOptions.IgnoreCase | RegexOptions.Compiled);
        private static readonly Regex LegacyCoveredBySuffixRegex = new(@"\s*Covered by\s+[^.]+\.?\s*$", RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static TranslationClient _translationClient;
        private static bool _clientInitAttempted;
        private static readonly object ClientLock = new();

        private static TranslationClient GetTranslationClient()
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
                catch
                {
                    _translationClient = null;
                }
                finally
                {
                    _clientInitAttempted = true;
                }

                return _translationClient;
            }
        }

        private static readonly HashSet<string> StopWords = new(StringComparer.OrdinalIgnoreCase)
        {
            "the", "and", "for", "that", "this", "with", "from", "have", "has", "had", "will", "would",
            "could", "should", "about", "after", "before", "into", "over", "under", "between", "through",
            "during", "without", "within", "along", "following", "across", "behind", "beyond", "plus",
            "except", "but", "not", "are", "was", "were", "been", "being", "their", "there", "they",
            "them", "then", "than", "when", "where", "which", "while", "who", "whom", "whose", "what",
            "why", "how", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such",
            "only", "own", "same", "so", "too", "very", "can", "just", "now", "new", "news", "cyprus",
            "cypriot", "north", "northern", "south", "southern", "turkish", "greek", "trnc", "kktc",
            "kibris", "kıbrıs", "said", "says", "also", "today", "yesterday", "year", "years", "first",
            "two", "three", "one", "made", "make", "held", "statement", "stated", "announced", "report",
            "reported", "according", "minister", "president", "government", "island", "state", "country",
            "people", "time", "day", "week", "month", "part", "place", "work", "high", "public"
        };

        private readonly string _projectId;
        private readonly string _location;
        private readonly ILogger _logger;

        public OverviewAnalyzer(string projectId = "events-atamel", ILogger logger = null, string location = "europe-west1")
        {
            _projectId = string.IsNullOrWhiteSpace(projectId) ? "events-atamel" : projectId;
            _location = string.IsNullOrWhiteSpace(location) ? "europe-west1" : location;
            _logger = logger;
        }

        private class CandidateArticle
        {
            public int Index { get; set; }
            public Feed Feed { get; set; }
            public FeedItem Item { get; set; }
            public string Language { get; set; }
            public int GeoTier { get; set; }
            public string EnglishTitle { get; set; }
            public string EnglishSummary { get; set; }
            public HashSet<string> Tokens { get; set; } = new(StringComparer.OrdinalIgnoreCase);
        }

        private class GeminiOverviewResult
        {
            [JsonProperty("summaryEn")]
            public string SummaryEn { get; set; }

            [JsonProperty("summaryTr")]
            public string SummaryTr { get; set; }

            [JsonProperty("summaryEl")]
            public string SummaryEl { get; set; }

            [JsonProperty("stories")]
            public List<GeminiStoryItem> Stories { get; set; }

            [JsonProperty("podcastTurns")]
            public List<GeminiPodcastTurnItem> PodcastTurns { get; set; }
        }

        private class GeminiPodcastTurnItem
        {
            [JsonProperty("speaker")]
            public string Speaker { get; set; }

            [JsonProperty("textEn")]
            public string TextEn { get; set; }

            [JsonProperty("textTr")]
            public string TextTr { get; set; }

            [JsonProperty("textEl")]
            public string TextEl { get; set; }
        }

        private class GeminiStoryItem
        {
            [JsonProperty("titleEn")]
            public string TitleEn { get; set; }

            [JsonProperty("titleTr")]
            public string TitleTr { get; set; }

            [JsonProperty("titleEl")]
            public string TitleEl { get; set; }

            [JsonProperty("narrativeEn")]
            public string NarrativeEn { get; set; }

            [JsonProperty("narrativeTr")]
            public string NarrativeTr { get; set; }

            [JsonProperty("narrativeEl")]
            public string NarrativeEl { get; set; }

            [JsonProperty("topic")]
            public string Topic { get; set; }

            [JsonProperty("articleIndices")]
            public List<int> ArticleIndices { get; set; }
        }

        public async Task<NewsOverview> AnalyzeAsync(List<Feed> feeds, bool columnistsOnly = false)
        {
            var overviewId = columnistsOnly ? "latest_columnists" : "latest";
            var validFeeds = (feeds ?? new List<Feed>())
                .Where(f => f?.Items != null && f.Items.Count > 0)
                .ToList();

            var candidates = CollectCandidates(validFeeds, columnistsOnly);
            var totalArticles = validFeeds.Sum(f => f.Items?.Count(i => i != null && i.IsColumnist == columnistsOnly) ?? 0);

            _logger?.LogInformation($"Analyzing overview (columnistsOnly={columnistsOnly}) across {validFeeds.Count} feeds ({candidates.Count} candidate articles out of {totalArticles} total).");

            if (candidates.Count == 0)
            {
                return new NewsOverview
                {
                    Id = overviewId,
                    GeneratedAt = DateTime.UtcNow,
                    TotalFeedsAnalyzed = validFeeds.Count,
                    TotalArticlesAnalyzed = 0,
                    SummaryEn = "No stories are available for analysis yet.",
                    SummaryTr = "Henüz analiz edilecek içerik bulunamadı.",
                    SummaryEl = "Δεν υπάρχουν ακόμη διαθέσιμα άρθρα για ανάλυση.",
                    Stories = new List<OverviewStory>()
                };
            }

            // 1. Try Gemini via Vertex AI (or GEMINI_API_KEY)
            try
            {
                var geminiOverview = await TryAnalyzeWithGeminiAsync(candidates, validFeeds.Count, totalArticles, columnistsOnly);
                if (geminiOverview != null && geminiOverview.Stories != null && geminiOverview.Stories.Count > 0)
                {
                    geminiOverview.Id = overviewId;
                    PodcastScriptBuilder.EnsurePodcastPopulated(geminiOverview);
                    _logger?.LogInformation($"Successfully generated overview (columnistsOnly={columnistsOnly}) via Gemini with {geminiOverview.Stories.Count} top stories.");
                    return geminiOverview;
                }
            }
            catch (Exception ex)
            {
                _logger?.LogWarning($"Gemini analysis did not succeed, falling back to clustering + translation analyzer: {ex.Message}");
            }

            // 2. Automatic Fallback: Cross-language clustering + synthesis + translation
            var fallbackOverview = await AnalyzeWithClusteringFallbackAsync(candidates, validFeeds.Count, totalArticles);
            fallbackOverview.Id = overviewId;
            PodcastScriptBuilder.EnsurePodcastPopulated(fallbackOverview);
            _logger?.LogInformation($"Generated overview (columnistsOnly={columnistsOnly}) via fallback analyzer with {fallbackOverview.Stories.Count} top stories.");
            return fallbackOverview;
        }

        private List<CandidateArticle> CollectCandidates(List<Feed> feeds, bool columnistsOnly = false)
        {
            var result = new List<CandidateArticle>();
            var cutoff = DateTime.UtcNow.AddHours(columnistsOnly ? -96 : -36);

            foreach (var feed in feeds)
            {
                var lang = string.IsNullOrWhiteSpace(feed.Language) ? "tr" : feed.Language.Trim().ToLowerInvariant();
                var filtered = feed.Items
                    .Where(item => item != null &&
                                   item.IsColumnist == columnistsOnly &&
                                   !string.IsNullOrWhiteSpace(item.Title) &&
                                   !(string.IsNullOrEmpty(item.Summary) && item.ImageUrl == null) &&
                                   !TextUtil.ContainsBannedWords(item.Title) &&
                                   !TextUtil.ContainsBannedWords(item.Summary) &&
                                   !TextUtil.ContainsBannedWords(item.Detail))
                    .OrderByDescending(item => item.PublishDate)
                    .ToList();

                var recentFiltered = filtered
                    .Where(i => EnsureUtc(i.PublishDate) >= cutoff)
                    .ToList();

                var recentCyprus = recentFiltered
                    .Where(i => TextUtil.GetGeoRelevanceTier(i.Title, i.Summary, i.Detail) >= 3 &&
                                TextUtil.ClassifyTopic(i.Title, i.Summary, i.Detail, i.Url?.AbsoluteUri) != "world")
                    .OrderByDescending(i => TextUtil.GetGeoRelevanceTier(i.Title, i.Summary, i.Detail))
                    .ThenByDescending(i => i.PublishDate)
                    .Take(9)
                    .ToList();

                var recentWorld = recentFiltered
                    .Except(recentCyprus)
                    .Where(i => TextUtil.GetGeoRelevanceTier(i.Title, i.Summary, i.Detail) < 3 ||
                                TextUtil.ClassifyTopic(i.Title, i.Summary, i.Detail, i.Url?.AbsoluteUri) == "world")
                    .OrderByDescending(i => i.ImageUrl != null)
                    .ThenByDescending(i => i.PublishDate)
                    .Take(3)
                    .ToList();

                var techCutoff = DateTime.UtcNow.AddDays(-7);
                var recentTech = filtered
                    .Except(recentCyprus)
                    .Except(recentWorld)
                    .Where(i => EnsureUtc(i.PublishDate) >= techCutoff &&
                                (string.Equals(i.Topic, "tech", StringComparison.OrdinalIgnoreCase) ||
                                 TextUtil.ClassifyTopic(i.Title, i.Summary, i.Detail, i.Url?.AbsoluteUri) == "tech"))
                    .OrderByDescending(i => TextUtil.GetGeoRelevanceTier(i.Title, i.Summary, i.Detail))
                    .ThenByDescending(i => i.PublishDate)
                    .Take(2)
                    .ToList();

                foreach (var item in recentCyprus.Concat(recentWorld).Concat(recentTech))
                {
                    result.Add(new CandidateArticle
                    {
                        Feed = feed,
                        Item = item,
                        Language = lang,
                        GeoTier = TextUtil.GetGeoRelevanceTier(item.Title, item.Summary, item.Detail)
                    });
                }
            }

            if (result.Count == 0)
            {
                foreach (var feed in feeds)
                {
                    var lang = string.IsNullOrWhiteSpace(feed.Language) ? "tr" : feed.Language.Trim().ToLowerInvariant();
                    var fallbackRecent = feed.Items
                        .Where(item => item != null &&
                                       item.IsColumnist == columnistsOnly &&
                                       !string.IsNullOrWhiteSpace(item.Title))
                        .OrderByDescending(i => i.PublishDate)
                        .Take(4)
                        .ToList();

                    foreach (var item in fallbackRecent)
                    {
                        result.Add(new CandidateArticle
                        {
                            Feed = feed,
                            Item = item,
                            Language = lang,
                            GeoTier = TextUtil.GetGeoRelevanceTier(item.Title, item.Summary, item.Detail)
                        });
                    }
                }
            }

            var cyprusPool = result
                .Where(c => c.GeoTier >= 3 &&
                            TextUtil.ClassifyTopic(c.Item.Title, c.Item.Summary, c.Item.Detail, c.Item.Url?.AbsoluteUri) != "world")
                .OrderByDescending(c => c.GeoTier)
                .ThenByDescending(c => c.Item.PublishDate)
                .Take(195)
                .ToList();

            var worldPool = result
                .Except(cyprusPool)
                .OrderByDescending(c => c.Item.ImageUrl != null)
                .ThenByDescending(c => c.Item.PublishDate)
                .Take(45)
                .ToList();

            result = cyprusPool.Concat(worldPool).Take(240).ToList();

            for (int i = 0; i < result.Count; i++)
            {
                result[i].Index = i;
            }

            return result;
        }

        private async Task<NewsOverview> TryAnalyzeWithGeminiAsync(
            List<CandidateArticle> candidates,
            int totalFeeds,
            int totalArticles,
            bool columnistsOnly = false)
        {
            var prompt = BuildGeminiPrompt(candidates, totalFeeds, columnistsOnly);
            GeminiOverviewResult parsed = null;

            var apiKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
            if (!string.IsNullOrWhiteSpace(apiKey))
            {
                var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={Uri.EscapeDataString(apiKey)}";
                var responseText = await CallGeminiEndpointAsync(url, null, prompt);
                if (!string.IsNullOrWhiteSpace(responseText))
                {
                    parsed = JsonConvert.DeserializeObject<GeminiOverviewResult>(CleanJsonFence(responseText));
                }
            }
            else
            {
                var credential = await GoogleCredential.GetApplicationDefaultAsync();
                if (credential.IsCreateScopedRequired)
                {
                    credential = credential.CreateScoped("https://www.googleapis.com/auth/cloud-platform");
                }
                var token = await ((ITokenAccess)credential).GetAccessTokenForRequestAsync();
                if (!string.IsNullOrWhiteSpace(token))
                {
                    var modelsToTry = new[]
                    {
                        (_location, "gemini-2.5-flash"),
                        ("us-central1", "gemini-2.5-flash"),
                        ("global", "gemini-3-flash-preview"),
                        ("global", "gemini-3.1-pro-preview")
                    };

                    foreach (var (loc, model) in modelsToTry)
                    {
                        try
                        {
                            var host = loc == "global"
                                ? "aiplatform.googleapis.com"
                                : $"{loc}-aiplatform.googleapis.com";
                            var url = $"https://{host}/v1/projects/{_projectId}/locations/{loc}/publishers/google/models/{model}:generateContent";
                            var responseText = await CallGeminiEndpointAsync(url, token, prompt);
                            if (!string.IsNullOrWhiteSpace(responseText))
                            {
                                var candidateParsed = JsonConvert.DeserializeObject<GeminiOverviewResult>(CleanJsonFence(responseText));
                                if (candidateParsed?.Stories != null && candidateParsed.Stories.Count > 0)
                                {
                                    parsed = candidateParsed;
                                    _logger?.LogInformation($"Gemini synthesis succeeded using model {model} in {loc} with {parsed.Stories.Count} stories.");
                                    break;
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger?.LogWarning($"Vertex AI {model} in {loc} failed: {ex.Message}");
                        }
                    }
                }
            }

            if (parsed?.Stories == null || parsed.Stories.Count == 0)
            {
                return null;
            }

            var stories = new List<OverviewStory>();
            var usedCandidateIndices = new HashSet<int>();
            int rank = 1;
            foreach (var gs in parsed.Stories)
            {
                var indices = (gs.ArticleIndices ?? new List<int>())
                    .Where(idx => idx >= 0 && idx < candidates.Count)
                    .Distinct()
                    .ToList();

                if (indices.Count == 0)
                {
                    continue;
                }

                foreach (var idx in indices)
                {
                    usedCandidateIndices.Add(idx);
                }

                var matchedCandidates = indices.Select(idx => candidates[idx]).ToList();
                var sources = BuildStorySources(matchedCandidates);
                if (sources.Count == 0)
                {
                    continue;
                }

                var imageUrl = matchedCandidates
                    .Select(c => c.Item.ImageUrl)
                    .FirstOrDefault(u => u != null);

                var publishDate = EnsureUtc(matchedCandidates.Max(c => c.Item.PublishDate));
                var titleEn = NullIfEmpty(gs.TitleEn) ?? sources[0].Article.Title;
                var narrativeEn = NullIfEmpty(gs.NarrativeEn) ?? string.Empty;
                var resolvedTopic = TextUtil.NormalizeTopic(gs.Topic)
                    ?? TextUtil.ClassifyTopic(
                        $"{titleEn} {gs.TitleTr} {gs.TitleEl}",
                        $"{narrativeEn} {gs.NarrativeTr} {gs.NarrativeEl}",
                        sources[0].Article.Summary,
                        sources[0].Article.Url?.AbsoluteUri);

                stories.Add(new OverviewStory
                {
                    Id = $"story-{rank}",
                    TitleEn = titleEn,
                    TitleTr = NullIfEmpty(gs.TitleTr) ?? NullIfEmpty(gs.TitleEn) ?? sources[0].Article.Title,
                    TitleEl = NullIfEmpty(gs.TitleEl) ?? NullIfEmpty(gs.TitleEn) ?? sources[0].Article.Title,
                    NarrativeEn = narrativeEn,
                    NarrativeTr = NullIfEmpty(gs.NarrativeTr) ?? NullIfEmpty(gs.NarrativeEn) ?? string.Empty,
                    NarrativeEl = NullIfEmpty(gs.NarrativeEl) ?? NullIfEmpty(gs.NarrativeEn) ?? string.Empty,
                    ImageUrl = imageUrl,
                    PublishDate = publishDate,
                    Topic = resolvedTopic,
                    Sources = sources
                });
                rank++;
            }

            if (stories.Count == 0)
            {
                return null;
            }

            // Ensure stories are strictly ordered by geographic priority: Cyprus (3) -> Greece (2) -> Turkey (1) -> World (0),
            // and prioritize fresh stories (last 18 hours) before older stories.
            var nowUtc = DateTime.UtcNow;
            stories = stories
                .Select((story, originalIndex) =>
                {
                    var tier = TextUtil.GetGeoRelevanceTier(
                        $"{story.TitleEn} {story.TitleTr} {story.TitleEl}",
                        $"{story.NarrativeEn} {story.NarrativeTr} {story.NarrativeEl}");
                    var bucket = tier >= 3 ? 3 : tier;
                    var ageHours = (nowUtc - EnsureUtc(story.PublishDate)).TotalHours;
                    var isRecent = ageHours <= 18.0 ? 1 : 0;
                    return (story, bucket, isRecent, originalIndex);
                })
                .OrderByDescending(x => x.bucket)
                .ThenByDescending(x => x.isRecent)
                .ThenBy(x => x.originalIndex)
                .Select((x, i) =>
                {
                    x.story.Id = $"story-{i + 1}";
                    return x.story;
                })
                .ToList();

            if (stories.Count < 40)
            {
                var remainingCandidates = candidates
                    .Where(c => !usedCandidateIndices.Contains(c.Index))
                    .ToList();
                if (remainingCandidates.Count > 0)
                {
                    try
                    {
                        var needed = 40 - stories.Count;
                        var extraOverview = await AnalyzeWithClusteringFallbackAsync(
                            remainingCandidates,
                            totalFeeds,
                            totalArticles,
                            minStories: Math.Min(needed, remainingCandidates.Count),
                            maxStories: needed);
                        if (extraOverview?.Stories != null)
                        {
                            foreach (var extra in extraOverview.Stories)
                            {
                                if (stories.Count >= 40) break;
                                extra.Id = $"story-{stories.Count + 1}";
                                stories.Add(extra);
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger?.LogWarning($"Failed to append extra clustered stories up to 40: {ex.Message}");
                    }
                }
            }

            if (!columnistsOnly)
            {
                stories = OrderCyprusFirstThenWorld(stories);
            }

            var currentEdition = PodcastScriptBuilder.ResolveEdition(DateTime.UtcNow);
            var podcastTurns = new List<PodcastDialogueTurn>();
            if (parsed.PodcastTurns != null && parsed.PodcastTurns.Count >= 6)
            {
                var topPodcastStories = PodcastScriptBuilder.SelectPodcastStories(stories, columnistsOnly);
                int idx = 0;
                foreach (var pt in parsed.PodcastTurns)
                {
                    if (string.IsNullOrWhiteSpace(pt?.TextEn) &&
                        string.IsNullOrWhiteSpace(pt?.TextTr) &&
                        string.IsNullOrWhiteSpace(pt?.TextEl))
                    {
                        continue;
                    }

                    var spk = string.Equals(pt.Speaker?.Trim(), "B", StringComparison.OrdinalIgnoreCase)
                        ? "B"
                        : (idx % 2 == 0 ? "A" : "B");

                    podcastTurns.Add(new PodcastDialogueTurn
                    {
                        Index = idx++,
                        Speaker = spk,
                        SpeakerNameEl = string.Empty,
                        SpeakerNameTr = string.Empty,
                        SpeakerNameEn = string.Empty,
                        TextEn = NullIfEmpty(pt.TextEn) ?? string.Empty,
                        TextTr = NullIfEmpty(pt.TextTr) ?? NullIfEmpty(pt.TextEn) ?? string.Empty,
                        TextEl = NullIfEmpty(pt.TextEl) ?? NullIfEmpty(pt.TextEn) ?? string.Empty
                    });
                }

                for (int i = 0; i < podcastTurns.Count; i++)
                {
                    if (i < 2 || i >= podcastTurns.Count - 2)
                    {
                        podcastTurns[i].StoryId = null;
                    }
                    else
                    {
                        int storyIdx = (i - 2) / 2;
                        if (storyIdx >= 0 && storyIdx < topPodcastStories.Count)
                        {
                            podcastTurns[i].StoryId = topPodcastStories[storyIdx].Id;
                        }
                    }
                }
            }

            var overview = new NewsOverview
            {
                Id = "latest",
                GeneratedAt = DateTime.UtcNow,
                TotalFeedsAnalyzed = totalFeeds,
                TotalArticlesAnalyzed = totalArticles,
                SummaryEn = NullIfEmpty(parsed.SummaryEn) ?? "Key stories synthesized across Turkish, Greek, and English newspapers in Cyprus.",
                SummaryTr = NullIfEmpty(parsed.SummaryTr) ?? "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden derlenen öne çıkan haberler.",
                SummaryEl = NullIfEmpty(parsed.SummaryEl) ?? "Οι σημαντικότερες ειδήσεις από τουρκοκυπριακές, ελληνοκυπριακές και αγγλόφωνες εφημερίδες της Κύπρου.",
                Edition = currentEdition,
                Stories = stories,
                PodcastTurns = podcastTurns
            };

            PodcastScriptBuilder.EnsurePodcastPopulated(overview, currentEdition);
            return overview;
        }

        private async Task<string> CallGeminiEndpointAsync(string url, string bearerToken, string prompt)
        {
            var payload = new
            {
                contents = new[]
                {
                    new
                    {
                        role = "user",
                        parts = new[] { new { text = prompt } }
                    }
                },
                generationConfig = new
                {
                    temperature = 0.2,
                    maxOutputTokens = 32768,
                    responseMimeType = "application/json"
                }
            };

            using var req = new HttpRequestMessage(HttpMethod.Post, url)
            {
                Content = new StringContent(JsonConvert.SerializeObject(payload), Encoding.UTF8, "application/json")
            };

            if (!string.IsNullOrWhiteSpace(bearerToken))
            {
                req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);
            }

            using var resp = await Http.SendAsync(req);
            if (!resp.IsSuccessStatusCode)
            {
                var err = await resp.Content.ReadAsStringAsync();
                throw new InvalidOperationException($"Gemini HTTP {(int)resp.StatusCode}: {err}");
            }

            var body = await resp.Content.ReadAsStringAsync();
            var root = JObject.Parse(body);
            return root["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]?.ToString();
        }

        private static string BuildGeminiPrompt(List<CandidateArticle> candidates, int totalFeeds, bool columnistsOnly = false)
        {
            var edition = PodcastScriptBuilder.ResolveEdition(DateTime.UtcNow);
            var (editionEn, editionTr, editionEl, nextEditionEn, nextEditionTr, nextEditionEl) = edition switch
            {
                "morning" => (
                    "Cyprus Bicommunal News - Morning",
                    "Kıbrıs İki Toplumlu Haberler - Sabah",
                    "Δικοινοτικές Ειδήσεις Κύπρου - Πρωί",
                    "Mid-Day",
                    "Öğle",
                    "Μεσημεριανή"
                ),
                "midday" => (
                    "Cyprus Bicommunal News - Mid-Day",
                    "Kıbrıs İki Toplumlu Haberler - Öğle",
                    "Δικοινοτικές Ειδήσεις Κύπρου - Μεσημέρι",
                    "Evening",
                    "Akşam",
                    "Βραδινή"
                ),
                _ => (
                    "Cyprus Bicommunal News - Evening",
                    "Kıbrıs İki Toplumlu Haberler - Akşam",
                    "Δικοινοτικές Ειδήσεις Κύπρου - Βράδυ",
                    "Morning",
                    "Sabah",
                    "Πρωινή"
                )
            };

            var sb = new StringBuilder();
            sb.AppendLine("You are an expert bicommunal Cyprus news editor and broadcast podcast producer fluent in English, Turkish, and Greek.");
            if (columnistsOnly)
            {
                sb.AppendLine($"Below are {candidates.Count} recent opinion columns and commentaries from Turkish, Greek, and English newspaper columnists across Cyprus.");
                sb.AppendLine("Analyze all columns and identify the major opinion themes and top columns of the day (aim for 12 to 16 top column topics/pieces).");
            }
            else
            {
                sb.AppendLine($"Below are {candidates.Count} recent news articles from Turkish, Greek, and English newspapers across Cyprus.");
                sb.AppendLine("Analyze all articles and identify all major top stories of the day covered across newspapers (aim for 18 to 22 top stories; include at least 18 distinct stories).");
            }
            sb.AppendLine("RECENCY PRIORITY: Prioritize breaking and recent stories published within the last 12–18 hours over older stories from yesterday.");
            sb.AppendLine("GEOGRAPHIC PRIORITY & WORLD NEWS INCLUSION (STRICT): You MUST prioritize and order stories/columns as follows:");
            sb.AppendLine("  1st Priority (First 14 to 16 stories): CYPRUS (island-wide, Greek Cypriot, Turkish Cypriot, and bicommunal political, economic, tech/startup, legal, social, and cultural developments — including 1 to 2 notable technology, AI, cybersecurity, digital transformation, or startup stories with topic: \"tech\" when present).");
            sb.AppendLine("  2nd Priority (Next 4 to 6 stories, right after Cyprus): WORLD & REGIONAL NEWS (topic: \"world\" — major international, Middle East, European, US, global, Greece, and Turkey developments covered in the newspapers).");
            sb.AppendLine("The selected Top Stories list MUST include 14 to 16 major Cyprus stories first, followed immediately by 4 to 6 major World/international stories (labeled with topic: \"world\"). Similarly, the 5-minute podcast (8 stories total) MUST cover the top 6 Cyprus stories first (Turns 2–13), followed by the top 2 World/international stories (Turns 14–17) before the closing wrap-up.");
            sb.AppendLine("Within Cyprus topics, prioritize themes covered across different language communities in Cyprus and major island-wide developments, ensuring a balanced selection across Turkish, Greek, and English sources.");
            sb.AppendLine("COMMUNITY & GEOGRAPHIC QUALIFICATION (CRITICAL FOR BOTH STORIES AND PODCAST):");
            sb.AppendLine("- Because listeners and readers come from both Greek Cypriot and Turkish Cypriot communities, ALWAYS explicitly qualify events, municipalities, institutions, political parties, ministries, and officials in the north so there is never any ambiguity (for example, never refer to an event in the northern part of Nicosia simply as 'in Nicosia' or 'Municipality of Nicosia', and never drop an acronym like 'LTB' without explaining that it is the Nicosia Turkish Municipality).");
            sb.AppendLine("- Adapt the terminology naturally to the community listening/reading in each language:");
            sb.AppendLine("  * In ENGLISH (titleEn, narrativeEn, summaryEn, textEn): Use clear qualifiers such as \"northern Nicosia\", \"north Cyprus\", \"Turkish Cypriot\", and \"the Nicosia Turkish Municipality (LTB)\".");
            sb.AppendLine("  * In TURKISH (titleTr, narrativeTr, summaryTr, textTr): Use clear qualifiers such as \"Kuzey Lefkoşa\", \"Kuzey Kıbrıs\", and \"Lefkoşa Türk Belediyesi (LTB)\".");
            sb.AppendLine("  * In GREEK (titleEl, narrativeEl, summaryEl, textEl): Use standard Greek Cypriot terminology familiar to the Greek Cypriot audience when referring to places, events, or institutions in the north — such as \"κατεχόμενη Λευκωσία\" (occupied Nicosia), \"στα κατεχόμενα\", \"ο Τουρκοκυπριακός Δήμος Λευκωσίας (LTB)\", and \"στην τουρκοκυπριακή κοινότητα\". Never translate a northern Nicosia event into Greek simply as \"στη Λευκωσία\" — always specify \"στην κατεχόμενη Λευκωσία\".");
            sb.AppendLine("1. For each top story/column:");
            sb.AppendLine("- Write a clear, journalistic headline in English (titleEn), Turkish (titleTr), and Greek (titleEl).");
            sb.AppendLine("- Write a rich 2-4 sentence narrative synthesis in English (narrativeEn), Turkish (narrativeTr), and Greek (narrativeEl) explaining the key arguments/developments and how the newspapers/columnists cover it.");
            sb.AppendLine("- Provide topic: one of \"politics\", \"society\", \"economy\", \"tech\", \"sports\", \"culture\", or \"world\".");
            sb.AppendLine("- Provide articleIndices: the array of integer indices of all articles/columns from the list below that cover or relate to this topic (include at least 1 and up to 6 matching items from different newspapers).");
            sb.AppendLine("2. Also provide a 1-2 sentence daily overview summary in English (summaryEn), Turkish (summaryTr), and Greek (summaryEl) focusing on the top Cyprus developments.");
            var editionToneHint = edition switch
            {
                "morning" => "This is the Morning edition — use a fresh start-of-the-day tone (you may occasionally mention morning coffee, but vary your morning greetings).",
                "midday" => "This is the Mid-Day edition — use a midday catch-up / afternoon break tone. NEVER say 'grab a coffee' or use morning clichés.",
                _ => "This is the Evening edition — use a warm evening wind-down / end-of-day reflection tone. NEVER say 'grab a coffee' or use morning clichés."
            };

            sb.AppendLine("3. Also generate a ~5-minute two-host casual, conversational daily podcast script (podcastTurns, 20 alternating turns between Speaker \"A\" and Speaker \"B\") in English (textEn), Turkish (textTr), and Greek (textEl):");
            sb.AppendLine($"- EDITION & OPENING TONE: {editionToneHint}");
            sb.AppendLine("- NATURAL CONVERSATION (DO NOT READ HEADLINES): Never simply read or list news titles/headlines out loud — neither in the opening intro (Turns 0 and 1) nor when introducing each story (Turns 2–17). Instead, talk through the themes and stories naturally in complete, flowing spoken sentences, as two smart, approachable co-hosts having an authentic conversation.");
            sb.AppendLine("- Turn 0 (speaker \"A\") MUST warmly welcome listeners to \"" + editionEn + "\" (in Turkish: \"" + editionTr + "\", in Greek: \"" + editionEl + "\") with a time-appropriate greeting and naturally talk through a couple of the biggest themes shaping today's news without reciting headline titles.");
            sb.AppendLine("- Turn 1 (speaker \"B\") MUST build on that naturally, mention one or two other interesting angles coming up in conversational phrasing (not headline lists), and transition smoothly into the first story.");
            sb.AppendLine("- Subsequent turns MUST alternate between speaker \"A\" and speaker \"B\" (2 turns per topic across 8 stories: first the top 6 Cyprus stories in Turns 2–13, and then the top 2 World/international stories in Turns 14–17): the first speaker introduces what is happening in the story in a natural, conversational way (never reading a headline title), and the second speaker reacts naturally and adds context, why it matters, and cross-community or international perspective without repeating the first speaker.");
            sb.AppendLine("- AVOID REPETITIVE FILLERS: Do NOT overuse phrases like \"Yeah, totally\", \"Totally\", \"across the island\", \"island-wide\", or \"Definitely a story we'll be watching closely\". Vary reactions, openings, and transitions on every turn so no two turns sound templated or start the same way.");
            sb.AppendLine($"- The final 2 turns (\"A\" then \"B\") MUST warmly wrap up this edition (\"{editionEn}\") and invite listeners to join again for the next edition (the \"{nextEditionEn}\" edition in English, \"{nextEditionTr}\" bülteni in Turkish, and \"{nextEditionEl}\" έκδοση in Greek).");
            sb.AppendLine("- STRICT PODCAST RULES: Do NOT use any personal names for the two podcast hosts. Do NOT mention the number of stories/columns, the number of newspapers/news sources, or the number of articles analyzed.");
            sb.AppendLine("Return strictly valid JSON with schema:");
            sb.AppendLine(@"{
  ""summaryEn"": ""..."",
  ""summaryTr"": ""..."",
  ""summaryEl"": ""..."",
  ""stories"": [
    {
      ""titleEn"": ""..."",
      ""titleTr"": ""..."",
      ""titleEl"": ""..."",
      ""narrativeEn"": ""..."",
      ""narrativeTr"": ""..."",
      ""narrativeEl"": ""..."",
      ""topic"": ""politics"",
      ""articleIndices"": [0, 5, 12]
    }
  ],
  ""podcastTurns"": [
    {
      ""speaker"": ""A"",
      ""textEn"": ""..."",
      ""textTr"": ""..."",
      ""textEl"": ""...""
    }
  ]
}");
            sb.AppendLine();
            sb.AppendLine("ARTICLES:");

            var nowForPrompt = DateTime.UtcNow;
            foreach (var c in candidates)
            {
                var cleanSummary = CleanSnippet(c.Item.Summary ?? c.Item.Detail, 180);
                var geoLabel = TextUtil.GetGeoRelevanceLabel(c.GeoTier);
                var authorPart = !string.IsNullOrWhiteSpace(c.Item.Author) ? $" | Author: {c.Item.Author}" : string.Empty;
                var hoursAgo = Math.Max(0, (int)Math.Round((nowForPrompt - EnsureUtc(c.Item.PublishDate)).TotalHours));
                sb.AppendLine($"[{c.Index}] ({c.Feed.Id} | {c.Feed.Title} | {c.Language} | {hoursAgo}h ago | Geo: {geoLabel}{authorPart}) {c.Item.Title} — {cleanSummary}");
            }

            return sb.ToString();
        }

        private async Task<NewsOverview> AnalyzeWithClusteringFallbackAsync(
            List<CandidateArticle> candidates,
            int totalFeeds,
            int totalArticles,
            int minStories = 36,
            int maxStories = 40)
        {
            // Step 1: Translate candidate titles to English in parallel (using bounded concurrency) so we can cluster across TR/EL/EN
            using var semaphore = new SemaphoreSlim(10);
            var titleTasks = candidates.Select(async c =>
            {
                await semaphore.WaitAsync();
                try
                {
                    if (c.Language == "en")
                    {
                        c.EnglishTitle = c.Item.Title;
                    }
                    else
                    {
                        c.EnglishTitle = await TranslateViaGtxAsync(c.Item.Title, c.Language, "en");
                    }
                    c.Tokens = ExtractTokens(c.EnglishTitle);
                }
                finally
                {
                    semaphore.Release();
                }
            });
            await Task.WhenAll(titleTasks);

            // Step 2: Group articles into story clusters based on token similarity across different newspapers
            var clusters = BuildStoryClusters(candidates, minStories: minStories, maxStories: maxStories);

            // Step 3: For each cluster, synthesize English, Turkish, and Greek titles and narratives
            var stories = new List<OverviewStory>();
            int rank = 1;

            foreach (var cluster in clusters)
            {
                var sources = BuildStorySources(cluster);
                if (sources.Count == 0)
                {
                    continue;
                }

                var primary = cluster
                    .OrderByDescending(c => c.Item.ImageUrl != null)
                    .ThenByDescending(c => (c.Item.Summary ?? string.Empty).Length)
                    .First();

                var enLeadTitle = !string.IsNullOrWhiteSpace(primary.EnglishTitle)
                    ? primary.EnglishTitle
                    : primary.Item.Title;

                if (primary.Language != "en" &&
                    (string.Equals(enLeadTitle, primary.Item.Title, StringComparison.Ordinal) ||
                     NeedsTranslationForLanguage(enLeadTitle, "en", primary.Language)))
                {
                    enLeadTitle = await TranslateViaGtxAsync(primary.Item.Title, null, "en");
                }

                // Translate summaries of the top 2 sources in this cluster to English to build a rich narrative
                var snippetParts = new List<string>();
                foreach (var member in cluster.Take(2))
                {
                    var rawSnippet = CleanSnippet(member.Item.Summary ?? member.Item.Detail, 220);
                    if (!string.IsNullOrWhiteSpace(rawSnippet))
                    {
                        var enSnippet = member.Language == "en"
                            ? rawSnippet
                            : await TranslateViaGtxAsync(rawSnippet, null, "en");
                        if (!string.IsNullOrWhiteSpace(enSnippet))
                        {
                            snippetParts.Add(EnsurePeriod(enSnippet));
                        }
                    }
                }

                string narrativeEn;
                if (snippetParts.Count > 1)
                {
                    narrativeEn = string.Join(" ", snippetParts.Take(2));
                }
                else if (snippetParts.Count == 1)
                {
                    narrativeEn = snippetParts[0];
                }
                else
                {
                    narrativeEn = EnsurePeriod(enLeadTitle);
                }

                var titleTrTask = primary.Language == "tr"
                    ? Task.FromResult(primary.Item.Title)
                    : TranslateViaGtxAsync(primary.Item.Title, null, "tr");

                var titleElTask = primary.Language == "el"
                    ? Task.FromResult(primary.Item.Title)
                    : TranslateViaGtxAsync(primary.Item.Title, null, "el");

                var primaryRawSnippet = CleanSnippet(primary.Item.Summary ?? primary.Item.Detail, 260);
                var narrativeSourceForSingle = cluster.Count == 1 && !string.IsNullOrWhiteSpace(primaryRawSnippet)
                    ? EnsurePeriod(primaryRawSnippet)
                    : narrativeEn;

                var narrativeTrTask = (cluster.Count == 1 && primary.Language == "tr" && !string.IsNullOrWhiteSpace(primaryRawSnippet))
                    ? Task.FromResult(EnsurePeriod(primaryRawSnippet))
                    : TranslateViaGtxAsync(narrativeSourceForSingle, null, "tr");

                var narrativeElTask = (cluster.Count == 1 && primary.Language == "el" && !string.IsNullOrWhiteSpace(primaryRawSnippet))
                    ? Task.FromResult(EnsurePeriod(primaryRawSnippet))
                    : TranslateViaGtxAsync(narrativeSourceForSingle, null, "el");

                await Task.WhenAll(titleTrTask, titleElTask, narrativeTrTask, narrativeElTask);

                var imageUrl = cluster
                    .Select(c => c.Item.ImageUrl)
                    .FirstOrDefault(u => u != null);

                var publishDate = EnsureUtc(cluster.Max(c => c.Item.PublishDate));
                var resolvedTopic = TextUtil.ClassifyTopic(
                    $"{enLeadTitle} {titleTrTask.Result} {titleElTask.Result}",
                    $"{narrativeEn} {narrativeTrTask.Result} {narrativeElTask.Result}",
                    primary.Item.Summary,
                    primary.Item.Url?.AbsoluteUri);

                stories.Add(new OverviewStory
                {
                    Id = $"story-{rank}",
                    TitleEn = enLeadTitle,
                    TitleTr = titleTrTask.Result,
                    TitleEl = titleElTask.Result,
                    NarrativeEn = narrativeEn,
                    NarrativeTr = narrativeTrTask.Result,
                    NarrativeEl = narrativeElTask.Result,
                    ImageUrl = imageUrl,
                    PublishDate = publishDate,
                    Topic = resolvedTopic,
                    Sources = sources
                });

                rank++;
            }

            stories = OrderCyprusFirstThenWorld(stories);

            return new NewsOverview
            {
                Id = "latest",
                GeneratedAt = DateTime.UtcNow,
                TotalFeedsAnalyzed = totalFeeds,
                TotalArticlesAnalyzed = totalArticles,
                SummaryEn = "Key stories synthesized across Turkish, Greek, and English newspapers in Cyprus.",
                SummaryTr = "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden derlenen öne çıkan haberler.",
                SummaryEl = "Οι σημαντικότερες ειδήσεις από τουρκοκυπριακές, ελληνοκυπριακές και αγγλόφωνες εφημερίδες της Κύπρου.",
                Stories = stories
            };
        }

        public static List<OverviewStory> OrderCyprusFirstThenWorld(
            List<OverviewStory> stories,
            int topCyprusCount = 15,
            int topWorldCount = 5)
        {
            if (stories == null || stories.Count <= 4)
            {
                return stories ?? new List<OverviewStory>();
            }

            bool IsWorldStory(OverviewStory s)
            {
                var normTopic = TextUtil.NormalizeTopic(s?.Topic);
                if (normTopic == "world") return true;
                var tier = TextUtil.GetGeoRelevanceTier(
                    $"{s?.TitleEn} {s?.TitleTr} {s?.TitleEl}",
                    $"{s?.NarrativeEn} {s?.NarrativeTr} {s?.NarrativeEl}");
                return tier < 3;
            }

            var cyprusStories = stories.Where(s => !IsWorldStory(s)).ToList();
            var worldStories = stories.Where(IsWorldStory).ToList();
            if (cyprusStories.Count == 0 || worldStories.Count == 0)
            {
                return stories;
            }

            foreach (var ws in worldStories)
            {
                if (string.IsNullOrWhiteSpace(ws.Topic) || ws.Topic == "politics" || ws.Topic == "society")
                {
                    ws.Topic = "world";
                }
            }

            var reordered = new List<OverviewStory>();
            var firstCyprus = cyprusStories.Take(topCyprusCount).ToList();
            var firstWorld = worldStories.Take(topWorldCount).ToList();
            reordered.AddRange(firstCyprus);
            reordered.AddRange(firstWorld);
            reordered.AddRange(cyprusStories.Skip(firstCyprus.Count));
            reordered.AddRange(worldStories.Skip(firstWorld.Count));

            for (int i = 0; i < reordered.Count; i++)
            {
                reordered[i].Id = $"story-{i + 1}";
            }

            return reordered;
        }

        private static List<List<CandidateArticle>> BuildStoryClusters(List<CandidateArticle> candidates, int minStories, int maxStories)
        {
            var rawClusters = new List<List<CandidateArticle>>();
            var assigned = new HashSet<int>();

            for (int i = 0; i < candidates.Count; i++)
            {
                if (assigned.Contains(i))
                {
                    continue;
                }

                var seed = candidates[i];
                var cluster = new List<CandidateArticle> { seed };
                var clusterFeeds = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { seed.Feed.Id };
                var unionTokens = new HashSet<string>(seed.Tokens, StringComparer.OrdinalIgnoreCase);

                for (int j = i + 1; j < candidates.Count; j++)
                {
                    if (assigned.Contains(j))
                    {
                        continue;
                    }

                    var other = candidates[j];
                    if (clusterFeeds.Contains(other.Feed.Id))
                    {
                        continue;
                    }

                    int shared = other.Tokens.Count(t => unionTokens.Contains(t));
                    double jaccard = (unionTokens.Count + other.Tokens.Count - shared) > 0
                        ? (double)shared / (unionTokens.Count + other.Tokens.Count - shared)
                        : 0;

                    if (shared >= 2 || (shared >= 1 && jaccard >= 0.22))
                    {
                        cluster.Add(other);
                        clusterFeeds.Add(other.Feed.Id);
                        assigned.Add(j);
                        foreach (var t in other.Tokens)
                        {
                            unionTokens.Add(t);
                        }
                        if (cluster.Count >= 6)
                        {
                            break;
                        }
                    }
                }

                assigned.Add(i);
                rawClusters.Add(cluster);
            }

            // Rank clusters by: geographic priority (Cyprus -> Greece -> Turkey -> World), distinct languages covered, distinct newspapers, image availability, and recency
            int ClusterGeoBucket(List<CandidateArticle> cluster)
            {
                int maxTier = cluster.Max(a => a.GeoTier);
                return maxTier >= 3 ? 3 : maxTier;
            }

            var multiSource = rawClusters
                .Where(c => c.Count >= 2)
                .OrderByDescending(ClusterGeoBucket)
                .ThenByDescending(c => c.Select(a => a.Language).Distinct().Count())
                .ThenByDescending(c => c.Count)
                .ThenByDescending(c => c.Any(a => a.Item.ImageUrl != null))
                .ThenByDescending(c => c.Max(a => a.Item.PublishDate))
                .ToList();

            var selected = new List<List<CandidateArticle>>();
            var worldClusters = rawClusters
                .Where(c => ClusterGeoBucket(c) < 3)
                .OrderByDescending(c => c.Count)
                .ThenByDescending(c => c.Any(a => a.Item.ImageUrl != null))
                .ThenByDescending(c => c.Max(a => a.Item.PublishDate))
                .Take(Math.Min(6, Math.Max(2, maxStories / 4)))
                .ToList();

            int cyprusCap = Math.Max(1, maxStories - worldClusters.Count);
            selected.AddRange(multiSource.Where(c => !worldClusters.Contains(c)).Take(cyprusCap));
            foreach (var wc in worldClusters)
            {
                if (selected.Count < maxStories && !selected.Contains(wc))
                {
                    selected.Add(wc);
                }
            }

            if (selected.Count < minStories)
            {
                // Ensure balanced representation across TR, EL, and EN single-source top headlines, prioritizing Cyprus -> Greece -> Turkey -> World
                var remainingSingle = rawClusters
                    .Where(c => c.Count == 1)
                    .OrderByDescending(ClusterGeoBucket)
                    .ThenByDescending(c => c[0].Item.ImageUrl != null)
                    .ThenByDescending(c => (c[0].Item.Summary ?? string.Empty).Length)
                    .ThenByDescending(c => c[0].Item.PublishDate)
                    .ToList();

                var langOrder = new[] { "tr", "el", "en" };
                int pass = 0;
                while (selected.Count < minStories && remainingSingle.Count > 0 && pass < 20)
                {
                    foreach (var lang in langOrder)
                    {
                        if (selected.Count >= minStories) break;
                        var match = remainingSingle.FirstOrDefault(c => c[0].Language == lang);
                        if (match != null)
                        {
                            selected.Add(match);
                            remainingSingle.Remove(match);
                        }
                    }
                    pass++;
                }

                foreach (var rem in remainingSingle)
                {
                    if (selected.Count >= minStories) break;
                    selected.Add(rem);
                }
            }

            return selected;
        }

        private static List<OverviewStorySource> BuildStorySources(List<CandidateArticle> cluster)
        {
            var sources = new List<OverviewStorySource>();
            var seenFeeds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var c in cluster.OrderByDescending(x => EnsureUtc(x.Item.PublishDate)))
            {
                if (c?.Feed == null || c.Item == null || string.IsNullOrWhiteSpace(c.Feed.Id))
                {
                    continue;
                }

                if (!seenFeeds.Add(c.Feed.Id))
                {
                    continue;
                }

                sources.Add(new OverviewStorySource
                {
                    FeedId = c.Feed.Id,
                    FeedTitle = c.Feed.Title,
                    FeedLanguage = string.IsNullOrWhiteSpace(c.Feed.Language) ? c.Language : c.Feed.Language,
                    FeedImageUrl = c.Feed.ImageUrl,
                    FeedUrl = c.Feed.Url,
                    Article = new FeedItem
                    {
                        Title = c.Item.Title,
                        PublishDate = EnsureUtc(c.Item.PublishDate),
                        Summary = c.Item.Summary,
                        Detail = c.Item.Detail,
                        ImageUrl = c.Item.ImageUrl,
                        Url = c.Item.Url,
                        Author = c.Item.Author,
                        IsColumnist = c.Item.IsColumnist
                    }
                });
            }

            return sources;
        }

        private static HashSet<string> ExtractTokens(string text)
        {
            var tokens = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (string.IsNullOrWhiteSpace(text))
            {
                return tokens;
            }

            var matches = Regex.Matches(text.ToLowerInvariant(), @"[\p{L}\p{N}]{4,}");
            foreach (Match m in matches)
            {
                var word = m.Value;
                if (!StopWords.Contains(word))
                {
                    tokens.Add(word);
                }
            }
            return tokens;
        }

        public static bool NeedsTranslationForLanguage(string text, string targetLang, string majoritySourceLang = null)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return false;
            }

            var tl = (targetLang ?? "en").Trim().ToLowerInvariant();
            if (tl == "el")
            {
                return !GreekScriptRegex.IsMatch(text);
            }

            if (GreekScriptRegex.IsMatch(text))
            {
                return true;
            }

            if (tl == "en" && TurkishSpecificRegex.IsMatch(text))
            {
                // Proper nouns like "Erhan Arıklı" or "Lefkoşa" in an English sentence should not trigger re-translation
                bool hasEnglishWords = Regex.IsMatch(
                    text,
                    @"\b(the|and|to|of|in|is|are|was|were|for|with|on|that|this|from|as|at|by|after|over)\b",
                    RegexOptions.IgnoreCase);
                if (!hasEnglishWords)
                {
                    return true;
                }
            }

            if (!string.IsNullOrWhiteSpace(majoritySourceLang) &&
                !string.Equals(majoritySourceLang.Trim(), tl, StringComparison.OrdinalIgnoreCase) &&
                LegacyReportsPrefixRegex.IsMatch(text))
            {
                return true;
            }

            return false;
        }

        private static string StripLegacyReportWrappers(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }

            var cleaned = LegacyReportsPrefixRegex.Replace(text, " ");
            cleaned = LegacyCoveredBySuffixRegex.Replace(cleaned, string.Empty);
            cleaned = Regex.Replace(cleaned, @"\s+", " ").Trim();
            return cleaned;
        }

        public static async Task<bool> EnsureStoriesTranslatedAsync(NewsOverview overview)
        {
            if (overview?.Stories == null || overview.Stories.Count == 0)
            {
                return false;
            }

            bool modified = false;
            using var semaphore = new SemaphoreSlim(8);
            var tasks = overview.Stories.Select(async story =>
            {
                if (story == null) return;

                var firstSource = story.Sources?.FirstOrDefault();
                var sourceLang = firstSource?.FeedLanguage?.Trim().ToLowerInvariant();
                var rawSourceTitle = firstSource?.Article?.Title?.Trim() ?? string.Empty;

                var tEn = story.TitleEn?.Trim() ?? string.Empty;
                var tTr = story.TitleTr?.Trim() ?? string.Empty;
                var tEl = story.TitleEl?.Trim() ?? string.Empty;

                bool allTitlesSame = !string.IsNullOrEmpty(tEn) &&
                                     string.Equals(tEn, tTr, StringComparison.Ordinal) &&
                                     string.Equals(tEn, tEl, StringComparison.Ordinal);

                bool needTitleEn = NeedsTranslationForLanguage(tEn, "en", sourceLang) ||
                                   (allTitlesSame && sourceLang != null && sourceLang != "en");
                bool needTitleTr = NeedsTranslationForLanguage(tTr, "tr", sourceLang) ||
                                   (allTitlesSame && sourceLang != null && sourceLang != "tr");
                bool needTitleEl = NeedsTranslationForLanguage(tEl, "el", sourceLang) ||
                                   (allTitlesSame && sourceLang != null && sourceLang != "el");

                var nEn = story.NarrativeEn?.Trim() ?? string.Empty;
                var nTr = story.NarrativeTr?.Trim() ?? string.Empty;
                var nEl = story.NarrativeEl?.Trim() ?? string.Empty;

                bool allNarrativesSame = !string.IsNullOrEmpty(nEn) &&
                                         string.Equals(nEn, nTr, StringComparison.Ordinal) &&
                                         string.Equals(nEn, nEl, StringComparison.Ordinal);

                bool needNarrativeEn = NeedsTranslationForLanguage(nEn, "en", sourceLang) ||
                                       (allNarrativesSame && sourceLang != null && sourceLang != "en");
                bool needNarrativeTr = NeedsTranslationForLanguage(nTr, "tr", sourceLang) ||
                                       (allNarrativesSame && sourceLang != null && sourceLang != "tr");
                bool needNarrativeEl = NeedsTranslationForLanguage(nEl, "el", sourceLang) ||
                                       (allNarrativesSame && sourceLang != null && sourceLang != "el");

                if (!needTitleEn && !needTitleTr && !needTitleEl &&
                    !needNarrativeEn && !needNarrativeTr && !needNarrativeEl)
                {
                    return;
                }

                await semaphore.WaitAsync();
                try
                {
                    var baseTitle = !string.IsNullOrWhiteSpace(rawSourceTitle)
                        ? rawSourceTitle
                        : (!string.IsNullOrWhiteSpace(tEn) ? tEn : (!string.IsNullOrWhiteSpace(tTr) ? tTr : tEl));

                    var baseNarrative = StripLegacyReportWrappers(
                        !string.IsNullOrWhiteSpace(nEn) ? nEn : (!string.IsNullOrWhiteSpace(nTr) ? nTr : nEl));

                    if (needTitleEn && !string.IsNullOrWhiteSpace(baseTitle))
                    {
                        story.TitleEn = await TranslateViaGtxAsync(baseTitle, null, "en");
                        modified = true;
                    }
                    if (needTitleTr && !string.IsNullOrWhiteSpace(baseTitle))
                    {
                        story.TitleTr = await TranslateViaGtxAsync(baseTitle, null, "tr");
                        modified = true;
                    }
                    if (needTitleEl && !string.IsNullOrWhiteSpace(baseTitle))
                    {
                        story.TitleEl = await TranslateViaGtxAsync(baseTitle, null, "el");
                        modified = true;
                    }

                    if (needNarrativeEn && !string.IsNullOrWhiteSpace(baseNarrative))
                    {
                        story.NarrativeEn = await TranslateViaGtxAsync(baseNarrative, null, "en");
                        modified = true;
                    }
                    if (needNarrativeTr && !string.IsNullOrWhiteSpace(baseNarrative))
                    {
                        story.NarrativeTr = await TranslateViaGtxAsync(baseNarrative, null, "tr");
                        modified = true;
                    }
                    if (needNarrativeEl && !string.IsNullOrWhiteSpace(baseNarrative))
                    {
                        story.NarrativeEl = await TranslateViaGtxAsync(baseNarrative, null, "el");
                        modified = true;
                    }
                }
                finally
                {
                    semaphore.Release();
                }
            });

            await Task.WhenAll(tasks);
            return modified;
        }

        private static async Task<string> TranslateViaGtxAsync(string text, string sourceLang, string targetLang)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }

            var sl = string.IsNullOrWhiteSpace(sourceLang) ? "auto" : sourceLang.ToLowerInvariant();
            var tl = targetLang.ToLowerInvariant();
            if (sl == tl)
            {
                return text;
            }

            var cacheKey = $"{sl}->{tl}:{text}";
            if (TranslationCache.TryGetValue(cacheKey, out var cached))
            {
                return cached;
            }

            var client = GetTranslationClient();
            if (client != null)
            {
                try
                {
                    var cloudSourceLang = sl == "auto" ? null : sl;
                    var res = await client.TranslateTextAsync(text, tl, cloudSourceLang);
                    var cloudTranslated = WebUtility.HtmlDecode(res?.TranslatedText ?? string.Empty).Trim();
                    if (!string.IsNullOrEmpty(cloudTranslated))
                    {
                        if (TranslationCache.Count > 3000)
                        {
                            TranslationCache.Clear();
                        }
                        TranslationCache[cacheKey] = cloudTranslated;
                        return cloudTranslated;
                    }
                }
                catch
                {
                    // Fall back to Google Translate GTX endpoint if Cloud Translation V2 fails
                }
            }

            try
            {
                var url = $"https://translate.googleapis.com/translate_a/single?client=gtx&sl={Uri.EscapeDataString(sl)}&tl={Uri.EscapeDataString(tl)}&dt=t&q={Uri.EscapeDataString(text)}";
                using var resp = await TranslateHttp.GetAsync(url);
                resp.EnsureSuccessStatusCode();
                var json = await resp.Content.ReadAsStringAsync();
                var arr = JArray.Parse(json);
                var sentences = arr[0] as JArray;
                if (sentences == null)
                {
                    return text;
                }

                var sb = new StringBuilder();
                foreach (var item in sentences)
                {
                    var seg = item?[0]?.ToString();
                    if (!string.IsNullOrEmpty(seg))
                    {
                        sb.Append(seg);
                    }
                }

                var translated = sb.ToString().Trim();
                if (!string.IsNullOrEmpty(translated))
                {
                    if (TranslationCache.Count > 3000)
                    {
                        TranslationCache.Clear();
                    }
                    TranslationCache[cacheKey] = translated;
                    return translated;
                }
            }
            catch
            {
                // Fall back to original text if translation fails
            }

            return text;
        }

        private static string CleanSnippet(string raw, int maxLen)
        {
            if (string.IsNullOrWhiteSpace(raw))
            {
                return string.Empty;
            }

            var noHtml = Regex.Replace(raw, "<.*?>", " ");
            noHtml = System.Net.WebUtility.HtmlDecode(noHtml);
            noHtml = Regex.Replace(noHtml, @"\s+", " ").Trim();
            if (noHtml.Length > maxLen)
            {
                noHtml = noHtml.Substring(0, maxLen).TrimEnd() + "...";
            }
            return noHtml;
        }

        private static string EnsurePeriod(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }
            var trimmed = text.Trim();
            if (trimmed.EndsWith(".") || trimmed.EndsWith("!") || trimmed.EndsWith("?"))
            {
                return trimmed;
            }
            return trimmed + ".";
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

        private static string NullIfEmpty(string s)
        {
            return string.IsNullOrWhiteSpace(s) ? null : s.Trim();
        }

        private static DateTime EnsureUtc(DateTime dt)
        {
            return dt.Kind switch
            {
                DateTimeKind.Utc => dt,
                DateTimeKind.Local => dt.ToUniversalTime(),
                _ => DateTime.SpecifyKind(dt, DateTimeKind.Utc)
            };
        }
    }
}
