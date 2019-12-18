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
using System.Linq;
using System.ServiceModel.Syndication;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.Common.Sources;
using Amathus.Reader.News.Sources;
using Amathus.Reader.News.Xml;
using Microsoft.Extensions.Logging;

namespace Amathus.Reader.News
{
    public class NewsReader : BaseFeedReader<SyndicationFeed>
    {
        public NewsReader(ILogger logger = null):base(logger)
        {
        }

        protected override FeedId[] GetFeedIds()
        {
            return Enum.GetValues(typeof(FeedId)).Cast<FeedId>().ToArray();
        }

        protected override Source<SyndicationFeed> GetSource(FeedId sourceId)
        {
            return NewsSourceBuilder.Build(sourceId);
        }

        protected override SyndicationFeed LoadFeed(Uri sourceUrl)
        {
            var reader = new DateInvariantXmlReader(sourceUrl.ToString());
            var rawFeed = SyndicationFeed.Load(reader);
            reader.Close();
            return rawFeed;
        }
    }
}
