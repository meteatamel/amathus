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
using System.ServiceModel.Syndication;
using System.Web;
using Amathus.Common.Feeds;

namespace Amathus.Common.Converter
{
    public class DefaultFeedItemConverter : IFeedItemConverter
    {
        public virtual FeedItem Convert(SyndicationItem item)
        {
            var feedItem =  new FeedItem
            {
                Title = HttpUtility.HtmlDecode(item.Title.Text),
                PublishDate = item.PublishDate.UtcDateTime,
                Summary = HttpUtility.HtmlDecode(item.Summary.Text),
                Url = item.Links[0].Uri
            };

            return feedItem;
        }
    }
}
