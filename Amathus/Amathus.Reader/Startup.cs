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
using System.Collections.Generic;
using Amathus.Common.Reader;
using Amathus.Common.FeedStore;
using Amathus.Common.Sources;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Amathus.Reader
{
    public class Startup
    {
        private List<Source> _sources;

        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            _sources = Configuration.GetSection("Amathus:Sources").Get<List<Source>>();
            services.AddSingleton<IFeedReader>(container =>
            {
                var logger = container.GetRequiredService<ILogger<IFeedReader>>();
                return new FeedReader(_sources, logger);
            });

            services.AddSingleton<ISyndFeedStore>(container =>
            {
                var bucketId = Configuration["Amathus:BucketId"];
                var logger = container.GetRequiredService<ILogger<ISyndFeedStore>>();
                return new CloudStorageSyndFeedStore(bucketId, logger);
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<Startup> logger)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            logger.LogInformation("Starting...");
            logger.LogInformation("Sources: " + _sources?.Count);

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
