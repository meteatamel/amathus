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
using System.Collections.Generic;
using System.Linq;
using Amathus.Common.Converter;
using Amathus.Common.Feeds;
using Amathus.Common.Reader;
using Amathus.Common.Sources;
using Amathus.FuncTests;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.FunctionalTests
{
    [TestClass]
    public class FeedTest
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
            var feed = Read("DetayKibris");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_Diyalog_Converts()
        {
            var feed = Read("Diyalog");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_GundemKibris_Converts()
        {
            var feed = Read("GundemKibris");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_HaberKibris_Converts()
        {
            var feed = Read("HaberKibris");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_HalkinSesi_Converts()
        {
            var feed = Read("HalkinSesi");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_Havadis_Converts()
        {
            var feed = Read("Havadis");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_KibrisAda_Converts()
        {
            var feed = Read("KibrisAda");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        // No RSS feed anymore
        [TestMethod, Ignore]
        public void Convert_KibrisPostasi_Converts()
        {
            var feed = Read("KibrisPostasi");

            AssertCommonElements(feed);
            Assert.AreEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_KibrisSonDakika_Converts()
        {
            var feed = Read("KibrisSonDakika");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_KibrisTime_Converts()
        {
            var feed = Read("KibrisTime");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_YeniCag_Converts()
        {
            var feed = Read("YeniCag");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        [TestMethod]
        public void Convert_YeniDuzen_Converts()
        {
            var feed = Read("YeniDuzen");

            AssertCommonElements(feed);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
        }

        private static void AssertCommonElements(Feed source)
        {
            Assert.IsNotNull(source);
            Assert.IsFalse(string.IsNullOrEmpty(source.Title));
            Assert.IsNotNull(source.Url);
            Assert.IsNotNull(source.ImageUrl);
            Assert.IsTrue(source.Items.Any());
        }

        private static Feed Read(string sourceId)
        {

            var source = _sources.Find(source => source.Id == sourceId);

            var reader = new FeedReader(_sources);
            var rawFeed = reader.Read(source);

            var converter = new FeedConverter(_sources);
            var feed = converter.Convert(source.Id, rawFeed);

            return feed;
        }

    }
}
