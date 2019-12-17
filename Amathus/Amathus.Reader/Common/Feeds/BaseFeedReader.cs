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
using Amathus.Reader.Common.Sources;
using log4net;

namespace Amathus.Reader.Common.Feeds
{
    public abstract class BaseFeedReader<T> : IFeedReader
    {
        public async Task<IEnumerable<Feed>> Read()
        {
            var tasks = GetFeedIds().Select(feedId => Task.Run(() => Read(feedId)));
            var results = await Task.WhenAll(tasks);
            return results.Where(feed => feed != null);
        }

        public Feed Read(FeedId sourceId)
        {
            try
            {
                var source = GetSource(sourceId);
                var rawFeed = LoadFeed(source.Url);
                var feed = source.Converter.Convert(source, rawFeed);
                GetLogger().DebugFormat($"News source:{feed.Id} => {feed.AverageItemLength}");
                return feed;

            }
            catch (Exception ex)
            {
                GetLogger().Error("Error during feed read: " + sourceId, ex);
                return null;
            }
        }

        protected abstract FeedId[] GetFeedIds();

        protected abstract ILog GetLogger();

        protected abstract Source<T> GetSource(FeedId sourceId);

        protected abstract T LoadFeed(Uri sourceUrl);
    }
}
