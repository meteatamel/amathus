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
using System.ServiceModel.Syndication;
using Amathus.Common.Feeds;
using Amathus.Common.Util;

namespace Amathus.Common.Converter
{
    public class HtmlImageFooterRemoverFeedItemConverter : HtmlRemoverFeedItemConverter
    { 
        public override FeedItem Convert(SyndicationItem item)
        {
            var feedItem = base.Convert(item);
            feedItem.ImageUrl = TextUtil.ExtractImgSrc(feedItem.Detail);
            if (feedItem.ImageUrl != null)
            {
                feedItem.Detail = TextUtil.RemoveImgSrc(feedItem.Detail);
            }
            feedItem.Summary = TextUtil.RemoveFooter(feedItem.Summary);
            feedItem.Detail = TextUtil.RemoveFooter(feedItem.Detail);
            return feedItem;
        }
    }
}
