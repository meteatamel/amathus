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
        public void Convert_AlphaNews_Converts()
        {
            var feed = Read(Source.AlphaNews);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Bagimsiz_Converts()
        {
            var feed = Read(Source.Bagimsiz);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_BugunKibris_Converts()
        {
            var feed = Read(Source.BugunKibris);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_CyprusMail_Converts()
        {
            var feed = Read(Source.CyprusMail);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_CyprusToday_Converts()
        {
            var feed = Read(Source.CyprusToday);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_DetayKibris_Converts()
        {
            var feed = Read(Source.DetayKibris);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Dialogos_Converts()
        {
            var feed = Read(Source.Dialogos);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Diyalog_Converts()
        {
            var feed = Read(Source.Diyalog);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_FinancialMirror_Converts()
        {
            var feed = Read(Source.FinancialMirror);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_GazeddaKibris_Converts()
        {
            var feed = Read(Source.GazeddaKibris);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Giynik_Converts()
        {
            var feed = Read(Source.Giynik);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_GundemKibris_Converts()
        {
            var feed = Read(Source.GundemKibris);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_GunesKibris_Converts()
        {
            var feed = Read(Source.GunesKibris);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_HaberalKibrisli_Converts()
        {
            var feed = Read(Source.HaberalKibrisli);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_HalkinSesi_Converts()
        {
            var feed = Read(Source.HalkinSesi);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Havadis_Converts()
        {
            var feed = Read(Source.Havadis);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_KibrisGencTv_Converts()
        {
            var feed = Read(Source.KibrisGencTv);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_KibrisGercek_Converts()
        {
            var feed = Read(Source.KibrisGercek);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_KibrisGazetesi_Converts()
        {
            var feed = Read(Source.KibrisGazetesi);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_KibrisManset_Converts()
        {
            var feed = Read(Source.KibrisManset);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_KibrisObjektif_Converts()
        {
            var feed = Read(Source.KibrisObjektif);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_KibrisTime_Converts()
        {
            var feed = Read(Source.KibrisTime);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Lemesos_Converts()
        {
            var feed = Read(Source.Lemesos);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_LondraGazete_Converts()
        {
            var feed = Read(Source.LondraGazete);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_PafosPress_Converts()
        {
            var feed = Read(Source.PafosPress);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Philenews_Converts()
        {
            var feed = Read(Source.Philenews);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Politis_Converts()
        {
            var feed = Read(Source.Politis);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_PolitisEn_Converts()
        {
            var feed = Read(Source.PolitisEn);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Sigmalive_Converts()
        {
            var feed = Read(Source.Sigmalive);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_ToThemaOnline_Converts()
        {
            var feed = Read(Source.ToThemaOnline);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_TVine_Converts()
        {
            var feed = Read(Source.TVine);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_Vatan_Converts()
        {
            var feed = Read(Source.Vatan);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_YeniCag_Converts()
        {
            var feed = Read(Source.YeniCag);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        [TestMethod]
        public void Convert_YeniDuzen_Converts()
        {
            var feed = Read(Source.YeniDuzen);
            AssertTitleLastUpdatedTimeUrlImageUrl(feed);
        }

        private static void AssertTitleLastUpdatedTimeUrlImageUrl(Feed feed)
        {
            Assert.IsNotNull(feed);
            Assert.IsTrue(!string.IsNullOrEmpty(feed.Title));
            Assert.IsTrue(!string.IsNullOrEmpty(feed.Language));
            Assert.IsNotNull(feed.LastUpdatedTime);
            Assert.AreNotEqual(new DateTime(), feed.LastUpdatedTime);
            Assert.IsNotNull(feed.Url);
            Assert.IsNotNull(feed.ImageUrl);
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
