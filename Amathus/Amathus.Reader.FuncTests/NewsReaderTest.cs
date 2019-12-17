using Amathus.Reader.Common.Feeds;
using Amathus.Reader.News;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.Server.Reader.FunctionalTests
{
    [TestClass]
    public class NewsReaderTest
    {

        [TestMethod]
        public void Read_Basic_ReturnsNonEmptyFeed()
        {
            var reader = new NewsReader();

            var source = reader.Read(FeedId.Diyalog);

            Assert.IsNotNull(source);
        }
    }
}
