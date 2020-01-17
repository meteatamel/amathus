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
using System.Linq;
using System.ServiceModel.Syndication;
using Amathus.Common.Feeds;
using Amathus.Common.Sources;

namespace Amathus.Common.Converter
{
    public class DefaultSyndicationConverter : IConverter
    {
        protected IItemConverter<SyndicationItem> ItemConverter;

        public DefaultSyndicationConverter(IItemConverter<SyndicationItem> itemConverter = null)
        {
            ItemConverter = itemConverter ?? new DefaultSyndicationItemConverter();
        }

        public virtual Feed Convert(Source source, SyndicationFeed syncFeed)
        {
            var feed = new Feed
            {
                Id = source.Id,
                Title = source.Title,
                ImageUrl = source.LogoUrl,
                LastUpdatedTime = syncFeed.LastUpdatedTime.UtcDateTime,
                Url = syncFeed.Links[0].Uri,
                Items = syncFeed.Items.Select(item => ItemConverter.Convert(item))
                                  //.Where(item => DateTime.Compare(item.PublishDate, DateTime.UtcNow) <= 0)
                                  .OrderByDescending(item => item.PublishDate).ToList<FeedItem>()
            };

            return feed;
        }
    }
}
