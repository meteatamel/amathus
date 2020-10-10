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
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amathus.Common.Feeds;
using Amathus.Common.Picker;
using Amathus.Common.FeedStore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.Controllers
{
    [Produces("application/json")]
    [Route("api/v1/[controller]")]
    public class FeedItemsController : ControllerBase
    {
        private readonly ILogger _logger;
        private readonly IFeedStore _feedStore;

        public FeedItemsController(IFeedStore feedStore, ILogger<FeedItemsController> logger)
        {
            _feedStore = feedStore;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            if (limit != null && limit < 1)
            {
                return BadRequest("Limit cannot be less than 1");
            }

            var feeds = await GetAllFromCache();
            if (!feeds.Any())
            {
                return NotFound();
            }

            if (from != null)
            {
                var sinceUtc = ((DateTime)from).ToUniversalTime();
                feeds = feeds.Select(feed =>
                {
                    feed.Items = feed.Items.Where(item => item.PublishDate >= sinceUtc).ToList();
                    return feed;
                }).ToList();
            }

            if (limit == null)
            {
                return Ok(feeds);
            }

            var picker = new LimitedFeedItemPicker(feeds);
            var picked = picker.Pick((int)limit);
            return Ok(picked);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id, [FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            if (limit != null && limit < 1)
            {
                return BadRequest("Limit cannot be less than 1");
            }

            id = id.ToLowerInvariant();

            var feed = await _feedStore.ReadAsync(id);
            if (feed == null)
            {
                return NotFound();
            }


            if (from != null)
            {
                var sinceUtc = ((DateTime)from).ToUniversalTime();
                feed.Items = feed.Items.Where(item => item.PublishDate >= sinceUtc).ToList();
            }

            if (limit != null)
            {
                feed.Items = feed.Items.Take((int)limit).ToList();
            }

            return Ok(feed);
        }

        private async Task<List<Feed>> GetAllFromCache()
        {
            var feeds = await _feedStore.ReadAllAsync();
            feeds = feeds.OrderByDescending(feed => feed.AverageItemLength).ToList();
            return feeds;
        }
    }
}
