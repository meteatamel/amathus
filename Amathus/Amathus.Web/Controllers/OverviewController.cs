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
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Amathus.Common.FeedStore;
using Amathus.Common.Overview;
using Amathus.Common.Util;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.Controllers
{
    [Produces("application/json")]
    [Route("api/v1/[controller]")]
    [ApiController]
    public class OverviewController : ControllerBase
    {
        private static readonly SemaphoreSlim GenerationLock = new(1, 1);

        private readonly IFeedStore _feedStore;
        private readonly IOverviewAnalyzer _overviewAnalyzer;
        private readonly ILogger<OverviewController> _logger;

        public OverviewController(
            IFeedStore feedStore,
            IOverviewAnalyzer overviewAnalyzer,
            ILogger<OverviewController> logger)
        {
            _feedStore = feedStore;
            _overviewAnalyzer = overviewAnalyzer;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Get(
            [FromQuery] bool refresh = false,
            [FromQuery] string edition = null,
            [FromQuery] bool columnists = false)
        {
            var overviewId = columnists ? "latest_columnists" : "latest";

            if (!refresh)
            {
                var existing = await _feedStore.ReadOverviewAsync(overviewId);
                if (existing != null && existing.Stories != null && existing.Stories.Count > 0)
                {
                    var copy = existing.Copy();
                    EnsureStoryTopicsPopulated(copy);
                    bool storiesRepaired = await OverviewAnalyzer.EnsureStoriesTranslatedAsync(copy);
                    bool podcastRebuilt = PodcastScriptBuilder.EnsurePodcastPopulated(copy, edition, forceRebuild: storiesRepaired);
                    if (storiesRepaired || podcastRebuilt)
                    {
                        _ = _feedStore.SaveOverviewAsync(copy);
                    }
                    _ = WarmupInitialPodcastTurnsAsync(copy);
                    return Ok(copy);
                }
            }

            await GenerationLock.WaitAsync();
            try
            {
                if (!refresh)
                {
                    var existing = await _feedStore.ReadOverviewAsync(overviewId);
                    if (existing != null && existing.Stories != null && existing.Stories.Count > 0)
                    {
                        var copy = existing.Copy();
                        EnsureStoryTopicsPopulated(copy);
                        bool storiesRepaired = await OverviewAnalyzer.EnsureStoriesTranslatedAsync(copy);
                        bool podcastRebuilt = PodcastScriptBuilder.EnsurePodcastPopulated(copy, edition, forceRebuild: storiesRepaired);
                        if (storiesRepaired || podcastRebuilt)
                        {
                            _ = _feedStore.SaveOverviewAsync(copy);
                        }
                        _ = WarmupInitialPodcastTurnsAsync(copy);
                        return Ok(copy);
                    }
                }

                var feeds = await _feedStore.ReadAllAsync();
                if (feeds == null || !feeds.Any())
                {
                    return NotFound();
                }

                _logger.LogInformation($"Generating daily overview (columnists={columnists}) on demand...");
                var overview = await _overviewAnalyzer.AnalyzeAsync(feeds, columnists);
                overview.Id = overviewId;
                EnsureStoryTopicsPopulated(overview);
                bool storiesRepairedOnGen = await OverviewAnalyzer.EnsureStoriesTranslatedAsync(overview);
                PodcastScriptBuilder.EnsurePodcastPopulated(overview, edition, forceRebuild: storiesRepairedOnGen);
                await _feedStore.SaveOverviewAsync(overview);
                _ = WarmupInitialPodcastTurnsAsync(overview);
                return Ok(overview);
            }
            finally
            {
                GenerationLock.Release();
            }
        }

        private static void EnsureStoryTopicsPopulated(NewsOverview overview)
        {
            if (overview?.Stories == null)
            {
                return;
            }

            foreach (var story in overview.Stories)
            {
                if (story == null)
                {
                    continue;
                }

                var normalized = TextUtil.NormalizeTopic(story.Topic);
                if (normalized == null)
                {
                    var firstSource = story.Sources?.FirstOrDefault()?.Article;
                    normalized = TextUtil.ClassifyTopic(
                        $"{story.TitleEn} {story.TitleTr} {story.TitleEl}",
                        $"{story.NarrativeEn} {story.NarrativeTr} {story.NarrativeEl}",
                        firstSource?.Summary,
                        firstSource?.Url?.AbsoluteUri);
                }
                story.Topic = normalized;
            }
        }

        private static async Task WarmupInitialPodcastTurnsAsync(NewsOverview overview)
        {
            if (overview?.PodcastTurns == null || overview.PodcastTurns.Count == 0)
            {
                return;
            }

            try
            {
                var turnsToWarm = overview.PodcastTurns.Take(2).ToList();
                foreach (var lang in new[] { "en", "tr", "el" })
                {
                    foreach (var turn in turnsToWarm)
                    {
                        var text = lang switch
                        {
                            "tr" => turn.TextTr,
                            "el" => turn.TextEl,
                            _ => turn.TextEn
                        };
                        if (!string.IsNullOrWhiteSpace(text))
                        {
                            await PodcastTtsService.SynthesizeMp3Async(
                                text,
                                lang,
                                turn.Speaker ?? "A",
                                PodcastTtsService.DefaultVoicePreset);
                        }
                    }
                }
            }
            catch
            {
                // Best-effort background cache warmup
            }
        }

        [HttpGet("podcast/audio")]
        [Produces("audio/wav", "audio/mpeg")]
        public async Task<IActionResult> GetPodcastAudio(
            [FromQuery] string lang = "en",
            [FromQuery] string speaker = "A",
            [FromQuery] string voicePreset = null,
            [FromQuery] string text = "",
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return BadRequest("Text parameter is required.");
            }

            var audioBytes = await PodcastTtsService.SynthesizeMp3Async(
                text,
                lang,
                speaker,
                voicePreset,
                cancellationToken);

            if (audioBytes == null || audioBytes.Length == 0)
            {
                return StatusCode(502, "Failed to synthesize podcast audio.");
            }

            bool isWav = audioBytes.Length > 4 &&
                         audioBytes[0] == 0x52 && // 'R'
                         audioBytes[1] == 0x49 && // 'I'
                         audioBytes[2] == 0x46 && // 'F'
                         audioBytes[3] == 0x46;   // 'F'

            Response.Headers["Cache-Control"] = "public, max-age=86400";
            return File(audioBytes, isWav ? "audio/wav" : "audio/mpeg", enableRangeProcessing: true);
        }
    }
}
