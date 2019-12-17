using System;
using System.Collections.Generic;
using System.Linq;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.News.Picker
{
    public class WeightedNewsPicker : BaseNewsPicker
    {
        private static readonly double MinPercentage = 1.0 / NumberOfNewsSources / 2.0;

        public WeightedNewsPicker(List<Feed> newsFeeds) : base(newsFeeds)
        {
        }

        public override List<Feed> Pick(int limit)
        {
            NewsFeeds = NewsFeeds.OrderBy(feed => feed.AverageItemLength).ToList();
            var remaining = limit;
            var totalAverageItemLength = NewsFeeds.Sum(feed => feed.AverageItemLength);
            foreach (var newsFeed in NewsFeeds)
            {
                var perc = newsFeed.AverageItemLength / totalAverageItemLength;
                var actualPerc = Math.Max(perc, MinPercentage);
                var count = (int)Math.Round(limit * actualPerc);
                var actualCount = Math.Min(remaining, count);
                newsFeed.Items = newsFeed.Items.Take(actualCount);
                remaining -= actualCount;
            }
            return NewsFeeds.OrderByDescending(feed => feed.Items.Count()).ThenBy(feed => feed.Id).ToList();
        }
    }
}
