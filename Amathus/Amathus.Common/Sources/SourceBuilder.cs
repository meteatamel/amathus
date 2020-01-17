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
using System.ServiceModel.Syndication;
using Amathus.Common.Feeds;
using Amathus.Common.Converter;

namespace Amathus.Common.Sources
{
    public static class SourceBuilder
    {
        public static Source Build(FeedId sourceId)
        {
            var source = new Source
            {
                Converter = new DefaultSyndicationConverter(),
                Id = sourceId
            };

            switch (sourceId)
            {
                case FeedId.DetayKibris:
                    source.LogoUrl = SourceConstants.DetayKibrisLogo;
                    source.Url = SourceConstants.DetayKibris;
                    source.Converter = new DefaultSyndicationConverter(new HtmlAndImageRemoverSyndicationItemConverter());
                    break;
                case FeedId.Diyalog:
                    source.LogoUrl = SourceConstants.DiyalogLogo;
                    source.Url = SourceConstants.Diyalog;
                    source.Converter = new DefaultSyndicationConverter(new DiyalogSyndicationItemConverter());
                    break;
                case FeedId.GundemKibris:
                    source.LogoUrl = SourceConstants.GundemKibrisLogo;
                    source.Url = SourceConstants.GundemKibris;
                    source.Converter = new DefaultSyndicationConverter(new HtmlAndImageRemoverSyndicationItemConverter());
                    break;
                case FeedId.HaberKibris:
                    source.LogoUrl = SourceConstants.HaberKibrisLogo;
                    source.Url = SourceConstants.HaberKibris;
                    break;
                case FeedId.HalkinSesi:
                    source.LogoUrl = SourceConstants.HalkinSesiLogo;
                    source.Url = SourceConstants.HalkinSesi;
                    source.Converter = new DefaultSyndicationConverter(new SecondLinkSyncicationItemConverter());
                    break;
                case FeedId.Havadis:
                    source.LogoUrl = SourceConstants.HavadisLogo;
                    source.Url = SourceConstants.Havadis;
                    source.Converter = new DefaultSyndicationConverter(new HtmlAndImageRemoverSyndicationItemConverter());
                    break;
                case FeedId.KibrisAda:
                    source.LogoUrl = SourceConstants.KibrisAdaLogo;
                    source.Url = SourceConstants.KibrisAda;
                    source.Converter = new DefaultSyndicationConverter(new HtmlAndImageRemoverSyndicationItemConverter());
                    break;
                case FeedId.KibrisPostasi:
                    source.LogoUrl = SourceConstants.KibrisPostasiLogo;
                    source.Url = SourceConstants.KibrisPostasi;
                    break;
                case FeedId.KibrisSonDakika:
                    source.LogoUrl = SourceConstants.KibrisSonDakikaLogo;
                    source.Url = SourceConstants.KibrisSonDakika;
                    source.Converter = new DefaultSyndicationConverter(new HtmlAndImageRemoverSyndicationItemConverter());
                    break;
                case FeedId.KibrisTime:
                    source.LogoUrl = SourceConstants.KibrisTimeLogo;
                    source.Url = SourceConstants.KibrisTime;
                    source.Converter = new DefaultSyndicationConverter(new SecondLinkSyncicationItemConverter());
                    break;
                case FeedId.YeniCag:
                    source.LogoUrl = SourceConstants.YeniCagLogo;
                    source.Url = SourceConstants.YeniCag;
                    source.Converter = new DefaultSyndicationConverter(new HtmlAndImageRemoverSyndicationItemConverter());
                    break;
                case FeedId.YeniDuzen:
                    source.LogoUrl = SourceConstants.YeniDuzenLogo;
                    source.Url = SourceConstants.YeniDuzen;
                    source.Converter = new DefaultSyndicationConverter(new HtmlAndImageRemoverSyndicationItemConverter());
                    break;
            }
            return source;
        }
    }
}
