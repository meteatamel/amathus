using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using log4net;
using Microsoft.Extensions.Hosting;
using Amathus.Reader.News;
using System.Diagnostics;
using Microsoft.Extensions.Caching.Memory;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Web.HostedServices
{
    public class NewsReaderService : IHostedService, IDisposable
    {
        public const string KeyPrefix = "news";

        private static readonly ILog Logger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        private Timer _timer;
        private NewsReader _newsReader;

        private IMemoryCache _cache;

        public NewsReaderService(IMemoryCache cache)
        {
            _cache = cache;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _timer = new Timer(DoWork, null, TimeSpan.Zero,
                TimeSpan.FromMinutes(10));
            _newsReader = new NewsReader();

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

            Logger.Info("Fetching news feeds started");
            var feeds = _newsReader.Read().Result.ToList();
            feeds.ForEach(feed => InsertIntoCache(feed.Id.ToString(), feed));
            stopWatch.Stop();
            Logger.Info("Fetching news feeds finished in '" + stopWatch.Elapsed.Seconds + "' seconds. Total feeds: " + feeds.Count);
        }

        private void InsertIntoCache(string key, Feed feed)
        {
            if (key == null || feed == null) return;

            _cache.Set(KeyPrefix + "_" + key.ToLowerInvariant(), feed);
        }
    }
}