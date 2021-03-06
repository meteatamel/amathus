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
using System.ServiceModel.Syndication;
using System.Xml.Linq;
using Amathus.Common.Feeds;
using Amathus.Common.Util;

namespace Amathus.Common.Converter
{
    public class DefaultFeedItemConverter : IFeedItemConverter
    {
        public virtual FeedItem Convert(SyndicationItem item)
        {
            var feedItem = new FeedItem
            {
                Title = TextUtil.HtmlDecode(item.Title.Text),
                PublishDate = item.PublishDate.UtcDateTime,
                Summary = TextUtil.HtmlDecode(item.Summary.Text),
                Detail = GetExtension(item, "encoded"),
                Url = item.Links[0].Uri
            };

            return feedItem;
        }

        protected string GetExtension(SyndicationItem item, string localName)
        {
            foreach (SyndicationElementExtension ext in item.ElementExtensions)
            {
                if (ext.GetObject<XElement>().Name.LocalName == localName)
                {
                    var value = ext.GetObject<XElement>().Value.ToString();
                    return value;
                }
            }
            return null;
        }
    }
}
