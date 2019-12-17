using System.Collections.Generic;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.News.Picker
{
    public interface INewsPicker
    {
        List<Feed> Pick(int limit);
    }
}
