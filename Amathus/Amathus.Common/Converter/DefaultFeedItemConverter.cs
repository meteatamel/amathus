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
using System.Net;
using System.ServiceModel.Syndication;
using Amathus.Common.Feeds;

namespace Amathus.Common.Converter
{
    public class DefaultFeedItemConverter : IFeedItemConverter
    {
        public FeedItem Convert(SyndicationItem item)
        {
            var newsItem =  new FeedItem
            {
                Title = WebUtility.HtmlDecode(item.Title.Text),
                PublishDate = item.PublishDate.UtcDateTime,
                Summary = WebUtility.HtmlDecode(item.Summary.Text),
                Url = item.Links[0].Uri
            };

            // If the publish date is in the future, set it to UtcNow
            if (DateTime.Compare(newsItem.PublishDate, DateTime.UtcNow) > 0)
            {
                newsItem.PublishDate = DateTime.UtcNow;
            }

            return newsItem;
        }
    }
}
