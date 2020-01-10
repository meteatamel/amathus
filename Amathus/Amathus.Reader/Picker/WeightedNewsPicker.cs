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
using Amathus.Reader.Feeds;

namespace Amathus.Reader.Picker
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
