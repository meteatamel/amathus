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
using System;
using System.Collections.Generic;
using Amathus.Common.Sources;
using Microsoft.Extensions.Configuration;

namespace Amathus.FuncTests
{
    public class TestHelper
    {

        public static List<Source> GetSources()
        {
            var configuration = new ConfigurationBuilder()
                    //.SetBasePath(path)
                    .AddJsonFile("amathussources.json", optional: false)
                    .Build();

            return configuration.GetSection("Amathus:Sources").Get<List<Source>>();
        }
    }
}
