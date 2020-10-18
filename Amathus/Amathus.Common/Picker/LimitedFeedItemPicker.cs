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
            var numberOfItemsPerSource = limit / _feeds.Count;
            var remainingItems = limit % _feeds.Count;
            
            foreach (var feed in _feeds)
            {
                if (remainingItems > 0)
                {
                    feed.Items = feed.Items.Take(numberOfItemsPerSource + 1).ToList();
                    remainingItems--;
                }
                else
                {
                    feed.Items = feed.Items.Take(numberOfItemsPerSource).ToList();
                }
            }

            var feedsWithItems = _feeds.Where(feed => feed.Items != null && feed.Items.Count != 0).ToList();
            return feedsWithItems;
        }
    }
}
