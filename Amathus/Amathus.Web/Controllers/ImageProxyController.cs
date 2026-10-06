// Copyright 2026 Google LLC
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
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.Controllers
{
    [Route("api/v1/[controller]")]
    public class ImageProxyController : ControllerBase
    {
        private static readonly HttpClient HttpClient = CreateHttpClient();
        private readonly ILogger<ImageProxyController> _logger;

        private static HttpClient CreateHttpClient()
        {
            var handler = new SocketsHttpHandler
            {
                AllowAutoRedirect = true,
                AutomaticDecompression = DecompressionMethods.All
            };
            handler.SslOptions.RemoteCertificateValidationCallback = (_, _, _, _) => true;

            var client = new HttpClient(handler)
            {
                Timeout = TimeSpan.FromSeconds(15)
            };
            client.DefaultRequestHeaders.UserAgent.ParseAdd(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36");
            client.DefaultRequestHeaders.Accept.ParseAdd("image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8");
            return client;
        }

        public ImageProxyController(ILogger<ImageProxyController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        [ResponseCache(Duration = 86400, Location = ResponseCacheLocation.Any)]
        public async Task<IActionResult> Get([FromQuery] string url)
        {
            if (string.IsNullOrWhiteSpace(url) || !Uri.TryCreate(url, UriKind.Absolute, out var targetUri) ||
                (targetUri.Scheme != Uri.UriSchemeHttp && targetUri.Scheme != Uri.UriSchemeHttps))
            {
                return BadRequest("Invalid image URL");
            }

            try
            {
                using var response = await HttpClient.GetAsync(targetUri);
                if (!response.IsSuccessStatusCode && targetUri.Scheme == Uri.UriSchemeHttps)
                {
                    var httpUri = new UriBuilder(targetUri) { Scheme = Uri.UriSchemeHttp, Port = -1 }.Uri;
                    using var fallbackResponse = await HttpClient.GetAsync(httpUri);
                    if (!fallbackResponse.IsSuccessStatusCode)
                    {
                        return NotFound();
                    }
                    var fallbackBytes = await fallbackResponse.Content.ReadAsByteArrayAsync();
                    var fallbackType = fallbackResponse.Content.Headers.ContentType?.ToString() ?? "image/jpeg";
                    return File(fallbackBytes, fallbackType);
                }

                if (!response.IsSuccessStatusCode)
                {
                    return NotFound();
                }

                var bytes = await response.Content.ReadAsByteArrayAsync();
                var contentType = response.Content.Headers.ContentType?.ToString() ?? "image/jpeg";
                return File(bytes, contentType);
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Failed to proxy image {url}: {ex.Message}");
                return NotFound();
            }
        }
    }
}
