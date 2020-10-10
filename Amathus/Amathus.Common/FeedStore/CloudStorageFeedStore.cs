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
using System.IO;
using System.ServiceModel.Syndication;
using System.Threading.Tasks;
using System.Xml;
using Google.Cloud.Storage.V1;
using Microsoft.Extensions.Logging;

namespace Amathus.Common.FeedStore
{
    public class CloudStorageSyndFeedStore : ISyndFeedStore
    {
        private readonly string _bucketId;
        private readonly ILogger _logger;

        public CloudStorageSyndFeedStore(string bucketId, ILogger logger = null)
        {
            _bucketId = bucketId;
            _logger = logger;
        }

        public async Task InsertAsync(SyndicationFeed feed)
        {
            var client = StorageClient.Create();

            //await CheckBucketExists();

            var objectName = feed.Id.ToLowerInvariant();
            _logger?.LogInformation($"Uploading {objectName} to bucket {_bucketId}");

            var stream = GetStream(feed);
            await client.UploadObjectAsync(_bucketId, objectName, "application/xml", stream);

            _logger?.LogInformation($"Uploaded {objectName}");
        }

        public async Task<SyndicationFeed> ReadAsync(string feedId)
        {
            if (string.IsNullOrEmpty(feedId))
            {
                throw new ArgumentNullException();
            }

            //await CheckBucketExists();

            var client = StorageClient.Create();

            var objectName = feedId.ToLowerInvariant();
            _logger?.LogInformation($"Reading {objectName} from bucket {_bucketId}");

            var stream = new MemoryStream();
            try
            {
                await client.DownloadObjectAsync(_bucketId, objectName, stream);
                _logger?.LogInformation($"Read {objectName}");
            }
            catch (Exception e)
            {
                _logger.LogError($"Error reading {objectName}: " + e.Message);
                throw e;
            }

            _logger?.LogInformation($"Converting to SyndicationFeed");

            try
            {
                stream.Position = 0; // Reset to read
                var reader = new XmlTextReader(stream);

                var feed = SyndicationFeed.Load(reader);
                reader.Close();
                _logger?.LogInformation($"Converted to SyndicationFeed");
                return feed;
            }
            catch (Exception e)
            {
                _logger?.LogError($"Error converting {e.Message}");
                throw e;
            }
        }


        private async Task CheckBucketExists()
        {
            if (string.IsNullOrEmpty(_bucketId))
            {
                throw new ArgumentNullException();
            }

            try
            {
                var client = StorageClient.Create();

                await client.GetBucketAsync(_bucketId);
            }
            catch (Exception)
            {
                throw new ArgumentException("Bucket does not exist yet");
            }
        }

        private static MemoryStream GetStream(SyndicationFeed feed)
        {
            var stream = new MemoryStream();
            var writer = XmlWriter.Create(stream);
            var atomFormatter = feed.GetAtom10Formatter();
            atomFormatter.WriteTo(writer);
            writer.Close();
            return stream;
        }
    }
}
