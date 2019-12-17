using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amathus.Reader.Common.Sources;
using log4net;

namespace Amathus.Reader.Common.Feeds
{
    public abstract class BaseFeedReader<T> : IFeedReader
    {
        public async Task<IEnumerable<Feed>> Read()
        {
            var tasks = GetFeedIds().Select(feedId => Task.Run(() => Read(feedId)));
            var results = await Task.WhenAll(tasks);
            return results.Where(feed => feed != null);
        }

        public Feed Read(FeedId sourceId)
        {
            try
            {
                var source = GetSource(sourceId);
                var rawFeed = LoadFeed(source.Url);
                var feed = source.Converter.Convert(source, rawFeed);
                GetLogger().DebugFormat($"News source:{feed.Id} => {feed.AverageItemLength}");
                return feed;

            }
            catch (Exception ex)
            {
                GetLogger().Error("Error during feed read: " + sourceId, ex);
                return null;
            }
        }

        protected abstract FeedId[] GetFeedIds();

        protected abstract ILog GetLogger();

        protected abstract Source<T> GetSource(FeedId sourceId);

        protected abstract T LoadFeed(Uri sourceUrl);
    }
}
