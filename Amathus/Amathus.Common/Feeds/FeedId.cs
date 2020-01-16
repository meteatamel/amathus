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
using Google.Cloud.Firestore;

namespace Amathus.Common.Feeds
{
    [FirestoreData(ConverterType = typeof(FirestoreEnumNameConverter<FeedId>))]
    public enum FeedId
    {
        DemokratBakis,
        DetayKibris, 
        Diyalog, 
        GundemKibris, 
        HaberKibris, 
        HalkinSesi, 
        Havadis,
        KibrisAda,
        KibrisPostasi,
        KibrisSonDakika,
        KibrisTime,
        YeniCag,
        YeniDuzen,
    }

    public static class FeedIdExtensions
    {
        public static string ToFriendlyString(this FeedId me)
        {
            switch (me)
            {
                case FeedId.DemokratBakis:
                    return "Demokrat Bakış";
                case FeedId.DetayKibris:
                    return "Detay Kıbrıs";
                case FeedId.Diyalog:
                    return "Diyalog";
                case FeedId.GundemKibris:
                    return "Gündem Kıbrıs";
                case FeedId.HaberKibris:
                    return "Haber Kıbrıs";
                case FeedId.HalkinSesi:
                    return "Halkın Sesi";
                case FeedId.Havadis:
                    return "Havadis";
                case FeedId.KibrisAda:
                    return "Kıbrıs Ada";
                case FeedId.KibrisPostasi:
                    return "Kıbrıs Postası";
                case FeedId.KibrisSonDakika:
                    return "Kıbrıs Son Dakika";
                case FeedId.KibrisTime:
                    return "Kıbrıs Time";
                case FeedId.YeniCag:
                    return "Yeniçağ";
                case FeedId.YeniDuzen:
                    return "Yenidüzen";
            }
            return "";
        }
    }
}
