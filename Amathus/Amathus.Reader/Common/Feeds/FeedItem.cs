using System;
using Newtonsoft.Json;

namespace Amathus.Reader.Common.Feeds
{
    public class FeedItem
    {
        public string Title { get; set; }

        public DateTime PublishDate { get; set; }

        public string Summary { get; set; }

        public string Detail { get; set; }

        public Uri ImageUrl { get; set; }

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
            //return key == null ? 0 : key.Length;
        }
    }
}
