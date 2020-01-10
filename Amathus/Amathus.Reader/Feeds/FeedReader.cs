﻿// Copyright 2019 Google LLC
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
using System.ServiceModel.Syndication;
using System.Threading.Tasks;
using Amathus.Reader.Sources;
using Microsoft.Extensions.Logging;

namespace Amathus.Reader.Feeds
{
    public class FeedReader : IFeedReader
    {
        private readonly ILogger _logger;

        public FeedReader(ILogger logger = null)
        {
            _logger = logger;
        }

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
                _logger?.LogDebug($"Reading feed: {sourceId}");
                var source = GetSource(sourceId);
                var rawFeed = LoadFeed(source.Url);

                _logger?.LogDebug($"Converting feed: {sourceId}");
                var feed = source.Converter.Convert(source, rawFeed);

                _logger?.LogDebug($"Feed average item length: {feed.AverageItemLength}");

                return feed;

            }
            catch (Exception ex)
            {
                _logger?.LogError($"Reading failed for feed: {sourceId}", ex);
                return null;
            }
        }

        private FeedId[] GetFeedIds()
        {
            return Enum.GetValues(typeof(FeedId)).Cast<FeedId>().ToArray();
        }

        private Source<SyndicationFeed> GetSource(FeedId sourceId)
        {
            return NewsSourceBuilder.Build(sourceId);
        }

        private SyndicationFeed LoadFeed(Uri sourceUrl)
        {
            var reader = new DateInvariantXmlReader(sourceUrl.ToString());
            var rawFeed = SyndicationFeed.Load(reader);
            reader.Close();
            return rawFeed;
        }
    }
}