using System;
using System.Linq;
using System.ServiceModel.Syndication;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.Common.Sources;
using Amathus.Reader.News.Sources;
using Amathus.Reader.News.Xml;
using log4net;

namespace Amathus.Reader.News
{
    public class NewsReader : BaseFeedReader<SyndicationFeed>
    {
        private static readonly ILog Logger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        protected override FeedId[] GetFeedIds()
        {
            return Enum.GetValues(typeof(FeedId)).Cast<FeedId>().ToArray();
        }

        protected override ILog GetLogger()
        {
            return Logger;
        }

        protected override Source<SyndicationFeed> GetSource(FeedId sourceId)
        {
            return NewsSourceBuilder.Build(sourceId);
        }

        protected override SyndicationFeed LoadFeed(Uri sourceUrl)
        {
            var reader = new DateInvariantXmlReader(sourceUrl.ToString());
            var rawFeed = SyndicationFeed.Load(reader);
            reader.Close();
            return rawFeed;
        }
    }
}
