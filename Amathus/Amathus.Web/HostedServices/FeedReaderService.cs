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
using Amathus.Reader.Feeds;
using Amathus.Web.Models;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.HostedServices
{
    public class FeedReaderService : IHostedService, IDisposable
    {
        private readonly ILogger _logger;
        private readonly IFeedStore _feedStore;

        private Timer _timer;
        private FeedReader _feedReader;

        public FeedReaderService(IFeedStore feedStore, ILogger<FeedReaderService> logger)
        {
            _feedStore = feedStore;
            _logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _timer = new Timer(DoWork, null, TimeSpan.Zero,
                TimeSpan.FromMinutes(10));
            _feedReader = new FeedReader(_logger);

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
            var feeds = _feedReader.Read().Result.ToList();
            feeds.ForEach(feed => _feedStore.InsertAsync(feed));
            stopWatch.Stop();
            _logger?.LogInformation($"Fetching news feeds finished in {stopWatch.Elapsed.Seconds} seconds. Total feeds: {feeds.Count}");
        }
    }
}