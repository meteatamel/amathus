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
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Amathus.Common.Feeds;
using Amathus.Common.Util;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Amathus.Common.Overview
{
    public class OverviewAnalyzer : IOverviewAnalyzer
    {
        private static readonly HttpClient Http = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(45)
        };

        private static readonly HttpClient TranslateHttp = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(12)
        };

        private static readonly ConcurrentDictionary<string, string> TranslationCache = new();

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

            [JsonProperty("articleIndices")]
            public List<int> ArticleIndices { get; set; }
        }

        public async Task<NewsOverview> AnalyzeAsync(List<Feed> feeds)
        {
            var validFeeds = (feeds ?? new List<Feed>())
                .Where(f => f?.Items != null && f.Items.Count > 0)
                .ToList();

            var candidates = CollectCandidates(validFeeds);
            var totalArticles = validFeeds.Sum(f => f.Items?.Count ?? 0);

            _logger?.LogInformation($"Analyzing overview across {validFeeds.Count} feeds ({candidates.Count} candidate articles out of {totalArticles} total).");

            if (candidates.Count == 0)
            {
                return new NewsOverview
                {
                    Id = "latest",
                    GeneratedAt = DateTime.UtcNow,
                    TotalFeedsAnalyzed = validFeeds.Count,
                    TotalArticlesAnalyzed = 0,
                    SummaryEn = "No news stories are available for analysis yet.",
                    SummaryTr = "Henüz analiz edilecek haber bulunamadı.",
                    SummaryEl = "Δεν υπάρχουν ακόμη διαθέσιμες ειδήσεις για ανάλυση.",
                    Stories = new List<OverviewStory>()
                };
            }

            // 1. Try Gemini via Vertex AI (or GEMINI_API_KEY)
            try
            {
                var geminiOverview = await TryAnalyzeWithGeminiAsync(candidates, validFeeds.Count, totalArticles);
                if (geminiOverview != null && geminiOverview.Stories != null && geminiOverview.Stories.Count > 0)
                {
                    PodcastScriptBuilder.EnsurePodcastPopulated(geminiOverview);
                    _logger?.LogInformation($"Successfully generated news overview via Gemini with {geminiOverview.Stories.Count} top stories.");
                    return geminiOverview;
                }
            }
            catch (Exception ex)
            {
                _logger?.LogWarning($"Gemini analysis did not succeed, falling back to clustering + translation analyzer: {ex.Message}");
            }

            // 2. Automatic Fallback: Cross-language clustering + synthesis + translation
            var fallbackOverview = await AnalyzeWithClusteringFallbackAsync(candidates, validFeeds.Count, totalArticles);
            PodcastScriptBuilder.EnsurePodcastPopulated(fallbackOverview);
            _logger?.LogInformation($"Generated news overview via fallback analyzer with {fallbackOverview.Stories.Count} top stories.");
            return fallbackOverview;
        }

        private List<CandidateArticle> CollectCandidates(List<Feed> feeds)
        {
            var result = new List<CandidateArticle>();
            var cutoff = DateTime.UtcNow.AddDays(-3);

            foreach (var feed in feeds)
            {
                var lang = string.IsNullOrWhiteSpace(feed.Language) ? "tr" : feed.Language.Trim().ToLowerInvariant();
                var filtered = feed.Items
                    .Where(item => item != null &&
                                   !item.IsColumnist &&
                                   !string.IsNullOrWhiteSpace(item.Title) &&
                                   !(string.IsNullOrEmpty(item.Summary) && item.ImageUrl == null) &&
                                   !TextUtil.ContainsBannedWords(item.Title) &&
                                   !TextUtil.ContainsBannedWords(item.Summary) &&
                                   !TextUtil.ContainsBannedWords(item.Detail))
                    .OrderByDescending(item => item.PublishDate)
                    .ToList();

                var recent = filtered.Where(i => i.PublishDate >= cutoff).Take(5).ToList();
                if (recent.Count == 0)
                {
                    recent = filtered.Take(4).ToList();
                }

                foreach (var item in recent)
                {
                    result.Add(new CandidateArticle
                    {
                        Feed = feed,
                        Item = item,
                        Language = lang
                    });
                }
            }

            result = result
                .OrderByDescending(c => c.Item.PublishDate)
                .Take(160)
                .ToList();

            for (int i = 0; i < result.Count; i++)
            {
                result[i].Index = i;
            }

            return result;
        }

        private async Task<NewsOverview> TryAnalyzeWithGeminiAsync(
            List<CandidateArticle> candidates,
            int totalFeeds,
            int totalArticles)
        {
            var prompt = BuildGeminiPrompt(candidates, totalFeeds);
            string responseText = null;

            var apiKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
            if (!string.IsNullOrWhiteSpace(apiKey))
            {
                var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={Uri.EscapeDataString(apiKey)}";
                responseText = await CallGeminiEndpointAsync(url, null, prompt);
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
                        (_location, "gemini-2.0-flash"),
                        ("us-central1", "gemini-2.0-flash")
                    };

                    foreach (var (loc, model) in modelsToTry)
                    {
                        try
                        {
                            var url = $"https://{loc}-aiplatform.googleapis.com/v1/projects/{_projectId}/locations/{loc}/publishers/google/models/{model}:generateContent";
                            responseText = await CallGeminiEndpointAsync(url, token, prompt);
                            if (!string.IsNullOrWhiteSpace(responseText))
                            {
                                break;
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger?.LogDebug($"Vertex AI {model} in {loc} failed: {ex.Message}");
                        }
                    }
                }
            }

            if (string.IsNullOrWhiteSpace(responseText))
            {
                return null;
            }

            var parsed = JsonConvert.DeserializeObject<GeminiOverviewResult>(CleanJsonFence(responseText));
            if (parsed?.Stories == null || parsed.Stories.Count == 0)
            {
                return null;
            }

            var stories = new List<OverviewStory>();
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

                stories.Add(new OverviewStory
                {
                    Id = $"story-{rank}",
                    TitleEn = NullIfEmpty(gs.TitleEn) ?? sources[0].Article.Title,
                    TitleTr = NullIfEmpty(gs.TitleTr) ?? NullIfEmpty(gs.TitleEn) ?? sources[0].Article.Title,
                    TitleEl = NullIfEmpty(gs.TitleEl) ?? NullIfEmpty(gs.TitleEn) ?? sources[0].Article.Title,
                    NarrativeEn = NullIfEmpty(gs.NarrativeEn) ?? string.Empty,
                    NarrativeTr = NullIfEmpty(gs.NarrativeTr) ?? NullIfEmpty(gs.NarrativeEn) ?? string.Empty,
                    NarrativeEl = NullIfEmpty(gs.NarrativeEl) ?? NullIfEmpty(gs.NarrativeEn) ?? string.Empty,
                    ImageUrl = imageUrl,
                    PublishDate = publishDate,
                    Sources = sources
                });
                rank++;
            }

            if (stories.Count == 0)
            {
                return null;
            }

            return new NewsOverview
            {
                Id = "latest",
                GeneratedAt = DateTime.UtcNow,
                TotalFeedsAnalyzed = totalFeeds,
                TotalArticlesAnalyzed = totalArticles,
                SummaryEn = NullIfEmpty(parsed.SummaryEn) ?? "Key stories synthesized across Turkish, Greek, and English newspapers in Cyprus.",
                SummaryTr = NullIfEmpty(parsed.SummaryTr) ?? "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden derlenen öne çıkan haberler.",
                SummaryEl = NullIfEmpty(parsed.SummaryEl) ?? "Οι σημαντικότερες ειδήσεις από τουρκοκυπριακές, ελληνοκυπριακές και αγγλόφωνες εφημερίδες της Κύπρου.",
                Stories = stories
            };
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

        private static string BuildGeminiPrompt(List<CandidateArticle> candidates, int totalFeeds)
        {
            var sb = new StringBuilder();
            sb.AppendLine("You are an expert bicommunal Cyprus news editor fluent in English, Turkish, and Greek.");
            sb.AppendLine($"Below are {candidates.Count} recent news articles from {totalFeeds} Turkish, Greek, and English newspapers across Cyprus.");
            sb.AppendLine("Analyze all articles and identify all major top stories of the day covered across newspapers (the number of stories can vary naturally depending on the day's news, typically between 8 and 18 stories).");
            sb.AppendLine("Prioritize stories covered by multiple newspapers (especially across different language communities in Cyprus) and major island-wide developments, ensuring a balanced selection across Turkish, Greek, and English sources.");
            sb.AppendLine("For each top story:");
            sb.AppendLine("- Write a clear, journalistic headline in English (titleEn), Turkish (titleTr), and Greek (titleEl).");
            sb.AppendLine("- Write a rich 2-4 sentence narrative synthesis in English (narrativeEn), Turkish (narrativeTr), and Greek (narrativeEl) explaining what happened and how the newspapers cover it.");
            sb.AppendLine("- Provide articleIndices: the array of integer indices of all articles from the list below that cover or relate to this story (include at least 1 and up to 6 matching articles from different newspapers).");
            sb.AppendLine("Also provide a 1-2 sentence daily overview summary in English (summaryEn), Turkish (summaryTr), and Greek (summaryEl).");
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
      ""articleIndices"": [0, 5, 12]
    }
  ]
}");
            sb.AppendLine();
            sb.AppendLine("ARTICLES:");

            foreach (var c in candidates)
            {
                var cleanSummary = CleanSnippet(c.Item.Summary ?? c.Item.Detail, 180);
                sb.AppendLine($"[{c.Index}] ({c.Feed.Id} | {c.Feed.Title} | {c.Language}) {c.Item.Title} — {cleanSummary}");
            }

            return sb.ToString();
        }

        private async Task<NewsOverview> AnalyzeWithClusteringFallbackAsync(
            List<CandidateArticle> candidates,
            int totalFeeds,
            int totalArticles)
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
            var clusters = BuildStoryClusters(candidates, minStories: 10, maxStories: 20);

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

                // Translate summaries of the top 3 sources in this cluster to English to build a rich narrative
                var snippetParts = new List<string>();
                foreach (var member in cluster.Take(3))
                {
                    var rawSnippet = CleanSnippet(member.Item.Summary ?? member.Item.Detail, 220);
                    if (!string.IsNullOrWhiteSpace(rawSnippet))
                    {
                        var enSnippet = member.Language == "en"
                            ? rawSnippet
                            : await TranslateViaGtxAsync(rawSnippet, member.Language, "en");
                        if (!string.IsNullOrWhiteSpace(enSnippet))
                        {
                            snippetParts.Add($"{member.Feed.Title} reports: {EnsurePeriod(enSnippet)}");
                        }
                    }
                }

                var sourceNames = string.Join(", ", sources.Select(s => s.FeedTitle).Distinct());
                string narrativeEn;
                if (snippetParts.Count > 1)
                {
                    narrativeEn = $"{string.Join(" ", snippetParts.Take(2))} Covered by {sourceNames}.";
                }
                else if (snippetParts.Count == 1)
                {
                    narrativeEn = snippetParts[0];
                }
                else
                {
                    narrativeEn = $"Reported by {sourceNames}: {EnsurePeriod(enLeadTitle)}";
                }

                var titleTrTask = primary.Language == "tr"
                    ? Task.FromResult(primary.Item.Title)
                    : TranslateViaGtxAsync(enLeadTitle, "en", "tr");

                var titleElTask = primary.Language == "el"
                    ? Task.FromResult(primary.Item.Title)
                    : TranslateViaGtxAsync(enLeadTitle, "en", "el");

                var narrativeTrTask = TranslateViaGtxAsync(narrativeEn, "en", "tr");
                var narrativeElTask = TranslateViaGtxAsync(narrativeEn, "en", "el");

                await Task.WhenAll(titleTrTask, titleElTask, narrativeTrTask, narrativeElTask);

                var imageUrl = cluster
                    .Select(c => c.Item.ImageUrl)
                    .FirstOrDefault(u => u != null);

                var publishDate = EnsureUtc(cluster.Max(c => c.Item.PublishDate));

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
                    Sources = sources
                });

                rank++;
            }

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

            // Rank clusters by: number of distinct languages covered, number of distinct newspapers, image availability, and recency
            var multiSource = rawClusters
                .Where(c => c.Count >= 2)
                .OrderByDescending(c => c.Select(a => a.Language).Distinct().Count())
                .ThenByDescending(c => c.Count)
                .ThenByDescending(c => c.Any(a => a.Item.ImageUrl != null))
                .ThenByDescending(c => c.Max(a => a.Item.PublishDate))
                .ToList();

            var selected = new List<List<CandidateArticle>>();
            selected.AddRange(multiSource.Take(maxStories));

            if (selected.Count < minStories)
            {
                // Ensure balanced representation across TR, EL, and EN single-source top headlines if needed
                var remainingSingle = rawClusters
                    .Where(c => c.Count == 1)
                    .OrderByDescending(c => c[0].Item.ImageUrl != null)
                    .ThenByDescending(c => (c[0].Item.Summary ?? string.Empty).Length)
                    .ThenByDescending(c => c[0].Item.PublishDate)
                    .ToList();

                var langOrder = new[] { "tr", "el", "en" };
                int pass = 0;
                while (selected.Count < minStories && remainingSingle.Count > 0 && pass < 10)
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

            foreach (var c in cluster)
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
                        Url = c.Item.Url
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
