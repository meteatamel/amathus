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
using System.Xml.Linq;
using Amathus.Common.Feeds;
using Amathus.Common.Util;

namespace Amathus.Common.Converter
{
    public class DefaultFeedItemConverter : IFeedItemConverter
    {
        public virtual FeedItem Convert(SyndicationItem item)
        {
            var articleLink = item.Links.FirstOrDefault(l => l.RelationshipType == "alternate")?.Uri
                ?? item.Links.FirstOrDefault(l => l.RelationshipType != "enclosure")?.Uri
                ?? item.Links.FirstOrDefault()?.Uri;

            var imageUrl = GetEnclosureOrMediaImage(item);

            var feedItem = new FeedItem
            {
                Title = TextUtil.HtmlDecode(item.Title?.Text ?? string.Empty),
                PublishDate = item.PublishDate.UtcDateTime == default ? DateTime.UtcNow : item.PublishDate.UtcDateTime,
                Summary = TextUtil.HtmlDecode(item.Summary?.Text ?? string.Empty),
                Detail = GetExtension(item, "encoded"),
                Url = articleLink,
                ImageUrl = TextUtil.EnsureHttps(imageUrl)
            };

            return feedItem;
        }

        protected Uri GetEnclosureOrMediaImage(SyndicationItem item)
        {
            var enclosure = item.Links.FirstOrDefault(l => l.RelationshipType == "enclosure")?.Uri;
            if (enclosure != null)
            {
                return TextUtil.EnsureHttps(enclosure);
            }

            foreach (SyndicationElementExtension ext in item.ElementExtensions)
            {
                try
                {
                    var el = ext.GetObject<XElement>();
                    if (el.Name.LocalName == "content" || el.Name.LocalName == "thumbnail")
                    {
                        var urlAttr = el.Attribute("url")?.Value;
                        var uri = TextUtil.GetImg(urlAttr);
                        if (uri != null)
                        {
                            return uri;
                        }
                    }
                }
                catch
                {
                    // Ignore malformed extensions
                }
            }

            return null;
        }

        protected string GetExtension(SyndicationItem item, string localName)
        {
            foreach (SyndicationElementExtension ext in item.ElementExtensions)
            {
                try
                {
                    var el = ext.GetObject<XElement>();
                    if (el.Name.LocalName == localName)
                    {
                        return el.Value.ToString();
                    }
                }
                catch
                {
                    // Ignore malformed extensions
                }
            }
            return null;
        }
    }
}
