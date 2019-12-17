using System.ServiceModel.Syndication;
using Amathus.Reader.Common.Converter;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.Common.Util;

namespace Amathus.Reader.News.Converter.SyndItem
{
    public class DiyalogSyndicationItemConverter : IItemConverter<SyndicationItem>
    {
        public FeedItem Convert(SyndicationItem item)
        {
            return new FeedItem
            {
                Title = item.Title.Text,
                PublishDate = item.PublishDate.UtcDateTime,
                Summary = TextUtil.RemoveHtml(item.Summary.Text),
                ImageUrl = item.Links[0].Uri,
                Url = item.Links[1].Uri,
            };
        }
    }
}
