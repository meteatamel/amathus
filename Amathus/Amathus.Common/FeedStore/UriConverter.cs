// Copyright 2020 Google LLC
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
using Google.Cloud.Firestore;

namespace Amathus.Common.FeedStore
{
    public class UriConverter : IFirestoreConverter<Uri>
    {
        public object ToFirestore(Uri value) => value.ToString();

        public Uri FromFirestore(object value)
        {
            switch (value)
            {
                case string uri: return new Uri(uri);
                case null: throw new ArgumentNullException(nameof(value));
                default: throw new ArgumentException($"Unexpected data: {value.GetType()}");
            }
        }
    }
}
