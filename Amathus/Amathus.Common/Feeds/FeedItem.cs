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
using Amathus.Common.FeedStore;
using Google.Cloud.Firestore;
using Newtonsoft.Json;

namespace Amathus.Common.Feeds
{
    [FirestoreData]
    public class FeedItem
    {
        [FirestoreProperty]
        public string Title { get; set; }

        [FirestoreProperty]
        public DateTime PublishDate { get; set; }

        [FirestoreProperty]
        public string Summary { get; set; }

        [FirestoreProperty]
        public string Detail { get; set; }

        [FirestoreProperty(ConverterType = typeof(UriConverter))]
        public Uri ImageUrl { get; set; }

        [FirestoreProperty(ConverterType = typeof(UriConverter))]
        public Uri Url { get; set; }

        [JsonIgnore]
        public int Length
        {
            get
            {
                return GetLength(Title) + GetLength(Summary) + GetLength(Detail);
            }
        }

        private static int GetLength(string key)
        {
            return key?.Length ?? 0;
        }
    }
}
