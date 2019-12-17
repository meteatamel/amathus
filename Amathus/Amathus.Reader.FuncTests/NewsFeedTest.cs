using System;
using System.Linq;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.News;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.Server.Reader.FunctionalTests
{
    [TestClass]
    public class NewsFeedTest
    {
        //[TestMethod]
        //public void Convert_DemokratBakis_Converts()
        //{
        //    var newsSource = Read(FeedId.DemokratBakis);

        //    AssertCommonElements(newsSource);
        //    Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        //}

        [TestMethod]
        public void Convert_DetayKibris_Converts()
        {
            var newsSource = Read(FeedId.DetayKibris);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_Diyalog_Converts()
        {
            var newsSource = Read(FeedId.Diyalog);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_GundemKibris_Converts()
        {
            var newsSource = Read(FeedId.GundemKibris);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_HaberKibris_Converts()
        {
            var newsSource = Read(FeedId.HaberKibris);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_HalkinSesi_Converts()
        {
            var newsSource = Read(FeedId.HalkinSesi);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_Havadis_Converts()
        {
            var newsSource = Read(FeedId.Havadis);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_KibrisAda_Converts()
        {
            var newsSource = Read(FeedId.KibrisAda);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_KibrisPostasi_Converts()
        {
            var newsSource = Read(FeedId.KibrisPostasi);

            AssertCommonElements(newsSource);
            Assert.AreEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_KibrisSonDakika_Converts()
        {
            var newsSource = Read(FeedId.KibrisSonDakika);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_KibrisTime_Converts()
        {
            var newsSource = Read(FeedId.KibrisTime);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_YeniCag_Converts()
        {
            var newsSource = Read(FeedId.YeniCag);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_YeniDuzen_Converts()
        {
            var newsSource = Read(FeedId.YeniDuzen);

            AssertCommonElements(newsSource);
            Assert.AreNotEqual(new DateTime(), newsSource.LastUpdatedTime);
        }

        private static void AssertCommonElements(Feed source)
        {
            Assert.IsNotNull(source);
            Assert.IsFalse(string.IsNullOrEmpty(source.Title));
            Assert.IsNotNull(source.Url);
            Assert.IsNotNull(source.ImageUrl);
            Assert.IsTrue(source.Items.Any());
        }

        private static Feed Read(FeedId sourceId)
        {
            var reader = new NewsReader();
            return reader.Read(sourceId);
        }

    }
}
