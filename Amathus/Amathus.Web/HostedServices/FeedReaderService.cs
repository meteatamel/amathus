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
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Amathus.Common.Reader;
using Amathus.Common.FeedStore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Amathus.Common.Converter;

namespace Amathus.Web.HostedServices
{
    public class FeedReaderService : IHostedService, IDisposable
    {
        private readonly IFeedReader _reader;
        private readonly IFeedConverter _converter;
        private readonly IFeedStore _store;
        private readonly ILogger _logger;

        private Timer _timer;

        public FeedReaderService(IFeedReader reader, IFeedConverter converter, IFeedStore store, ILogger<FeedReaderService> logger)
        {
            _reader = reader;
            _converter = converter;
            _store = store;
            _logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _timer = new Timer(DoWork, null, TimeSpan.Zero,
                TimeSpan.FromMinutes(10));

            return Task.CompletedTask;
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            _timer?.Change(Timeout.Infinite, 0);

            return Task.CompletedTask;
        }

        public void Dispose()
        {
            _timer?.Dispose();
        }

        private void DoWork(object state)
        {
            var stopWatch = new Stopwatch();
            stopWatch.Start();

            _logger?.LogInformation("Fetching news feeds started");
            var rawFeeds = _reader.ReadAll().Result.ToList();
            rawFeeds.ForEach(rawFeed => {
                
                var feed = _converter.Convert(rawFeed.Id, rawFeed);
                _store.InsertAsync(feed);
            });
            stopWatch.Stop();
            _logger?.LogInformation($"Fetching news feeds finished in {stopWatch.Elapsed.Seconds} seconds. Total feeds: {rawFeeds.Count}");
        }
    }
}