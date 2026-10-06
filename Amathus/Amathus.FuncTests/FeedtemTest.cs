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
        public void Convert_AlphaNews_Converts()
        {
            var feedItem = Read(Source.AlphaNews);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Bagimsiz_Converts()
        {
            var feedItem = Read(Source.Bagimsiz);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_BugunKibris_Converts()
        {
            var feedItem = Read(Source.BugunKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_CyprusMail_Converts()
        {
            var feedItem = Read(Source.CyprusMail);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_CyprusToday_Converts()
        {
            var feedItem = Read(Source.CyprusToday);

            AssertTitleUrlPublishDate(feedItem);
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
        public void Convert_Dialogos_Converts()
        {
            var feedItem = Read(Source.Dialogos);

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
        public void Convert_FinancialMirror_Converts()
        {
            var feedItem = Read(Source.FinancialMirror);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_GazeddaKibris_Converts()
        {
            var feedItem = Read(Source.GazeddaKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
        }

        [TestMethod]
        public void Convert_Giynik_Converts()
        {
            var feedItem = Read(Source.Giynik);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
        }

        [TestMethod]
        public void Convert_GundemKibris_Converts()
        {
            var feedItem = Read(Source.GundemKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_GunesKibris_Converts()
        {
            var feedItem = Read(Source.GunesKibris);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_HaberalKibrisli_Converts()
        {
            var feedItem = Read(Source.HaberalKibrisli);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_HalkinSesi_Converts()
        {
            var feedItem = Read(Source.HalkinSesi);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Havadis_Converts()
        {
            var feedItem = Read(Source.Havadis);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
        }

        [TestMethod]
        public void Convert_KibrisGazetesi_Converts()
        {
            var feedItem = Read(Source.KibrisGazetesi);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_KibrisGencTv_Converts()
        {
            var feedItem = Read(Source.KibrisGencTv);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisGercek_Converts()
        {
            var feedItem = Read(Source.KibrisGercek);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisManset_Converts()
        {
            var feedItem = Read(Source.KibrisManset);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_KibrisObjektif_Converts()
        {
            var feedItem = Read(Source.KibrisObjektif);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_KibrisTime_Converts()
        {
            var feedItem = Read(Source.KibrisTime);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Lemesos_Converts()
        {
            var feedItem = Read(Source.Lemesos);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_LondraGazete_Converts()
        {
            var feedItem = Read(Source.LondraGazete);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Detail));
        }

        [TestMethod]
        public void Convert_PafosPress_Converts()
        {
            var feedItem = Read(Source.PafosPress);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
        }

        [TestMethod]
        public void Convert_Philenews_Converts()
        {
            var feedItem = Read(Source.Philenews);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Politis_Converts()
        {
            var feedItem = Read(Source.Politis);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_PolitisEn_Converts()
        {
            var feedItem = Read(Source.PolitisEn);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_Sigmalive_Converts()
        {
            var feedItem = Read(Source.Sigmalive);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_ToThemaOnline_Converts()
        {
            var feedItem = Read(Source.ToThemaOnline);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
        }

        [TestMethod]
        public void Convert_TVine_Converts()
        {
            var feedItem = Read(Source.TVine);

            AssertTitleUrlPublishDate(feedItem);
            Assert.IsTrue(!string.IsNullOrEmpty(feedItem.Summary));
            Assert.IsNotNull(feedItem.ImageUrl);
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
