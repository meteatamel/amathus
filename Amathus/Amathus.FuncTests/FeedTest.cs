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
using Amathus.Reader.Feeds;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.FunctionalTests
{
    [TestClass]
    public class FeedTest
    {
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

        // No RSS feed anymore
        [TestMethod, Ignore]
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
            var reader = new FeedReader();
            return reader.Read(sourceId);
        }

    }
}
