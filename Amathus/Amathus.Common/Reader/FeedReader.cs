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
using System.ServiceModel.Syndication;
using System.Threading.Tasks;
using Amathus.Common.Sources;
using Microsoft.Extensions.Logging;

namespace Amathus.Common.Reader
{
    public class FeedReader : IFeedReader
    {
        private readonly List<Source> _sources;
        private readonly ILogger _logger;

        public FeedReader(List<Source> sources, ILogger logger = null)
        {
            _sources = sources;
            _logger = logger;
        }

        public async Task<IEnumerable<SyndicationFeed>> ReadAll()
        {
            var tasks = _sources.Select(source => Task.Run(() => Read(source)));
            var results = await Task.WhenAll(tasks);
            return results.Where(feed => feed != null);
        }

        public SyndicationFeed Read(Source source)
        {
            try
            {
                _logger?.LogDebug($"Reading feed: {source.Id}");
                var feed = LoadFeed(source.Url);
                feed.Id = source.Id;
                return feed;
            }
            catch (Exception ex)
            {
                _logger?.LogError($"Reading failed for feed: {source.Id}", ex);
                return null;
            }
        }

        private SyndicationFeed LoadFeed(Uri sourceUrl)
        {
            var reader = new DateTolerantXmlTextReader(sourceUrl.ToString());
            var rawFeed = SyndicationFeed.Load(reader);
            reader.Close();
            return rawFeed;
        }
    }
}
