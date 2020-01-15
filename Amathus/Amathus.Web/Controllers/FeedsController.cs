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
using Amathus.Reader.Feeds;
using Amathus.Reader.Picker;
using Amathus.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.Controllers
{
    [Produces("application/json")]
    //[Route("api/v1/[controller]")]
    [Route("api/v1/news")]
    public class FeedsController : ControllerBase
    {
        private readonly ILogger _logger;
        private readonly IFeedStore _feedStore;

        public FeedsController(IFeedStore feedStore, ILogger<FeedsController> logger)
        {
            _feedStore = feedStore;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            _logger.LogInformation($"GetAll limit: {limit}, from: {from}");

            if (limit != null && limit < 1)
            {
                return BadRequest("Limit cannot be less than 1");
            }

            var feeds = await GetAllFromCache();
            feeds = feeds.ToList();
            if (!feeds.Any()) return NotFound();

            var copies = feeds.Select(feed => feed.Copy()).ToList();

            if (from != null)
            {
                var sinceUtc = ((DateTime)from).ToUniversalTime();
                copies = copies.Select(feed =>
                {
                    feed.Items = feed.Items.Where(item => item.PublishDate >= sinceUtc).ToList();
                    return feed;
                }).ToList();
            }

            if (limit == null) return Ok(copies);

            //var picker = new FairNewsPicker(copies);
            var picker = new WeightedNewsPicker(copies);
            var pickedNews = picker.Pick((int)limit);
            return Ok(pickedNews);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id, [FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            if (!Enum.TryParse(id, true, out FeedId feedId))
            {
                return BadRequest("Id is not valid");
            }

            if (limit != null && limit < 1)
            {
                return BadRequest("Limit cannot be less than 1");
            }

            var feed = await _feedStore.ReadAsync(feedId);
            if (feed == null)
            {
                return NotFound();
            }

            // TODO - I don't think we need to copy anymore.
            var copy = feed.Copy();

            if (from != null)
            {
                var sinceUtc = ((DateTime)from).ToUniversalTime();
                copy.Items = copy.Items.Where(item => item.PublishDate >= sinceUtc).ToList();
            }

            if (limit != null)
            {
                copy.Items = copy.Items.Take((int)limit).ToList();
            }

            return Ok(feed);
        }

        private async Task<IEnumerable<Feed>> GetAllFromCache()
        {
            var feeds = new List<Feed>();

            var feedIds = Enum.GetValues(typeof(FeedId)).Cast<FeedId>().ToArray();
            foreach (var feedId in feedIds)
            {
                var feed = await _feedStore.ReadAsync(feedId);
                if (feed != null)
                {
                    feeds.Add(feed);
                }
            }

            feeds = feeds.OrderByDescending(feed => feed.AverageItemLength).ToList();
            return feeds;
        }
    }
}
