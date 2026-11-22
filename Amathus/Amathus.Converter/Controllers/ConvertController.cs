// Copyright 2020 Google LLC
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
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Amathus.Common.Converter;
using Amathus.Common.FeedStore;
using Amathus.Common.Notifications;
using Amathus.Common.Overview;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace Amathus.Converter.Controllers
{
    [Route("")]
    public class ConvertController : ControllerBase
    {
        private static readonly SemaphoreSlim OverviewRefreshLock = new(1, 1);
        private static DateTime _lastOverviewCheckUtc = DateTime.MinValue;

        private readonly ILogger _logger;
        private readonly ISyndFeedStore _syndStore;
        private readonly IFeedConverter _converter;
        private readonly IFeedStore _store;
        private readonly IOverviewAnalyzer _overviewAnalyzer;
        private readonly FcmNotificationService _notificationService;

        public ConvertController(
            ISyndFeedStore syndStore,
            IFeedConverter converter,
            IFeedStore store,
            IOverviewAnalyzer overviewAnalyzer,
            FcmNotificationService notificationService,
            ILogger<ConvertController> logger)
        {
            _syndStore = syndStore;
            _converter = converter;
            _store = store;
            _overviewAnalyzer = overviewAnalyzer;
            _notificationService = notificationService;
            _logger = logger;
        }

        [HttpPost]
        public async Task<IActionResult> Convert()
        {
            using (var reader = new StreamReader(HttpContext.Request.Body))
            {
                var content = await reader.ReadToEndAsync();
                _logger?.LogInformation("Converter received event: " + content);

                dynamic json = JValue.Parse(content);

                var attributes = json.message.attributes;
                var eventType = attributes.eventType;
                if (eventType != "OBJECT_FINALIZE")
                {
                    return Ok();
                }

                try
                {
                    var stopWatch = new Stopwatch();
                    stopWatch.Start();

                    var feedId = (string)attributes.objectId;
                    if (string.IsNullOrWhiteSpace(feedId) || feedId.Contains('/'))
                    {
                        _logger.LogInformation($"Ignoring non-feed object: {feedId}");
                        return Ok();
                    }
                    _logger.LogInformation($"Reading raw feed: {feedId}");
                    var rawFeed = await _syndStore.ReadAsync(feedId);

                    _logger.LogInformation($"Converting raw feed: {feedId}");
                    var feed = _converter.Convert(feedId, rawFeed);

                    _logger.LogInformation($"Inserting into backend: {feedId}");
                    await _store.InsertAsync(feed);

                    stopWatch.Stop();
                    _logger?.LogInformation($"Converting feed finished in {stopWatch.Elapsed.Seconds} seconds.");
                }
                catch (Exception e)
                {
                    _logger.LogError($"Error reading or converting feed: {e.Message}");
                }
            }

            return Ok();
        }

        [HttpGet("refresh-overview")]
        [HttpPost("refresh-overview")]
        public async Task<IActionResult> RefreshOverview([FromQuery] bool force = false, [FromQuery] bool notify = true)
        {
            if (_overviewAnalyzer == null)
            {
                return StatusCode(500, "Overview analyzer is not configured.");
            }

            if (!await OverviewRefreshLock.WaitAsync(0))
            {
                _logger?.LogInformation("Overview refresh already in progress on this instance; skipping duplicate trigger.");
                return Ok(new { status = "already_running" });
            }

            try
            {
                if (!force)
                {
                    var currentOverview = await _store.ReadOverviewAsync();
                    if (currentOverview != null && (DateTime.UtcNow - currentOverview.GeneratedAt.ToUniversalTime()) < TimeSpan.FromMinutes(30))
                    {
                        _lastOverviewCheckUtc = DateTime.UtcNow;
                        _logger?.LogInformation("Skipping overview refresh; latest overview is less than 30 minutes old.");
                        return Ok(new { status = "fresh", generatedAt = currentOverview.GeneratedAt });
                    }
                }

                var allFeeds = await _store.ReadAllAsync();
                if (allFeeds == null || allFeeds.Count < 5)
                {
                    return Ok(new { status = "insufficient_feeds", feedCount = allFeeds?.Count ?? 0 });
                }

                _logger?.LogInformation("Refreshing daily overview and columnists overview in Firestore...");
                var overview = await _overviewAnalyzer.AnalyzeAsync(allFeeds, columnistsOnly: false);
                overview.Id = "latest";
                await _store.SaveOverviewAsync(overview);

                var columnistsOverview = await _overviewAnalyzer.AnalyzeAsync(allFeeds, columnistsOnly: true);
                columnistsOverview.Id = "latest_columnists";
                await _store.SaveOverviewAsync(columnistsOverview);

                _lastOverviewCheckUtc = DateTime.UtcNow;

                System.Collections.Generic.Dictionary<string, string> notifications = null;
                if (notify && _notificationService != null)
                {
                    notifications = await _notificationService.SendEditionBriefingAsync(overview);
                }

                return Ok(new
                {
                    status = "refreshed",
                    edition = overview.Edition,
                    stories = overview.Stories?.Count ?? 0,
                    columnistStories = columnistsOverview.Stories?.Count ?? 0,
                    generatedAt = overview.GeneratedAt,
                    notifications
                });
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, $"Could not refresh overview: {ex.Message}");
                return StatusCode(500, "Overview refresh failed.");
            }
            finally
            {
                OverviewRefreshLock.Release();
            }
        }

        private string ConstructStorageUrl(dynamic attributes)
        {
            return attributes == null ? null
                : string.Format("gs://{0}/{1}", attributes.bucketId, attributes.objectId);
        }
    }
}
