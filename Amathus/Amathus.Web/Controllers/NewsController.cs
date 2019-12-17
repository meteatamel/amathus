using System;
using Amathus.Web.HostedServices;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;

namespace Amathus.Web.Controllers
{
    [Produces("application/json")]
    [Route("api/v1/[controller]")]
    public class NewsController : BaseController
    {
        public NewsController(IMemoryCache cache) : base(cache)
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
