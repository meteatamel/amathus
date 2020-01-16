// Copyright 2019 Google LLC
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
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Amathus.Common.Feeds;
using Amathus.Common.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Fetcher.Controllers
{
    [Route("api/v1/[controller]")]
    public class FetchController : ControllerBase
    {
        private readonly ILogger _logger;
        private readonly IFeedStore _feedStore;
        private readonly FeedReader _feedReader;

        public FetchController(IFeedStore feedStore, ILogger<FetchController> logger)
        {
            _feedStore = feedStore;
            _logger = logger;
            _feedReader = new FeedReader(_logger);
        }

        [HttpGet]
        public async Task<IActionResult> Fetch()
        {
            _logger?.LogInformation("Fetching feeds");
            var stopWatch = new Stopwatch();
            stopWatch.Start();

            var feeds = (await _feedReader.Read()).ToList();
            feeds.ForEach(feed => _feedStore.InsertAsync(feed));

            stopWatch.Stop();
            _logger?.LogInformation($"Fetching news feeds finished in {stopWatch.Elapsed.Seconds} seconds. Total feeds: {feeds.Count}");

            return Ok();
        }
    }
}
