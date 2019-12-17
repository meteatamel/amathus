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
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace Amathus.Reader.Common.Feeds
{
    public class Feed
    {
        [JsonConverter(typeof(StringEnumConverter))]
        public FeedId Id { get; set; }

        public string Title
        {
            get { return Id.ToFriendlyString(); }
        }

        public DateTime LastUpdatedTime { get; set; }

        public Uri ImageUrl { get; set; }

        public Uri Url { get; set; }

        public IEnumerable<FeedItem> Items { get; set; }

        [JsonIgnore]
        public double AverageItemLength
        {
            get
            {
                return Items.Average(item => item.Length);
            }
        }

        public Feed Copy()
        {
            var copy = (Feed)MemberwiseClone();
            copy.Items = new List<FeedItem>(Items);
            return copy;
        }
    }
}