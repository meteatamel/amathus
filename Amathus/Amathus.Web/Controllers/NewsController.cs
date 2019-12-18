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
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.Controllers
{
    [Produces("application/json")]
    [Route("api/v1/[controller]")]
    public class NewsController : BaseController
    {
        public NewsController(IMemoryCache cache, ILogger<NewsController> logger) : base(cache, logger)
        {
        }

        [HttpGet]
        public IActionResult GetAllNews([FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            return GetAll(limit, from);
        }

        [HttpGet("{id}")]
        public IActionResult GetNewsById(string id, [FromQuery] int? limit = null, [FromQuery] DateTime? from = null)
        {
            return GetById(id, limit, from);
        }

        protected override string GetKeyPrefix()
        {
            return NewsReaderService.KeyPrefix;
        }
    }
}
