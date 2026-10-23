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
using System.Net;
using System.Net.Http;
using System.Net.Sockets;
using System.ServiceModel.Syndication;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml.Linq;
using Amathus.Common.Sources;
using Amathus.Common.Util;
using Microsoft.Extensions.Logging;

namespace Amathus.Common.Reader
{
    public class FeedReader : IFeedReader
    {
        private static readonly HttpClient HttpClient = CreateHttpClient();
        private readonly List<Source> _sources;
        private readonly ILogger _logger;

        private static HttpClient CreateHttpClient()
        {
            var handler = new SocketsHttpHandler
            {
                AllowAutoRedirect = true,
                AutomaticDecompression = DecompressionMethods.All,
                ConnectCallback = async (context, cancellationToken) =>
                {
                    var entry = await Dns.GetHostEntryAsync(context.DnsEndPoint.Host, AddressFamily.InterNetwork, cancellationToken);
                    var socket = new Socket(SocketType.Stream, ProtocolType.Tcp) { NoDelay = true };
                    try
                    {
                        await socket.ConnectAsync(entry.AddressList, context.DnsEndPoint.Port, cancellationToken);
                        return new NetworkStream(socket, ownsSocket: true);
                    }
                    catch
                    {
                        socket.Dispose();
                        throw;
                    }
                }
            };
            handler.SslOptions.RemoteCertificateValidationCallback = (_, _, _, _) => true;

            var client = new HttpClient(handler)
            {
                Timeout = TimeSpan.FromSeconds(20),
                DefaultRequestVersion = HttpVersion.Version11,
                DefaultVersionPolicy = HttpVersionPolicy.RequestVersionOrLower
            };
            client.DefaultRequestHeaders.UserAgent.ParseAdd(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36");
            client.DefaultRequestHeaders.Accept.ParseAdd(
                "application/rss+xml, application/xml, text/xml, */*");
            return client;
        }

        public FeedReader(List<Source> sources, ILogger logger = null)
        {
            _sources = sources;
            _logger = logger;
        }

        public async Task<IEnumerable<SyndicationFeed>> ReadAll()
        {
            var tasks = _sources.Select(source => Task.Run(() => Read(source)));
            var results = await Task.WhenAll(tasks);
            return results.Where(feed => feed != null);
        }

        public SyndicationFeed Read(Source source)
        {
            try
            {
                _logger?.LogDebug($"Reading feed: {source.Id}");
                var feed = LoadFeed(source.Url);
                feed.Id = source.Id;

                if (source.ColumnistUrl != null)
                {
                    MergeColumnistFeed(source, feed);
                }

                return feed;
            }
            catch (Exception ex)
            {
                _logger?.LogError($"Reading failed for feed: {source.Id} - {ex.Message}", ex);
                return null;
            }
        }

        private void MergeColumnistFeed(Source source, SyndicationFeed mainFeed)
        {
            try
            {
                var colFeed = LoadFeed(source.ColumnistUrl);
                if (colFeed?.Items == null)
                {
                    return;
                }

                var authorBySlug = FetchAuthorDirectory(source.ColumnistAuthorsUrl);
                var colItems = new List<SyndicationItem>();
                var colLinks = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                foreach (var item in colFeed.Items)
                {
                    item.Categories.Add(new SyndicationCategory("amathus:columnist"));

                    var itemLink = item.Links.FirstOrDefault(l => l.RelationshipType == "alternate")?.Uri
                        ?? item.Links.FirstOrDefault(l => l.RelationshipType != "enclosure")?.Uri
                        ?? item.Links.FirstOrDefault()?.Uri;

                    var authorName = ExtractCreator(item);
                    string authorImage = null;

                    if (itemLink != null && authorBySlug.Count > 0)
                    {
                        var slug = itemLink.AbsolutePath.Trim('/');
                        if (authorBySlug.TryGetValue(slug, out var info))
                        {
                            if (string.IsNullOrWhiteSpace(authorName))
                            {
                                authorName = info.Author;
                            }
                            authorImage = info.ImageUrl;
                        }
                    }

                    if (string.IsNullOrWhiteSpace(authorName) && source.Id == Source.CyprusMail)
                    {
                        var titleText = item.Title?.Text ?? string.Empty;
                        if (titleText.StartsWith("Our View:", StringComparison.OrdinalIgnoreCase) ||
                            item.Categories.Any(c => string.Equals(c.Name, "Our View", StringComparison.OrdinalIgnoreCase)))
                        {
                            authorName = "Our View";
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(authorName) &&
                        !string.Equals(authorName.Trim(), "fm", StringComparison.OrdinalIgnoreCase) &&
                        !string.Equals(authorName.Trim(), "YKP", StringComparison.OrdinalIgnoreCase))
                    {
                        item.Categories.Add(new SyndicationCategory($"amathus:author:{TextUtil.HtmlDecode(authorName.Trim())}"));
                    }

                    if (!string.IsNullOrWhiteSpace(authorImage) && Uri.TryCreate(authorImage, UriKind.Absolute, out var authorImgUri))
                    {
                        item.Categories.Add(new SyndicationCategory($"amathus:image:{authorImgUri.AbsoluteUri}"));
                        var existingEnclosure = item.Links.FirstOrDefault(l => l.RelationshipType == "enclosure");
                        if (existingEnclosure == null ||
                            existingEnclosure.Uri == null ||
                            existingEnclosure.Uri.AbsoluteUri.IndexOf("no_headline", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            if (existingEnclosure != null)
                            {
                                item.Links.Remove(existingEnclosure);
                            }
                            item.Links.Add(SyndicationLink.CreateMediaEnclosureLink(authorImgUri, "image/jpeg", 0));
                        }
                    }

                    if (itemLink != null)
                    {
                        colLinks.Add(itemLink.AbsoluteUri);
                    }
                    colItems.Add(item);
                }

                var merged = new List<SyndicationItem>(colItems);
                if (mainFeed.Items != null)
                {
                    foreach (var mainItem in mainFeed.Items)
                    {
                        var link = mainItem.Links.FirstOrDefault(l => l.RelationshipType == "alternate")?.Uri
                            ?? mainItem.Links.FirstOrDefault(l => l.RelationshipType != "enclosure")?.Uri
                            ?? mainItem.Links.FirstOrDefault()?.Uri;
                        if (link != null && colLinks.Contains(link.AbsoluteUri))
                        {
                            continue;
                        }
                        merged.Add(mainItem);
                    }
                }

                mainFeed.Items = merged;
            }
            catch (Exception ex)
            {
                _logger?.LogWarning($"Reading columnist feed failed for {source.Id}: {ex.Message}");
            }
        }

        private static string ExtractCreator(SyndicationItem item)
        {
            foreach (SyndicationElementExtension ext in item.ElementExtensions)
            {
                try
                {
                    var el = ext.GetObject<XElement>();
                    if (el.Name.LocalName == "creator" && !string.IsNullOrWhiteSpace(el.Value))
                    {
                        return el.Value.Trim();
                    }
                }
                catch
                {
                    // Ignore malformed extension
                }
            }

            var person = item.Authors.FirstOrDefault();
            var name = !string.IsNullOrWhiteSpace(person?.Name) ? person.Name : person?.Email;
            return name?.Trim();
        }

        private Dictionary<string, (string Author, string ImageUrl)> FetchAuthorDirectory(Uri authorsUrl)
        {
            var map = new Dictionary<string, (string Author, string ImageUrl)>(StringComparer.OrdinalIgnoreCase);
            if (authorsUrl == null)
            {
                return map;
            }

            try
            {
                using var response = HttpClient.GetAsync(authorsUrl).GetAwaiter().GetResult();
                if (!response.IsSuccessStatusCode)
                {
                    return map;
                }
                var html = response.Content.ReadAsStringAsync().GetAwaiter().GetResult();
                var matches = Regex.Matches(
                    html,
                    @"card-header[^>]*>.*?<a\s+href=""([^""]+)""[^>]*>.*?card-body[^>]*>.*?<a\s+href=""[^""]+""\s+title=""([^""]+)""[^>]*>\s*<img\s+src=""([^""]+)""",
                    RegexOptions.Singleline | RegexOptions.IgnoreCase);

                foreach (Match m in matches)
                {
                    var href = m.Groups[1].Value.Trim();
                    var author = TextUtil.HtmlDecode(m.Groups[2].Value.Trim());
                    var img = m.Groups[3].Value.Trim();
                    if (Uri.TryCreate(authorsUrl, href, out var articleUri))
                    {
                        var slug = articleUri.AbsolutePath.Trim('/');
                        if (!string.IsNullOrEmpty(slug) && !string.IsNullOrEmpty(author))
                        {
                            map[slug] = (author, img);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger?.LogWarning($"Failed to fetch author directory from {authorsUrl}: {ex.Message}");
            }

            return map;
        }

        private SyndicationFeed LoadFeed(Uri sourceUrl)
        {
            using var response = HttpClient.GetAsync(sourceUrl).GetAwaiter().GetResult();
            response.EnsureSuccessStatusCode();
            using var stream = response.Content.ReadAsStreamAsync().GetAwaiter().GetResult();
            using var reader = new DateTolerantXmlTextReader(stream);
            var rawFeed = SyndicationFeed.Load(reader);
            return rawFeed;
        }
    }
}
