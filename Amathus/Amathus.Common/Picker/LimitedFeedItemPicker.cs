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
    public class LimitedFeedItemPicker : IFeedItemPicker
    {
        private readonly List<Feed> _feeds;

        public LimitedFeedItemPicker(List<Feed> feeds)
        {
            _feeds = feeds;
        }

        public List<Feed> Pick(int limit)
        {
            var feedsWithItems = _feeds.Where(feed => feed.Items != null && feed.Items.Count != 0).ToList();
            if (feedsWithItems.Count == 0)
            {
                return feedsWithItems;
            }

            var numberOfItemsPerSource = limit / feedsWithItems.Count;
            var remainingItems = limit % feedsWithItems.Count;
            var recentTechCutoff = DateTime.UtcNow.AddDays(-7);

            foreach (var feed in feedsWithItems)
            {
                var takeCount = numberOfItemsPerSource + (remainingItems > 0 ? 1 : 0);
                if (remainingItems > 0)
                {
                    remainingItems--;
                }

                var allItems = feed.Items;
                var picked = allItems.Take(takeCount).ToList();

                if (picked.Count >= 2 &&
                    allItems.Count > picked.Count &&
                    !picked.Any(i => string.Equals(i?.Topic, "tech", StringComparison.OrdinalIgnoreCase)))
                {
                    var recentTechItem = allItems
                        .Skip(picked.Count)
                        .FirstOrDefault(i =>
                            i != null &&
                            !i.IsColumnist &&
                            string.Equals(i.Topic, "tech", StringComparison.OrdinalIgnoreCase) &&
                            i.PublishDate >= recentTechCutoff);

                    if (recentTechItem != null)
                    {
                        picked[picked.Count - 1] = recentTechItem;
                    }
                }

                feed.Items = picked;
            }

            return feedsWithItems.Where(feed => feed.Items != null && feed.Items.Count != 0).ToList();
        }
    }
}
