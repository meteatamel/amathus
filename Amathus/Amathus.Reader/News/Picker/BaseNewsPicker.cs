using System;
using System.Collections.Generic;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.News.Picker
{
    public abstract class BaseNewsPicker : INewsPicker
    {
        protected static readonly int NumberOfNewsSources = Enum.GetValues(typeof(FeedId)).Length;

        protected List<Feed> NewsFeeds;

        protected BaseNewsPicker(List<Feed> newsFeeds)
        {
            NewsFeeds = newsFeeds;
        }

        public abstract List<Feed> Pick(int limit);
    }
}
