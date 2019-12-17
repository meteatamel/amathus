using System.Linq;
using System.ServiceModel.Syndication;
using Amathus.Reader.Common.Converter;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.Common.Sources;
using Amathus.Reader.News.Converter.SyndItem;
using System;

namespace Amathus.Reader.News.Converter.Synd
{
    public class DefaultSyndicationConverter : IConverter<SyndicationFeed>
    {
        protected IItemConverter<SyndicationItem> ItemConverter;

        public DefaultSyndicationConverter(IItemConverter<SyndicationItem> itemConverter = null)
        {
            ItemConverter = itemConverter ?? new DefaultSyndicationItemConverter();
        }

        public virtual Feed Convert(Source<SyndicationFeed> source, SyndicationFeed feed)
        {
            var newsFeed = new Feed
            {
                Id = source.Id,
                ImageUrl = source.LogoUrl,
                LastUpdatedTime = feed.LastUpdatedTime.UtcDateTime,
                Url = feed.Links[0].Uri,
                Items = feed.Items.Select(item => ItemConverter.Convert(item))
                                  .Where(item => DateTime.Compare(item.PublishDate, DateTime.UtcNow) <= 0)
                                  .OrderByDescending(item => item.PublishDate)
            };

            return newsFeed;
        }
    }
}
