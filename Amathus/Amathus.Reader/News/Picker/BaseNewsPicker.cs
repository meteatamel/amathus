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
using Amathus.Reader.Common.Feeds;

namespace Amathus.Reader.News.Picker
{
    public abstract class BaseNewsPicker : INewsPicker
    {
        protected static readonly int NumberOfNewsSources = Enum.GetValues(typeof(FeedId)).Length;

        protected List<Feed> NewsFeeds;

        protected BaseNewsPicker(List<Feed> newsFeeds)
        {
            NewsFeeds = newsFeeds;
        }

        public abstract List<Feed> Pick(int limit);
    }
}
