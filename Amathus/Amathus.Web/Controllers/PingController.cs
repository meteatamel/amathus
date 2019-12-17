using log4net;
using Microsoft.AspNetCore.Mvc;

namespace Amathus.Web.Controllers
{
    [Route("")]
    public class PingController : ControllerBase
    {
        private readonly ILog _logger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        [HttpGet]
        public IActionResult Ping()
        {
            _logger.Info("Ping");

            return Ok("pong");
        }
    }
}