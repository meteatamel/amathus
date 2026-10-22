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
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Amathus.Common.Converter;
using Amathus.Common.Feeds;
using Amathus.Common.FeedStore;
using Amathus.Common.Overview;
using Amathus.Common.Reader;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.HostedServices
{
    public class FeedReaderService : IHostedService, IDisposable
    {
        private readonly IFeedReader _reader;
        private readonly IFeedConverter _converter;
        private readonly IFeedStore _store;
        private readonly IOverviewAnalyzer _overviewAnalyzer;
        private readonly ILogger _logger;

        private Timer _timer;

        public FeedReaderService(
            IFeedReader reader,
            IFeedConverter converter,
            IFeedStore store,
            IOverviewAnalyzer overviewAnalyzer,
            ILogger<FeedReaderService> logger)
        {
            _reader = reader;
            _converter = converter;
            _store = store;
            _overviewAnalyzer = overviewAnalyzer;
            _logger = logger;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _timer = new Timer(DoWork, null, TimeSpan.Zero,
                TimeSpan.FromHours(1));

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

        private async void DoWork(object state)
        {
            try
            {
                var stopWatch = new Stopwatch();
                stopWatch.Start();

                _logger?.LogInformation("Fetching news feeds started");
                var rawFeeds = (await _reader.ReadAll()).ToList();
                var convertedFeeds = new List<Feed>();

                foreach (var rawFeed in rawFeeds)
                {
                    var feed = _converter.Convert(rawFeed.Id, rawFeed);
                    if (feed != null)
                    {
                        await _store.InsertAsync(feed);
                        convertedFeeds.Add(feed);
                    }
                }

                stopWatch.Stop();
                _logger?.LogInformation($"Fetching news feeds finished in {stopWatch.Elapsed.Seconds} seconds. Total feeds: {convertedFeeds.Count}");

                if (_overviewAnalyzer != null && convertedFeeds.Count > 0)
                {
                    var overviewWatch = Stopwatch.StartNew();
                    _logger?.LogInformation("Analyzing news feeds for daily overview...");
                    var overview = await _overviewAnalyzer.AnalyzeAsync(convertedFeeds);
                    await _store.SaveOverviewAsync(overview);
                    overviewWatch.Stop();
                    _logger?.LogInformation($"Daily overview generated in {overviewWatch.Elapsed.Seconds} seconds with {overview?.Stories?.Count ?? 0} top stories.");
                }
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error in FeedReaderService background cycle");
            }
        }
    }
}
