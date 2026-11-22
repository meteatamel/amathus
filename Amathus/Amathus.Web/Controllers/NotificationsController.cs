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
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading.Tasks;
using Amathus.Common.Notifications;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace Amathus.Web.Controllers
{
    public class NotificationPreferencesRequest
    {
        public string Token { get; set; }
        public string Language { get; set; }
        public List<string> Editions { get; set; } = new();
    }

    public class NotificationUnsubscribeRequest
    {
        public string Token { get; set; }
    }

    [Route("api/v1/[controller]")]
    [ApiController]
    public class NotificationsController : ControllerBase
    {
        private const int MaxRequestsPerIpPerMinute = 30;
        private static readonly ConcurrentDictionary<string, (DateTime WindowStart, int Count)> RateLimitBuckets = new();

        private readonly FcmNotificationService _notificationService;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            FcmNotificationService notificationService,
            ILogger<NotificationsController> logger)
        {
            _notificationService = notificationService;
            _logger = logger;
        }

        [HttpPost("preferences")]
        public async Task<IActionResult> UpdatePreferences([FromBody] NotificationPreferencesRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Token) || request.Token.Length > 512)
            {
                return BadRequest("A valid FCM registration token is required.");
            }

            if (IsRateLimited())
            {
                return StatusCode(429, "Too many notification preference updates. Please try again shortly.");
            }

            try
            {
                var (subscribed, unsubscribed) = await _notificationService.UpdatePreferencesAsync(
                    request.Token.Trim(),
                    request.Language,
                    request.Editions);

                return Ok(new
                {
                    Status = "ok",
                    SubscribedTopics = subscribed,
                    UnsubscribedCount = unsubscribed.Count
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to update notification preferences.");
                return StatusCode(500, "Could not update notification preferences.");
            }
        }

        [HttpPost("unsubscribe")]
        public async Task<IActionResult> Unsubscribe([FromBody] NotificationUnsubscribeRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Token) || request.Token.Length > 512)
            {
                return BadRequest("A valid FCM registration token is required.");
            }

            if (IsRateLimited())
            {
                return StatusCode(429, "Too many requests. Please try again shortly.");
            }

            try
            {
                var (_, unsubscribed) = await _notificationService.UpdatePreferencesAsync(
                    request.Token.Trim(),
                    "en",
                    Array.Empty<string>());

                return Ok(new
                {
                    Status = "ok",
                    UnsubscribedCount = unsubscribed.Count
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to unsubscribe token from notification topics.");
                return StatusCode(500, "Could not unsubscribe from notifications.");
            }
        }

        private bool IsRateLimited()
        {
            var ip = HttpContext?.Request?.Headers["X-Forwarded-For"].ToString();
            if (!string.IsNullOrWhiteSpace(ip))
            {
                var commaIdx = ip.IndexOf(',');
                if (commaIdx > 0)
                {
                    ip = ip.Substring(0, commaIdx);
                }
                ip = ip.Trim();
            }
            else
            {
                ip = HttpContext?.Connection?.RemoteIpAddress?.ToString() ?? "unknown";
            }

            var now = DateTime.UtcNow;
            if (RateLimitBuckets.Count > 5000)
            {
                RateLimitBuckets.Clear();
            }

            var bucket = RateLimitBuckets.AddOrUpdate(
                ip,
                _ => (now, 1),
                (_, existing) => (now - existing.WindowStart) >= TimeSpan.FromMinutes(1)
                    ? (now, 1)
                    : (existing.WindowStart, existing.Count + 1));

            return bucket.Count > MaxRequestsPerIpPerMinute;
        }
    }
}
