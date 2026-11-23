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
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amathus.Common.Overview;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;

namespace Amathus.Common.Notifications
{
    public class FcmNotificationService
    {
        public static readonly string[] ValidEditions = { "morning", "midday", "evening" };
        public static readonly string[] ValidLanguages = { "en", "tr", "el" };

        private const string DefaultClientUrl = "https://amathus-client-1086570528700.europe-west1.run.app/";

        private static readonly object InitLock = new();
        private static FirebaseApp _firebaseApp;
        private static bool _initAttempted;

        private readonly string _projectId;
        private readonly string _clientUrl;
        private readonly ILogger<FcmNotificationService> _logger;

        public FcmNotificationService(
            string projectId,
            ILogger<FcmNotificationService> logger,
            string clientUrl = null)
        {
            _projectId = string.IsNullOrWhiteSpace(projectId) ? "events-atamel" : projectId.Trim();
            _clientUrl = string.IsNullOrWhiteSpace(clientUrl) ? DefaultClientUrl : clientUrl.Trim();
            _logger = logger;
        }

        public static string TopicName(string edition, string language) =>
            $"briefing_{edition.Trim().ToLowerInvariant()}_{language.Trim().ToLowerInvariant()}";

        private FirebaseMessaging GetMessaging()
        {
            if (_firebaseApp != null)
            {
                return FirebaseMessaging.GetMessaging(_firebaseApp);
            }

            if (_initAttempted)
            {
                return null;
            }

            lock (InitLock)
            {
                if (_firebaseApp != null)
                {
                    return FirebaseMessaging.GetMessaging(_firebaseApp);
                }

                if (_initAttempted)
                {
                    return null;
                }

                try
                {
                    _firebaseApp = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
                    {
                        Credential = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("K_SERVICE"))
                            ? GoogleCredential.FromComputeCredential()
                            : GoogleCredential.GetApplicationDefault(),
                        ProjectId = _projectId
                    });
                }
                catch (Exception ex)
                {
                    _logger?.LogWarning($"Could not initialize FirebaseApp for FCM: {ex.Message}");
                    _firebaseApp = null;
                }
                finally
                {
                    _initAttempted = true;
                }

                return _firebaseApp != null ? FirebaseMessaging.GetMessaging(_firebaseApp) : null;
            }
        }

        public async Task<(List<string> Subscribed, List<string> Unsubscribed)> UpdatePreferencesAsync(
            string token,
            string language,
            IEnumerable<string> enabledEditions)
        {
            var messaging = GetMessaging();
            if (messaging == null)
            {
                throw new InvalidOperationException("Firebase Cloud Messaging is not initialized.");
            }

            var normLang = (language ?? "en").Trim().ToLowerInvariant();
            if (!ValidLanguages.Contains(normLang))
            {
                normLang = "en";
            }

            var desiredTopics = new HashSet<string>(
                (enabledEditions ?? Enumerable.Empty<string>())
                    .Where(e => !string.IsNullOrWhiteSpace(e))
                    .Select(e => e.Trim().ToLowerInvariant())
                    .Where(e => ValidEditions.Contains(e))
                    .Distinct()
                    .Select(e => TopicName(e, normLang)),
                StringComparer.Ordinal);

            var allTopics = (
                from ed in ValidEditions
                from lang in ValidLanguages
                select TopicName(ed, lang)
            ).ToList();

            var subscribed = new List<string>();
            var unsubscribed = new List<string>();
            var tokens = new List<string> { token };

            foreach (var topic in allTopics)
            {
                if (desiredTopics.Contains(topic))
                {
                    var res = await messaging.SubscribeToTopicAsync(tokens, topic);
                    if (res.FailureCount > 0)
                    {
                        var reason = res.Errors.FirstOrDefault()?.Reason ?? "unknown";
                        _logger?.LogWarning($"Failed to subscribe token to {topic}: {reason}");
                    }
                    else
                    {
                        subscribed.Add(topic);
                    }
                }
                else
                {
                    var res = await messaging.UnsubscribeFromTopicAsync(tokens, topic);
                    if (res.FailureCount == 0)
                    {
                        unsubscribed.Add(topic);
                    }
                }
            }

            return (subscribed, unsubscribed);
        }

        public async Task<Dictionary<string, string>> SendEditionBriefingAsync(
            NewsOverview overview,
            string editionOverride = null)
        {
            var results = new Dictionary<string, string>();
            var messaging = GetMessaging();
            if (messaging == null || overview == null)
            {
                return results;
            }

            var edition = PodcastScriptBuilder.ResolveEdition(overview.GeneratedAt, editionOverride ?? overview.Edition);
            var leadStory = overview.Stories?.FirstOrDefault();

            foreach (var lang in ValidLanguages)
            {
                var topic = TopicName(edition, lang);
                var title = BuildTitle(edition, lang);
                var body = BuildBody(overview, leadStory, edition, lang);

                var message = new Message
                {
                    Topic = topic,
                    Notification = new Notification
                    {
                        Title = title,
                        Body = body
                    },
                    Data = new Dictionary<string, string>
                    {
                        ["edition"] = edition,
                        ["lang"] = lang,
                        ["route"] = "overview",
                        ["url"] = _clientUrl,
                        ["click_action"] = "FLUTTER_NOTIFICATION_CLICK"
                    },
                    Webpush = new WebpushConfig
                    {
                        Headers = new Dictionary<string, string>
                        {
                            ["Urgency"] = "high",
                            ["TTL"] = "14400"
                        },
                        FcmOptions = new WebpushFcmOptions
                        {
                            Link = _clientUrl
                        }
                    },
                    Android = new AndroidConfig
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification
                        {
                            Title = title,
                            Body = body,
                            ChannelId = "amathus_briefings",
                            ClickAction = "FLUTTER_NOTIFICATION_CLICK"
                        }
                    },
                    Apns = new ApnsConfig
                    {
                        Aps = new Aps
                        {
                            Alert = new ApsAlert
                            {
                                Title = title,
                                Body = body
                            },
                            Sound = "default",
                            ThreadId = "amathus-briefing"
                        }
                    }
                };

                try
                {
                    var messageId = await messaging.SendAsync(message);
                    results[topic] = messageId;
                    _logger?.LogInformation($"Sent FCM briefing notification to topic {topic}: {messageId}");
                }
                catch (Exception ex)
                {
                    _logger?.LogWarning($"Failed to send FCM notification to topic {topic}: {ex.Message}");
                    results[topic] = $"error: {ex.Message}";
                }
            }

            return results;
        }

        private static string BuildTitle(string edition, string lang) => (edition, lang) switch
        {
            ("morning", "tr") => "Sabah 5 Dakikada Kıbrıs Haber",
            ("morning", "el") => "Πρωινή 5λεπτη Σύνοψη Κύπρου",
            ("morning", _) => "Morning 5-Min Cyprus News",

            ("midday", "tr") => "Öğle 5 Dakikada Kıbrıs Haber",
            ("midday", "el") => "Μεσημεριανή 5λεπτη Σύνοψη Κύπρου",
            ("midday", _) => "Lunch 5-Min Cyprus News",

            ("evening", "tr") => "Akşam 5 Dakikada Kıbrıs Haber",
            ("evening", "el") => "Βραδινή 5λεπτη Σύνοψη Κύπρου",
            _ => "Evening 5-Min Cyprus News"
        };

        private static string BuildBody(NewsOverview overview, OverviewStory leadStory, string edition, string lang)
        {
            var headline = lang switch
            {
                "tr" => leadStory?.TitleTr,
                "el" => leadStory?.TitleEl,
                _ => leadStory?.TitleEn
            };

            if (!string.IsNullOrWhiteSpace(headline))
            {
                var trimmed = headline.Trim();
                return trimmed.Length > 140 ? trimmed.Substring(0, 137) + "..." : trimmed;
            }

            var summary = lang switch
            {
                "tr" => overview.SummaryTr,
                "el" => overview.SummaryEl,
                _ => overview.SummaryEn
            };

            if (!string.IsNullOrWhiteSpace(summary))
            {
                var trimmed = summary.Trim();
                return trimmed.Length > 140 ? trimmed.Substring(0, 137) + "..." : trimmed;
            }

            return lang switch
            {
                "tr" => "Yeni 5 dakikalık Kıbrıs haber özetiniz hazır.",
                "el" => "Η νέα 5λεπτη σύνοψη ειδήσεων Κύπρου είναι έτοιμη.",
                _ => "Your new 5-minute Cyprus news review is ready."
            };
        }
    }
}
