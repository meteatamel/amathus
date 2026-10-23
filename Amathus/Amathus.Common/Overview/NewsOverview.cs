// Copyright 2026 Google LLC
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
using Amathus.Common.Feeds;
using Amathus.Common.FeedStore;
using Google.Cloud.Firestore;

namespace Amathus.Common.Overview
{
    [FirestoreData]
    public class NewsOverview
    {
        [FirestoreProperty]
        public string Id { get; set; } = "latest";

        [FirestoreProperty]
        public DateTime GeneratedAt { get; set; }

        [FirestoreProperty]
        public int TotalFeedsAnalyzed { get; set; }

        [FirestoreProperty]
        public int TotalArticlesAnalyzed { get; set; }

        [FirestoreProperty]
        public string SummaryEn { get; set; }

        [FirestoreProperty]
        public string SummaryTr { get; set; }

        [FirestoreProperty]
        public string SummaryEl { get; set; }

        [FirestoreProperty]
        public string Edition { get; set; }

        [FirestoreProperty]
        public List<OverviewStory> Stories { get; set; } = new List<OverviewStory>();

        [FirestoreProperty]
        public List<PodcastDialogueTurn> PodcastTurns { get; set; } = new List<PodcastDialogueTurn>();

        public NewsOverview Copy()
        {
            var copy = (NewsOverview)MemberwiseClone();
            copy.Stories = Stories?.Select(s => s.Copy()).ToList() ?? new List<OverviewStory>();
            copy.PodcastTurns = PodcastTurns?.Select(t => t.Copy()).ToList() ?? new List<PodcastDialogueTurn>();
            return copy;
        }
    }

    [FirestoreData]
    public class PodcastDialogueTurn
    {
        [FirestoreProperty]
        public int Index { get; set; }

        [FirestoreProperty]
        public string Speaker { get; set; }

        [FirestoreProperty]
        public string StoryId { get; set; }

        [FirestoreProperty]
        public string SpeakerNameEl { get; set; }

        [FirestoreProperty]
        public string SpeakerNameTr { get; set; }

        [FirestoreProperty]
        public string SpeakerNameEn { get; set; }

        [FirestoreProperty]
        public string TextEl { get; set; }

        [FirestoreProperty]
        public string TextTr { get; set; }

        [FirestoreProperty]
        public string TextEn { get; set; }

        public PodcastDialogueTurn Copy()
        {
            return (PodcastDialogueTurn)MemberwiseClone();
        }
    }

    [FirestoreData]
    public class OverviewStory
    {
        [FirestoreProperty]
        public string Id { get; set; }

        [FirestoreProperty]
        public string TitleEn { get; set; }

        [FirestoreProperty]
        public string TitleTr { get; set; }

        [FirestoreProperty]
        public string TitleEl { get; set; }

        [FirestoreProperty]
        public string NarrativeEn { get; set; }

        [FirestoreProperty]
        public string NarrativeTr { get; set; }

        [FirestoreProperty]
        public string NarrativeEl { get; set; }

        [FirestoreProperty(ConverterType = typeof(UriConverter))]
        public Uri ImageUrl { get; set; }

        [FirestoreProperty]
        public DateTime PublishDate { get; set; }

        [FirestoreProperty]
        public string Topic { get; set; }

        [FirestoreProperty]
        public List<OverviewStorySource> Sources { get; set; } = new List<OverviewStorySource>();

        public OverviewStory Copy()
        {
            var copy = (OverviewStory)MemberwiseClone();
            copy.Sources = Sources?.Select(s => s.Copy()).ToList() ?? new List<OverviewStorySource>();
            return copy;
        }
    }

    [FirestoreData]
    public class OverviewStorySource
    {
        [FirestoreProperty]
        public string FeedId { get; set; }

        [FirestoreProperty]
        public string FeedTitle { get; set; }

        [FirestoreProperty]
        public string FeedLanguage { get; set; }

        [FirestoreProperty(ConverterType = typeof(UriConverter))]
        public Uri FeedImageUrl { get; set; }

        [FirestoreProperty(ConverterType = typeof(UriConverter))]
        public Uri FeedUrl { get; set; }

        [FirestoreProperty]
        public FeedItem Article { get; set; }

        public OverviewStorySource Copy()
        {
            var copy = (OverviewStorySource)MemberwiseClone();
            if (Article != null)
            {
                copy.Article = new FeedItem
                {
                    Title = Article.Title,
                    PublishDate = Article.PublishDate,
                    Summary = Article.Summary,
                    Detail = Article.Detail,
                    ImageUrl = Article.ImageUrl,
                    Url = Article.Url,
                    Author = Article.Author,
                    IsColumnist = Article.IsColumnist,
                    Topic = Article.Topic
                };
            }
            return copy;
        }
    }
}
