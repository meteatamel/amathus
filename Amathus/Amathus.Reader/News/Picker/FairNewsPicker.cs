using System.Collections.Generic;
using System.Linq;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.News.Picker
{
    public class FairNewsPicker : BaseNewsPicker
    {
        public FairNewsPicker(List<Feed> newsFeeds) : base(newsFeeds)
        {
        }

        public override List<Feed> Pick(int limit)
        {
            var numberOfNewsItemsPerSource = limit / NumberOfNewsSources;
            var remainingNewsItems = limit % NumberOfNewsSources;
            
            foreach (var newsFeed in NewsFeeds)
            {
                if (remainingNewsItems > 0)
                {
                    newsFeed.Items = newsFeed.Items.Take(numberOfNewsItemsPerSource + 1);
                    remainingNewsItems--;
                }
                else
                {
                    newsFeed.Items = newsFeed.Items.Take(numberOfNewsItemsPerSource);
                }
            }
            return NewsFeeds;
        }


    }
}
