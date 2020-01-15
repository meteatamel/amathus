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
using Amathus.Web.Models;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Serialization;
using WebApiContrib.Core.Formatter.Jsonp;

namespace Amathus.Web
{
    public class Startup
    {
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

            services.AddHostedService<FeedReaderService>();

            var backend = Enum.Parse<FeedStoreBackend>(Configuration["FeedStore"], ignoreCase: true);

            switch (backend)
            {
                case FeedStoreBackend.InMemory:
                    services.AddSingleton<IFeedStore, InMemoryFeedStore>();
                    break;
                case FeedStoreBackend.Firestore:
                    services.AddSingleton<IFeedStore>(provider =>
                        new FirestoreFeedStore(
                            Configuration["FirestoreProjectId"]));
                    break;
                default:
                    throw new NotImplementedException(backend.ToString());
            }
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env, ILogger<Startup> logger)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            logger.LogInformation("Amathus is starting");

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
