using System.Net;
using System.ServiceModel.Syndication;
using Amathus.Reader.Common.Converter;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.News.Converter.SyndItem
{
    public class DefaultSyndicationItemConverter : IItemConverter<SyndicationItem>
    {
        public FeedItem Convert(SyndicationItem item)
        {
            var newsItem =  new FeedItem
            {
                Title = WebUtility.HtmlDecode(item.Title.Text),
                PublishDate = item.PublishDate.UtcDateTime,
                Summary = WebUtility.HtmlDecode(item.Summary.Text),
                Url = item.Links[0].Uri
            };
            return newsItem;
        }
    }
}
