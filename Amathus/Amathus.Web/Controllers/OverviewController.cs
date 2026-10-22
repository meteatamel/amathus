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
        public async Task<IActionResult> Get([FromQuery] bool refresh = false)
        {
            if (!refresh)
            {
                var existing = await _feedStore.ReadOverviewAsync();
                if (existing != null && existing.Stories != null && existing.Stories.Count > 0)
                {
                    return Ok(existing);
                }
            }

            await GenerationLock.WaitAsync();
            try
            {
                if (!refresh)
                {
                    var existing = await _feedStore.ReadOverviewAsync();
                    if (existing != null && existing.Stories != null && existing.Stories.Count > 0)
                    {
                        return Ok(existing);
                    }
                }

                var feeds = await _feedStore.ReadAllAsync();
                if (feeds == null || !feeds.Any())
                {
                    return NotFound();
                }

                _logger.LogInformation("Generating daily overview on demand...");
                var overview = await _overviewAnalyzer.AnalyzeAsync(feeds);
                await _feedStore.SaveOverviewAsync(overview);
                return Ok(overview);
            }
            finally
            {
                GenerationLock.Release();
            }
        }
    }
}
