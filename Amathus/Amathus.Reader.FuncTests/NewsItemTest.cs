// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
using System;
using System.Linq;
using Amathus.Reader.Common.Feeds;
using Amathus.Reader.News;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.Server.Reader.FunctionalTests
{
    [TestClass]
    public class NewsItemTest
    {
        //[TestMethod]
        //public void Convert_DemokratBakis_Converts()
        //{
        //    var newsItem = Read(FeedId.DemokratBakis);

        //    AssertCommonElements(newsItem);
        //    Assert.IsTrue(!string.IsNullOrEmpty(newsItem.Summary));
        //    Assert.IsNull(newsItem.ImageUrl);
        //}

        [TestMethod]
        public void Convert_DetayKibris_Converts()
        {
            var newsItem = Read(FeedId.DetayKibris);

            AssertCommonElements(newsItem);
            Assert.IsTrue(!string.IsNullOrEmpty(newsItem.Summary));
            Assert.IsNotNull(newsItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Diyalog_Converts()
        {
            var newsItem = Read(FeedId.Diyalog);

            AssertCommonElements(newsItem);
            Assert.IsTrue(!string.IsNullOrEmpty(newsItem.Summary));
            Assert.IsNotNull(newsItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_GundemKibris_Converts()
        {
            var newsItem = Read(FeedId.GundemKibris);

            AssertCommonElements(newsItem);
            Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
            Assert.IsNotNull(newsItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_HaberKibris_Converts()
        {
            var newsItem = Read(FeedId.HaberKibris);

            AssertCommonElements(newsItem);
            Assert.IsTrue(string.IsNullOrEmpty(newsItem.Summary));
            Assert.IsNull(newsItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_HalkinSesi_Converts()
        {
            var newsItem = Read(FeedId.HalkinSesi);

            AssertCommonElements(newsItem);
            Assert.IsNotNull(newsItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Havadis_Converts()
        {
            var newsItem = Read(FeedId.Havadis);

            AssertCommonElements(newsItem);
            //Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
            //Assert.IsNotNull(newsItem.ImageUrl);
        }


        [TestMethod]
        public void Convert_KibrisAda_Converts()
        {
            var newsItem = Read(FeedId.KibrisAda);

            AssertCommonElements(newsItem);
            Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
            Assert.IsNotNull(newsItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisPostasi_Converts()
        {
            var newsItem = Read(FeedId.KibrisPostasi);

            AssertCommonElements(newsItem);
            Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
        }

        [TestMethod]
        public void Convert_KibrisSonDakika_Converts()
        {
            var newsItem = Read(FeedId.KibrisSonDakika);

            AssertCommonElements(newsItem);
            Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
        }


        [TestMethod]
        public void Convert_KibrisTime_Converts()
        {
            var newsItem = Read(FeedId.KibrisTime);

            AssertCommonElements(newsItem);
            Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
        }

        [TestMethod]
        public void Convert_YeniCag_Converts()
        {
            var newsItem = Read(FeedId.YeniCag);

            AssertCommonElements(newsItem);
            Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
        }

        [TestMethod]
        public void Convert_YeniDuzen_Converts()
        {
            var newsItem = Read(FeedId.YeniDuzen);

            AssertCommonElements(newsItem);
            Assert.IsTrue(!string.IsNullOrEmpty(newsItem.Summary));
            Assert.IsNotNull(newsItem.ImageUrl);
        }

        private static void AssertCommonElements(FeedItem feedItem)
        {
            Assert.IsNotNull(feedItem);
            Assert.IsFalse(string.IsNullOrEmpty(feedItem.Title));
            Assert.AreNotEqual(new DateTime(), feedItem.PublishDate);
            Assert.IsNotNull(feedItem.Url);
        }

        private static FeedItem Read(FeedId sourceId)
        {
            var reader = new NewsReader();
            var newsSource = reader.Read(sourceId);
            return newsSource.Items.First();
        }
    }
}
