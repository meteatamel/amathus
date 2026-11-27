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
using System.Threading.Tasks;
using Amathus.Common.FeedStore;
using Amathus.Common.Translation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

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

        private const int MaxTitleChars = 500;
        private const int MaxSummaryChars = 2500;
        private const int MaxDetailChars = 15000;
        private const int MaxRequestsPerIpPerMinute = 120;

        private static readonly ConcurrentDictionary<string, (DateTime WindowStart, int Count)> RateLimitBuckets = new();

        private readonly IFeedStore _store;
        private readonly ILogger<TranslateController> _logger;

        public TranslateController(IFeedStore store, IConfiguration configuration, ILogger<TranslateController> logger)
        {
            _store = store;
            _logger = logger;
            var projectId = configuration?["Amathus:ProjectId"] ?? "events-atamel";
            GeminiTranslationService.Configure(projectId, store, logger);
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

            if ((request.Title?.Length ?? 0) > MaxTitleChars ||
                (request.Summary?.Length ?? 0) > MaxSummaryChars ||
                (request.Detail?.Length ?? 0) > MaxDetailChars)
            {
                return BadRequest("Payload exceeds maximum allowed length for translation.");
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

            if (IsRateLimited())
            {
                return StatusCode(429, "Too many translation requests. Please slow down.");
            }

            try
            {
                var translated = await GeminiTranslationService.TranslateArticleAsync(
                    title: request.Title,
                    summary: request.Summary,
                    detail: request.Detail,
                    sourceLang: sourceLang,
                    targetLang: targetLang,
                    storeOverride: _store,
                    loggerOverride: _logger);

                return Ok(new TranslateResponse
                {
                    Title = translated.Title,
                    Summary = translated.Summary,
                    Detail = translated.Detail,
                    SourceLanguage = translated.SourceLanguage,
                    TargetLanguage = translated.TargetLanguage
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Translation failed for targetLanguage={targetLang}");
                return StatusCode(500, "Translation failed.");
            }
        }

        private bool IsRateLimited()
        {
            var ip = HttpContext?.Request?.Headers["X-Forwarded-For"].ToString();
            if (!string.IsNullOrWhiteSpace(ip))
            {
                var commaIdx = ip.IndexOf(',');
                if (commaIdx > 0)
                {
                    ip = ip.Substring(0, commaIdx);
                }
                ip = ip.Trim();
            }
            else
            {
                ip = HttpContext?.Connection?.RemoteIpAddress?.ToString() ?? "unknown";
            }

            var now = DateTime.UtcNow;
            if (RateLimitBuckets.Count > 5000)
            {
                RateLimitBuckets.Clear();
            }

            var bucket = RateLimitBuckets.AddOrUpdate(
                ip,
                _ => (now, 1),
                (_, existing) => (now - existing.WindowStart) >= TimeSpan.FromMinutes(1)
                    ? (now, 1)
                    : (existing.WindowStart, existing.Count + 1));

            return bucket.Count > MaxRequestsPerIpPerMinute;
        }
    }
}
