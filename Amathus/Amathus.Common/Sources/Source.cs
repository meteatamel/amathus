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

namespace Amathus.Common.Sources
{
    public class Source
    {
        public const string CyprusToday = "cyprustoday";
        public const string DetayKibris = "detaykibris";
        public const string Diyalog = "diyalog";
        public const string GundemKibris = "gundemkibris";
        public const string Giynik = "giynik";
        public const string Haberator = "haberator";
        public const string HaberKibris = "haberkibris";
        public const string HaberalKibrisli = "haberalkibrisli";
        public const string Hakikat = "hakikat";
        public const string HalkinSesi = "halkinsesi";
        public const string Havadis = "havadis";
        public const string KibrisAda = "kibrisada";
        public const string KibrisGazetesi = "kibrisgazetesi";
        public const string KibrisHaber = "kibrishaber";
        public const string KibrisHaberci = "kibrishaberci";
        public const string KibrisManset = "kibrismanset";
        public const string KibrisSonDakika = "kibrissondakika";
        public const string KibrisTime = "kibristime";
        public const string LgcNews = "lgcnews";
        public const string LondraGazete = "londragazete";
        public const string OzgurGazete = "ozgurgazete";
        public const string SesKibris = "seskibris";
        public const string TVine = "tvine";
        public const string Vatan = "vatan";
        public const string Volkan = "volkan";
        public const string YeniCag = "yenicag";
        public const string YeniDuzen = "yeniduzen";

        public string Id { get; set; }

        public string Title { get; set; }

        public Uri LogoUrl { get; set; }

        public Uri Url { get; set; }
    }
}
