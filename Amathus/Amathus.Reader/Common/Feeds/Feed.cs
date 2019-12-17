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