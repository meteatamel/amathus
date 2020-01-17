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
using System.Collections.Generic;
using System.Linq;
using Amathus.Common.Feeds;
using Amathus.Common.Sources;
using Amathus.FuncTests;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.FunctionalTests
{
    [TestClass]
    public class FeedItemTest
    {
        private static List<Source> _sources;

        [ClassInitialize]
        public static void Init(TestContext context)
        {
            _sources = TestHelper.GetSources();
        }

        [TestMethod]
        public void Convert_DetayKibris_Converts()
        {
            var feedItem = Read("DetayKibris");

            AssertCommonElements(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Diyalog_Converts()
        {
            var feedItem = Read("Diyalog");

            AssertCommonElements(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_GundemKibris_Converts()
        {
            var feedItem = Read("GundemKibris");

            AssertCommonElements(feedItem);
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_HaberKibris_Converts()
        {
            var feedItem = Read("HaberKibris");

            AssertCommonElements(feedItem);
            Assert.IsNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_HalkinSesi_Converts()
        {
            var feedItem = Read("HalkinSesi");

            AssertCommonElements(feedItem);
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Havadis_Converts()
        {
            var feedItem = Read("Havadis");

            AssertCommonElements(feedItem);
            //Assert.IsFalse(string.IsNullOrEmpty(newsItem.Summary));
            //Assert.IsNotNull(newsItem.ImageUrl);
        }


        [TestMethod]
        public void Convert_KibrisAda_Converts()
        {
            var feedItem = Read("KibrisAda");

            AssertCommonElements(feedItem);
            Assert.IsFalse(string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        // No RSS Feed anymore
        [TestMethod, Ignore]
        public void Convert_KibrisPostasi_Converts()
        {
            var feedItem = Read("KibrisPostasi");

            AssertCommonElements(feedItem);
            Assert.IsFalse(string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_KibrisSonDakika_Converts()
        {
            var feedItem = Read("KibrisSonDakika");

            AssertCommonElements(feedItem);
            Assert.IsFalse(string.IsNullOrEmpty(feedItem.Summary));
        }


        [TestMethod]
        public void Convert_KibrisTime_Converts()
        {
            var feedItem = Read("KibrisTime");

            AssertCommonElements(feedItem);
            Assert.IsFalse(string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_YeniCag_Converts()
        {
            var feedItem = Read("YeniCag");

            AssertCommonElements(feedItem);
            Assert.IsFalse(string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_YeniDuzen_Converts()
        {
            var feedItem = Read("YeniDuzen");

            AssertCommonElements(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        private static void AssertCommonElements(FeedItem feedItem)
        {
            Assert.IsNotNull(feedItem);
            Assert.IsFalse(string.IsNullOrEmpty(feedItem.Title));
            //Assert.AreNotEqual(new DateTime(), feedItem.PublishDate);
            Assert.IsNotNull(feedItem.Url);
        }

        private static FeedItem Read(string sourceId)
        {
            var reader = new FeedReader(_sources);
            var source = _sources.Find(source => source.Id == sourceId);
            var feed = reader.Read(source);
            return feed.Items.First();
        }
    }
}
