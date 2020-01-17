// Copyright 2020 Google LLC
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
using System.Threading.Tasks;
using Amathus.Common.Feeds;

namespace Amathus.Common.FeedStore
{
    public class InMemoryFeedStore : IFeedStore
    {
        Dictionary<string, Feed> _feeds;
    
        public InMemoryFeedStore()
        {
            _feeds = new Dictionary<string, Feed>();
        }

        public Task InsertAsync(Feed feed)
        {
            if (feed != null)
            {
                _feeds[feed.Id] = feed;
            }
            return Task.CompletedTask;
        }

        public Task<Feed> ReadAsync(string id)
        {
            // Making a copy before returning, so filtering from contrllers
            // can work indepdently.
            var feed = _feeds.ContainsKey(id) ? _feeds[id].Copy(): null;
            return Task.FromResult(feed);
        }

        public Task<List<Feed>> ReadAllAsync()
        {
            var feeds = new List<Feed>();
            foreach(var feed in _feeds.Values)
            {
                feeds.Add(feed.Copy());
            }
            return Task.FromResult(feeds);
        }
    }
}
