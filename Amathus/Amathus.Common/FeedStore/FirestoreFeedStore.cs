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
using System.Collections.Generic;
using System.Threading.Tasks;
using Amathus.Common.Feeds;
using Google.Cloud.Firestore;

namespace Amathus.Common.FeedStore
{
    public class FirestoreFeedStore : IFeedStore
    {
        private readonly FirestoreDb _firestore;
        private readonly CollectionReference _feeds;

        public FirestoreFeedStore(string projectId)
        {
            _firestore = FirestoreDb.Create(projectId);
            _feeds = _firestore.Collection("feeds");
        }

        public async Task InsertAsync(Feed feed)
        {
            if (feed == null)
            {
                return;
            }

            var docRef = _feeds.Document(feed.Id.ToString());
            await docRef.SetAsync(feed, SetOptions.Overwrite);
        }

        public async Task<Feed> ReadAsync(string id)
        {
            var snapshot = await _feeds.Document(id).GetSnapshotAsync();
            if (!snapshot.Exists)
            {
                return null;
            }

            var feed = snapshot.ConvertTo<Feed>();
            return feed;
        }

        public async Task<List<Feed>> ReadAllAsync()
        {
            var feeds = new List<Feed>();

            var collection = await _feeds.GetSnapshotAsync();
            foreach (DocumentSnapshot document in collection.Documents)
            {
                var feed = document.ConvertTo<Feed>();
                feeds.Add(feed);
            }

            return feeds;
        }
    }
}
