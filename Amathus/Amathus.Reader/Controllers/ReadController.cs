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
using Amathus.Common.Reader;
using Amathus.Common.FeedStore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Reader.Controllers
{
    [Route("")]
    public class ReadController : ControllerBase
    {
        private readonly ILogger _logger;
        private readonly IFeedReader _reader;
        private readonly ISyndFeedStore _syncStore;

        public ReadController(IFeedReader reader, ISyndFeedStore syncStore, ILogger<ReadController> logger)
        {
            _reader = reader;
            _syncStore = syncStore;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Read()
        {
            _logger?.LogInformation("Fetching feeds");
            var stopWatch = new Stopwatch();
            stopWatch.Start();

            var rawFeeds = (await _reader.ReadAll()).ToList();
            rawFeeds.ForEach(async rawFeed =>
            {
                await _syncStore.InsertAsync(rawFeed);
            });

            stopWatch.Stop();
            _logger?.LogInformation($"Fetching news feeds finished in {stopWatch.Elapsed.Seconds} seconds. Total feeds: {rawFeeds.Count}");

            return Ok();
        }
    }
}
