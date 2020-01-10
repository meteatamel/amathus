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
using Amathus.Reader.Feeds;

namespace Amathus.Reader.Converter
{
    public class SecondLinkSyncicationItemConverter : HtmlAndImageRemoverSyndicationItemConverter
    {
        public override FeedItem Convert(SyndicationItem item)
        {
            var feedItem = base.Convert(item);
            // Halkin Sesi uses the second link as the article url.
            feedItem.Url = item.Links[1].Uri;
            return feedItem;
        }
    }
}
