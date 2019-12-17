using System;
using System.Collections.Generic;
using System.Linq;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.News.Picker;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;

namespace Amathus.Web.Controllers
{
    public abstract class BaseController : ControllerBase
    {
        protected abstract string GetKeyPrefix();   
        
        protected IMemoryCache Cache;

        protected BaseController(IMemoryCache cache) 
        {
            Cache = cache;
        }

        public IActionResult GetAll([FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            if (limit != null && limit < 1) return BadRequest("Limit cannot be less than 1");

            var feeds = GetAllFromCache().ToList();
            if (!feeds.Any()) return NotFound();

            var copies = feeds.Select(feed => feed.Copy()).ToList();

            if (from != null)
            {
                var sinceUtc = ((DateTime) from).ToUniversalTime();
                copies = copies.Select(feed =>
                {
                    feed.Items = feed.Items.Where(item => item.PublishDate >= sinceUtc);
                    return feed;
                }).ToList();
            }

            if (limit == null) return Ok(copies);

            //var picker = new FairNewsPicker(copies);
            var picker = new WeightedNewsPicker(copies);
            var pickedNews = picker.Pick((int) limit);
            return Ok(pickedNews);
        }

        public IActionResult GetById(string id, [FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            if (!Enum.TryParse(id, true, out FeedId sourceId)) return BadRequest("Id is not valid");
            if (limit != null && limit < 1) return BadRequest("Limit cannot be less than 1");

            var feed = GetItemFromCache(id);
            if (feed == null) return NotFound();

            var copy = feed.Copy();

            if (from != null)
            {
                var sinceUtc = ((DateTime) from).ToUniversalTime();
                copy.Items = copy.Items.Where(item => item.PublishDate >= sinceUtc);
            }

            if (limit != null)
            {
                copy.Items = copy.Items.Take((int) limit);
            }

            return Ok(copy);
        }


        private IEnumerable<Feed> GetAllFromCache()
        {
            var feeds = new List<Feed>();
            
            var feedIds = Enum.GetValues(typeof(FeedId)).Cast<FeedId>().ToArray();
            foreach (var feedId in feedIds)
            {
                var feed = GetItemFromCache(feedId.ToString());
                if (feed != null)
                {
                    feeds.Add(feed);
                }
            }
        
            feeds = feeds.OrderByDescending(feed => feed.AverageItemLength).ToList();
            return feeds;
        }

        private Feed GetItemFromCache(string key)
        {
            return (Feed)Cache.Get(GetKeyPrefix() + "_" + key.ToLowerInvariant());
        }
    }
}