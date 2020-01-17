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
using Amathus.Common.Feeds;

namespace Amathus.Common.Picker
{
    public class WeightedNewsPicker : BaseNewsPicker
    {
        public WeightedNewsPicker(List<Feed> feeds) : base(feeds)
        {
        }

        public override List<Feed> Pick(int limit)
        {
            Feeds = Feeds.OrderBy(feed => feed.AverageItemLength).ToList();
            var remaining = limit;
            var totalAverageItemLength = Feeds.Sum(feed => feed.AverageItemLength);
            foreach (var newsFeed in Feeds)
            {
                var perc = newsFeed.AverageItemLength / totalAverageItemLength;
                var minPerc = 1.0 / Feeds.Count / 2.0;
                var actualPerc = Math.Max(perc, minPerc);
                var count = (int)Math.Round(limit * actualPerc);
                var actualCount = Math.Min(remaining, count);
                newsFeed.Items = newsFeed.Items.Take(actualCount).ToList();
                remaining -= actualCount;
            }
            return Feeds.OrderByDescending(feed => feed.Items.Count()).ThenBy(feed => feed.Id).ToList();
        }
    }
}
