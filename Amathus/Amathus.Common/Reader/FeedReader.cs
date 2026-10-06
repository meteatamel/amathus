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
using System.Threading.Tasks;
using Amathus.Common.Sources;
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
                return feed;
            }
            catch (Exception ex)
            {
                _logger?.LogError($"Reading failed for feed: {source.Id} - {ex.Message}", ex);
                return null;
            }
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
