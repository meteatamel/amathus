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
using Amathus.Common.Feeds;
using Amathus.Common.Sources;
using Microsoft.Extensions.Logging;

namespace Amathus.Common.Converter
{
    public class FeedConverter : IFeedConverter
    {
        private readonly List<Source> _sources;
        private readonly ILogger _logger;

        public FeedConverter(List<Source> sources, ILogger logger = null)
        {
            _sources = sources;
            _logger = logger;
        }

        public virtual Feed Convert(string sourceId, SyndicationFeed syncFeed)
        {
            _logger?.LogDebug($"Converting feed: {sourceId}");

            var source = _sources.Find(source => source.Id.ToLowerInvariant() == sourceId.ToLowerInvariant());
            var itemConverter = GetFeedItemConverter(source.Id);

            try
            {
                var feed = new Feed
                {
                    Id = source.Id,
                    Title = source.Title,
                    ImageUrl = source.LogoUrl,
                    LastUpdatedTime = syncFeed.LastUpdatedTime.UtcDateTime,
                    Url = syncFeed.Links[0].Uri,
                    Items = syncFeed.Items.Select(item => itemConverter.Convert(item))
                                      //.Where(item => DateTime.Compare(item.PublishDate, DateTime.UtcNow) <= 0)
                                      .OrderByDescending(item => item.PublishDate).ToList<FeedItem>()
                };

                _logger?.LogDebug($"Feed average item length: {feed.AverageItemLength}");

                return feed;
            }
            catch (Exception ex)
            {
                _logger?.LogError($"Converting failed for feed: {source.Id}", ex);
                return null;
            }
        }

        private IFeedItemConverter GetFeedItemConverter(string sourceId)
        {
            switch (sourceId)
            {
                case Source.Hakikat:
                case Source.Havadis:
                case Source.KibrisHaberci:
                case Source.KibrisSonDakika:
                case Source.OzgurGazete:
                case Source.YeniCag:
                    return new HtmlRemoverFeedItemConverter();
                case Source.HaberalKibrisli:
                case Source.HalkinSesi:
                case Source.KibrisGazetesi:
                case Source.KibrisHaber:
                    return new HtmlRemoverImageUrlFeedItemConverter();
                case Source.DetayKibris:
                case Source.Haberator:
                case Source.KibrisAda:
                case Source.YeniDuzen:
                    return new HtmlImageSubtextRemoverFeedItemConverter();
                case Source.GundemKibris:
                    return new ImageFeedItemConverter();
                case Source.Diyalog:
                case Source.KibrisTime:
                    return new ImageUrlFeedItemConverter();
                default:
                    return new DefaultFeedItemConverter();
            }
        }
    }
}
