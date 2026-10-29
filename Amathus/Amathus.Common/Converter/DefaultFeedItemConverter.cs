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
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Amathus.Common.Feeds;
using Amathus.Common.Util;

namespace Amathus.Common.Converter
{
    public class DefaultFeedItemConverter : IFeedItemConverter
    {
        private static readonly HashSet<string> ColumnistCategoryNames = new(StringComparer.OrdinalIgnoreCase)
        {
            "Yazarlar",
            "Köşe Yazıları",
            "Opinions",
            "Opinion",
            "Comment"
        };

        public virtual FeedItem Convert(SyndicationItem item)
        {
            var articleLink = item.Links.FirstOrDefault(l => l.RelationshipType == "alternate")?.Uri
                ?? item.Links.FirstOrDefault(l => l.RelationshipType != "enclosure")?.Uri
                ?? item.Links.FirstOrDefault()?.Uri;

            var imageUrl = GetEnclosureOrMediaImage(item);
            var title = TextUtil.HtmlDecode(item.Title?.Text ?? string.Empty);
            var summary = TextUtil.HtmlDecode(item.Summary?.Text ?? string.Empty);
            var detail = GetExtension(item, "encoded");

            ExtractColumnistMetadata(item, title, out var isColumnist, out var author, out var overrideImageUrl, out var regularCategories);

            if (overrideImageUrl != null &&
                (imageUrl == null || imageUrl.AbsoluteUri.IndexOf("no_headline", StringComparison.OrdinalIgnoreCase) >= 0))
            {
                imageUrl = overrideImageUrl;
            }

            if (string.IsNullOrWhiteSpace(summary) && !string.IsNullOrWhiteSpace(detail))
            {
                summary = BuildSummaryExcerpt(detail);
            }

            var feedItem = new FeedItem
            {
                Title = title,
                PublishDate = item.PublishDate.UtcDateTime == default ? DateTime.UtcNow : item.PublishDate.UtcDateTime,
                Summary = summary,
                Detail = detail,
                Url = articleLink,
                ImageUrl = TextUtil.EnsureHttps(imageUrl),
                Author = string.IsNullOrWhiteSpace(author) ? null : author.Trim(),
                IsColumnist = isColumnist,
                Topic = TextUtil.ClassifyTopic(title, summary, detail, articleLink?.AbsoluteUri, regularCategories)
            };

            return feedItem;
        }

        private void ExtractColumnistMetadata(
            SyndicationItem item,
            string decodedTitle,
            out bool isColumnist,
            out string author,
            out Uri overrideImageUrl,
            out List<string> regularCategories)
        {
            isColumnist = false;
            author = null;
            overrideImageUrl = null;

            regularCategories = new List<string>();
            if (item.Categories != null)
            {
                foreach (var cat in item.Categories)
                {
                    var name = cat?.Name?.Trim();
                    if (string.IsNullOrEmpty(name))
                    {
                        continue;
                    }
                    if (string.Equals(name, "amathus:columnist", StringComparison.OrdinalIgnoreCase))
                    {
                        isColumnist = true;
                    }
                    else if (name.StartsWith("amathus:author:", StringComparison.OrdinalIgnoreCase))
                    {
                        author = name.Substring("amathus:author:".Length).Trim();
                    }
                    else if (name.StartsWith("amathus:image:", StringComparison.OrdinalIgnoreCase))
                    {
                        var imgStr = name.Substring("amathus:image:".Length).Trim();
                        overrideImageUrl = TextUtil.GetImg(imgStr);
                    }
                    else
                    {
                        regularCategories.Add(TextUtil.HtmlDecode(name).Trim());
                    }
                }
            }

            var person = item.Authors.FirstOrDefault();
            var authorPersonName = !string.IsNullOrWhiteSpace(person?.Name) ? person.Name : person?.Email;
            var dcCreator = TextUtil.HtmlDecode(GetExtension(item, "creator") ?? authorPersonName ?? string.Empty).Trim();

            if (!isColumnist)
            {
                if (regularCategories.Any(c => ColumnistCategoryNames.Contains(c)))
                {
                    isColumnist = true;
                }
                else if (!string.IsNullOrWhiteSpace(dcCreator) &&
                         dcCreator.IndexOf("Konuk Yazar", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    isColumnist = true;
                }
                else if (!string.IsNullOrWhiteSpace(decodedTitle) && regularCategories.Count > 0)
                {
                    // Yeniçağ tags columnists with their name in <category> and appends " – <Author>" to the title
                    var matchedAuthorCat = regularCategories.FirstOrDefault(cat =>
                        !string.Equals(cat, "YKP", StringComparison.OrdinalIgnoreCase) &&
                        (decodedTitle.EndsWith("– " + cat, StringComparison.OrdinalIgnoreCase) ||
                         decodedTitle.EndsWith("- " + cat, StringComparison.OrdinalIgnoreCase)));
                    if (!string.IsNullOrWhiteSpace(matchedAuthorCat))
                    {
                        isColumnist = true;
                        author = matchedAuthorCat;
                    }
                }
            }

            if (isColumnist && string.IsNullOrWhiteSpace(author) && !string.IsNullOrWhiteSpace(dcCreator))
            {
                if (!string.Equals(dcCreator, "YKP", StringComparison.OrdinalIgnoreCase) &&
                    !string.Equals(dcCreator, "fm", StringComparison.OrdinalIgnoreCase))
                {
                    author = dcCreator;
                }
            }
        }

        protected static string BuildSummaryExcerpt(string html)
        {
            var plain = Regex.Replace(html ?? string.Empty, "<[^>]+>", " ");
            plain = TextUtil.HtmlDecode(plain);
            plain = Regex.Replace(plain, @"\s+", " ").Trim();
            if (plain.Length > 260)
            {
                return plain.Substring(0, 260).TrimEnd() + "…";
            }
            return plain;
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
