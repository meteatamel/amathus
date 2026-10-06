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
using Amathus.Common.Util;

namespace Amathus.Common.Converter
{
    public class HtmlRemoverImageUrlFeedItemConverter : HtmlRemoverFeedItemConverter
    { 
        public override FeedItem Convert(SyndicationItem item)
        {
            var feedItem = base.Convert(item);
            var enclosure = item.Links.FirstOrDefault(l => l.RelationshipType == "enclosure")?.Uri;
            if (enclosure != null)
            {
                feedItem.ImageUrl = TextUtil.EnsureHttps(enclosure);
                feedItem.Url = item.Links.FirstOrDefault(l => l.RelationshipType == "alternate")?.Uri
                    ?? item.Links.FirstOrDefault(l => l.RelationshipType != "enclosure")?.Uri;
            }
            else if (item.Links.Count > 1)
            {
                feedItem.ImageUrl = TextUtil.EnsureHttps(item.Links[0].Uri);
                feedItem.Url = item.Links[1].Uri;
            }
            return feedItem;
        }
    }
}
