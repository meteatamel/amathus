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
using Amathus.Web.HostedServices;
using Amathus.Common.FeedStore;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Serialization;
using WebApiContrib.Core.Formatter.Jsonp;
using Amathus.Common.Reader;
using System.Collections.Generic;
using Amathus.Common.Sources;
using Amathus.Common.Converter;

namespace Amathus.Web
{
    public class Startup
    {
        private FeedStoreBackend _backend;
        private List<Source> _sources;

        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            // TODO: jsonp
            services.AddControllers()
                .AddNewtonsoftJson(options =>
                {
                    // To get upper case in Json
                    options.SerializerSettings.ContractResolver = new DefaultContractResolver();
                });

            _backend = Enum.Parse<FeedStoreBackend>(Configuration["Amathus:FeedStore"], ignoreCase: true);

            switch (_backend)
            {
                // InMemory is for local testing. When it's used, it sets up a
                // an local hosted service that reads the feeds and saves into
                // memory.
                case FeedStoreBackend.InMemory:
                    services.AddSingleton<IFeedStore, InMemoryFeedStore>();
                    services.AddHostedService<FeedReaderService>();
                    break;
                // Firestore backedend. It assumes that the backend is already populated.
                case FeedStoreBackend.Firestore:
                    services.AddSingleton<IFeedStore>(provider =>
                        new FirestoreFeedStore(
                            Configuration["Amathus:FirestoreProjectId"]));
                    break;
                default:
                    throw new ArgumentException("Backend cannot be initialized");
            }

            _sources = Configuration.GetSection("Amathus:Sources").Get<List<Source>>();
            services.AddSingleton<IFeedReader>(container =>
            {
                var logger = container.GetRequiredService<ILogger<IFeedReader>>();
                return new FeedReader(_sources, logger);
            });
            services.AddSingleton<IFeedConverter>(container =>
            {
                var logger = container.GetRequiredService<ILogger<IFeedConverter>>();
                return new FeedConverter(_sources, logger);
            });
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<Startup> logger)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            logger.LogInformation("Starting...");
            logger.LogInformation("Backend: " + _backend);
            logger.LogInformation("Sources: {0}", _sources?.Count ?? 0);

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
