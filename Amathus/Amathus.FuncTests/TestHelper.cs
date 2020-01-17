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
