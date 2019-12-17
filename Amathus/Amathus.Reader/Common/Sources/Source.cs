using System;
using Amathus.Reader.Common.Converter;
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.Common.Sources
{
    public class Source<T>
    {
        public IConverter<T> Converter { get; set; }

        public FeedId Id { get; set; }

        public Uri LogoUrl { get; set; }

        public Uri Url { get; set; }
    }
}
