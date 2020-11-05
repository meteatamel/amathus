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
    public class FeedItemTest
    {
        private static List<Source> _sources;

        [ClassInitialize]
        public static void Init(TestContext context) => _sources = TestHelper.GetSources();

        [TestMethod]
        public void Convert_CyprusToday_Converts()
        {
            var feedItem = Read(Source.CyprusToday);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes summary can be null or empty.
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_DetayKibris_Converts()
        {
            var feedItem = Read(Source.DetayKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Diyalog_Converts()
        {
            var feedItem = Read(Source.Diyalog);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_GazeddaKibris_Converts()
        {
            var feedItem = Read(Source.GazeddaKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Giynik_Converts()
        {
            var feedItem = Read(Source.Giynik);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_GundemKibris_Converts()
        {
            var feedItem = Read(Source.GundemKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Gunes_Converts()
        {
            var feedItem = Read(Source.Gunes);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Haberator_Converts()
        {
            var feedItem = Read(Source.Haberator);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_HaberKibris_Converts()
        {
            var feedItem = Read(Source.HaberKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_HaberalKibrisli_Converts()
        {
            var feedItem = Read(Source.HaberalKibrisli);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes it can be null or empty
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Hakikat_Converts()
        {
            var feedItem = Read(Source.Hakikat);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_HalkinSesi_Converts()
        {
            var feedItem = Read(Source.HalkinSesi);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes it can be null or empty
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Havadis_Converts()
        {
            var feedItem = Read(Source.Havadis);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisAda_Converts()
        {
            var feedItem = Read(Source.KibrisAda);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisGazetesi_Converts()
        {
            var feedItem = Read(Source.KibrisGazetesi);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes it can be null or empty
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisGercek_Converts()
        {
            var feedItem = Read(Source.KibrisGercek);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisHaber_Converts()
        {
            var feedItem = Read(Source.KibrisHaber);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes it can be null or empty
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisHaberci_Converts()
        {
            var feedItem = Read(Source.KibrisHaberci);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisManset_Converts()
        {
            var feedItem = Read(Source.KibrisManset);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes it can be null or empty
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisSonDakika_Converts()
        {
            var feedItem = Read(Source.KibrisSonDakika);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_KibrisTime_Converts()
        {
            var feedItem = Read(Source.KibrisTime);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes it can be null or empty
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_LgcNews_Converts()
        {
            var feedItem = Read(Source.LgcNews);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_LondraGazete_Converts()
        {
            var feedItem = Read(Source.LondraGazete);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_OzgurGazete_Converts()
        {
            var feedItem = Read(Source.OzgurGazete);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_SesKibris_Converts()
        {
            var feedItem = Read(Source.SesKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Tvine_Converts()
        {
            var feedItem = Read(Source.TVine);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
            // Not all have images
            //Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Vatan_Converts()
        {
            var feedItem = Read(Source.Vatan);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Volkan_Converts()
        {
            var feedItem = Read(Source.Volkan);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
        }

        [TestMethod]
        public void Convert_YeniCag_Converts()
        {
            var feedItem = Read(Source.YeniCag);

            AssertTitleUrlPublishDate(feedItem);
        }

        [TestMethod]
        public void Convert_YeniDuzen_Converts()
        {
            var feedItem = Read(Source.YeniDuzen);

            AssertTitleUrlPublishDate(feedItem);
            // Sometimes it can be null or empty
            //Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        private static void AssertTitleUrlPublishDate(FeedItem feedItem)
        {
            Assert.IsNotNull(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Title));
            Assert.IsNotNull(feedItem.PublishDate);
            Assert.AreNotEqual(new DateTime(), feedItem.PublishDate);
            Assert.IsNotNull(feedItem.Url);
        }

        private static FeedItem Read(string sourceId)
        {
            var source = _sources.Find(source => source.Id == sourceId);

            var reader = new FeedReader(_sources);
            var rawFeed = reader.Read(source);

            var converter = new FeedConverter(_sources);
            var feed = converter.Convert(source.Id, rawFeed);

            return feed.Items.First();
        }
    }
}
