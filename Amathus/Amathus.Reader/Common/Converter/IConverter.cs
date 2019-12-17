using Amathus.Reader.Common.Feeds;
using Amathus.Reader.Common.Sources;

namespace Amathus.Reader.Common.Converter
{
    public interface IConverter<T>
    {
        Feed Convert(Source<T> source, T rawFeed);
    }
}