using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.Common.Converter
{
    public interface IItemConverter<T>
    {
        FeedItem Convert(T rawFeed);
    }
}