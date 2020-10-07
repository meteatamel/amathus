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
using System.Linq;
using System.Threading.Tasks;
using Amathus.Common.FeedStore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.Controllers
{
    [Produces("application/json")]
    [Route("api/v1/[controller]")]
    public class FeedsController : ControllerBase
    {
        private readonly ILogger _logger;
        private readonly IFeedStore _feedStore;

        public FeedsController(IFeedStore feedStore, ILogger<FeedItemsController> logger)
        {
            _feedStore = feedStore;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var feeds = await _feedStore.ReadAllAsync();
            if (!feeds.Any())
            {
                return NotFound();
            }

            feeds.ForEach(feed => feed.Items = null);

            return Ok(feeds);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id)
        {
            id = id.ToLowerInvariant();

            var feed = await _feedStore.ReadAsync(id);
            if (feed == null)
            {
                return NotFound();
            }

            feed.Items = null;

            return Ok(feed);
        }
    }
}
