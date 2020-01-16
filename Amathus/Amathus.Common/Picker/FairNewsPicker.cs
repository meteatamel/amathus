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
    public class FairNewsPicker : BaseNewsPicker
    {
        public FairNewsPicker(List<Feed> newsFeeds) : base(newsFeeds)
        {
        }

        public override List<Feed> Pick(int limit)
        {
            var numberOfNewsItemsPerSource = limit / NumberOfNewsSources;
            var remainingNewsItems = limit % NumberOfNewsSources;
            
            foreach (var newsFeed in NewsFeeds)
            {
                if (remainingNewsItems > 0)
                {
                    newsFeed.Items = newsFeed.Items.Take(numberOfNewsItemsPerSource + 1).ToList();
                    remainingNewsItems--;
                }
                else
                {
                    newsFeed.Items = newsFeed.Items.Take(numberOfNewsItemsPerSource).ToList();
                }
            }
            return NewsFeeds;
        }


    }
}
