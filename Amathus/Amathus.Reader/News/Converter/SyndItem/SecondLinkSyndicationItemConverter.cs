using System.ServiceModel.Syndication;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.News.Converter.SyndItem
{
    public class SecondLinkSyncicationItemConverter : HtmlAndImageRemoverSyndicationItemConverter
    {
        public override FeedItem Convert(SyndicationItem item)
        {
            var feedItem = base.Convert(item);
            // Halkin Sesi uses the second link as the article url.
            feedItem.Url = item.Links[1].Uri;
            return feedItem;
        }
    }
}
