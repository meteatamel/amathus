﻿// Copyright 2019 Google LLC
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
using Amathus.Common.Feeds;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Amathus.FunctionalTests
{
    [TestClass]
    public class FeedReaderTest
    {

        [TestMethod]
        public void Read_Basic_ReturnsNonEmptyFeed()
        {
            var reader = new FeedReader();

            var source = reader.Read(FeedId.Diyalog);

            Assert.IsNotNull(source);
        }
    }
}