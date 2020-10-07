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
using System.Threading.Tasks;
using Amathus.Common.Converter;
using Amathus.Common.FeedStore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace Amathus.Converter.Controllers
{
    [Route("")]
    public class ConvertController : ControllerBase
    {
        private readonly ILogger _logger;
        private readonly ISyndFeedStore _syndStore;
        private readonly IFeedConverter _converter;
        private readonly IFeedStore _store;

        public ConvertController(ISyndFeedStore syndStore, IFeedConverter converter, IFeedStore store, ILogger<ConvertController> logger)
        {
            _syndStore = syndStore;
            _converter = converter;
            _store = store;
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

        private string ConstructStorageUrl(dynamic attributes)
        {
            return attributes == null ? null
                : string.Format("gs://{0}/{1}", attributes.bucketId, attributes.objectId);
        }
    }
}
