using System.ServiceModel.Syndication;
using Amathus.Reader.Common.Converter;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.Common.Util;

namespace Amathus.Reader.News.Converter.SyndItem
{
    public class HtmlAndImageRemoverSyndicationItemConverter : IItemConverter<SyndicationItem>
    {
        public virtual FeedItem Convert(SyndicationItem item)
        {
            return new FeedItem
            {
                Title = item.Title.Text,
                PublishDate = item.PublishDate.UtcDateTime,
                Summary = TextUtil.RemoveHtmlTabAndNewLine(item.Summary.Text),
                ImageUrl = UrlUtil.GetUrl(TextUtil.ExtractImgSrc(item.Summary.Text)),
                Url = item.Links[0].Uri,
            };
        }
    }
}
