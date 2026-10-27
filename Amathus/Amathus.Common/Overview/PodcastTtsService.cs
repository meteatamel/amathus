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
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Google.Apis.Auth.OAuth2;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Amathus.Common.Overview
{
    public static class PodcastTtsService
    {
        public const string DefaultVoicePreset = "chirp_aoede_puck";
        private const string GoogleCloudProjectId = "events-atamel";

        private static readonly HttpClient GoogleTtsHttp = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(30)
        };

        private static readonly SemaphoreSlim CredentialLock = new(1, 1);
        private static readonly ConcurrentDictionary<string, byte[]> AudioCache = new();

        private static GoogleCredential _cachedCredential;

        public static (string LanguageCode, string PersonaName, string CloudTtsVoiceName, string StylePrompt) ResolveGoogleVoice(
            string language,
            string speaker,
            string voicePreset = null)
        {
            var lang = (language ?? "en").Trim().ToLowerInvariant();
            var isHostB = string.Equals(speaker?.Trim(), "B", StringComparison.OrdinalIgnoreCase);
            var preset = NormalizeVoicePreset(voicePreset);

            var (personaA, personaB, enLocale, styleA, styleB) = preset switch
            {
                "chirp_sulafat_achird" => (
                    "Sulafat",
                    "Achird",
                    "en-GB",
                    "warm, casual, friendly, and relaxed conversational podcast co-host",
                    "friendly, approachable, casual, and upbeat conversational podcast co-host"
                ),
                "chirp_zephyr_charon" => (
                    "Zephyr",
                    "Charon",
                    "en-US",
                    "bright, breezy, casual, and cheerful conversational podcast co-host",
                    "smooth, easy-going, casual, and conversational podcast co-host"
                ),
                "chirp_kore_fenrir" => (
                    "Kore",
                    "Fenrir",
                    "en-GB",
                    "lively, clear, warm, and engaging conversational podcast co-host",
                    "energetic, expressive, and friendly conversational podcast co-host"
                ),
                "chirp_leda_orus" => (
                    "Leda",
                    "Orus",
                    "en-US",
                    "youthful, warm, calm, and natural conversational podcast co-host",
                    "calm, smooth, grounded, and friendly conversational podcast co-host"
                ),
                "chirp_callirrhoe_umbriel" => (
                    "Callirrhoe",
                    "Umbriel",
                    "en-US",
                    "easy-going, casual, warm, and relaxed friend chatting on a podcast",
                    "easy-going, laid-back, warm, and natural friend chatting on a podcast"
                ),
                _ => (
                    "Aoede",
                    "Puck",
                    "en-US",
                    "breezy, warm, casual, and friendly conversational podcast co-host",
                    "upbeat, casual, engaging, and friendly conversational podcast co-host"
                )
            };

            var locale = lang switch
            {
                "el" => "el-GR",
                "tr" => "tr-TR",
                _ => enLocale
            };

            var persona = isHostB ? personaB : personaA;
            var style = isHostB ? styleB : styleA;
            if (lang == "el")
            {
                style += "; articulate Greek words clearly, pronouncing 'Δι-κοινοτικές' / 'δι-κοινοτικά' (bicommunal, from κοινότητα) distinctly and never as 'δικομματικές'";
            }
            return (locale, persona, $"{locale}-Chirp3-HD-{persona}", style);
        }

        public static string NormalizeVoicePreset(string voicePreset)
        {
            if (string.IsNullOrWhiteSpace(voicePreset))
            {
                return DefaultVoicePreset;
            }

            var norm = voicePreset.Trim().ToLowerInvariant();
            return norm switch
            {
                "chirp_aoede_puck" => "chirp_aoede_puck",
                "chirp_sulafat_achird" => "chirp_sulafat_achird",
                "chirp_zephyr_charon" => "chirp_zephyr_charon",
                "chirp_kore_fenrir" => "chirp_kore_fenrir",
                "chirp_leda_orus" => "chirp_leda_orus",
                "chirp_callirrhoe_umbriel" => "chirp_callirrhoe_umbriel",
                _ => DefaultVoicePreset
            };
        }

        public static async Task<byte[]> SynthesizeMp3Async(
            string text,
            string language,
            string speaker,
            CancellationToken cancellationToken = default)
        {
            return await SynthesizeMp3Async(
                text,
                language,
                speaker,
                DefaultVoicePreset,
                cancellationToken);
        }

        public static async Task<byte[]> SynthesizeMp3Async(
            string text,
            string language,
            string speaker,
            string voicePreset,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return Array.Empty<byte>();
            }

            var cleanedText = Regex.Replace(text.Trim(), @"\s+", " ");
            if (cleanedText.Length > 1500)
            {
                cleanedText = cleanedText.Substring(0, 1500);
            }

            var lang = (language ?? "en").Trim().ToLowerInvariant();
            if (lang != "el" && lang != "tr" && lang != "en")
            {
                lang = "en";
            }

            var normalizedPreset = NormalizeVoicePreset(voicePreset);
            var (_, personaName, _, _) = ResolveGoogleVoice(lang, speaker, normalizedPreset);
            var effectiveVoiceId = $"gemini38:{lang}:{personaName}";

            var ttsText = PrepareTextForTts(cleanedText, lang);
            var cacheKey = $"v2:{effectiveVoiceId}:{ttsText}";
            if (AudioCache.TryGetValue(cacheKey, out var cached) && cached != null && cached.Length > 0)
            {
                return cached;
            }

            var gemini38Bytes = await TrySynthesizeGemini38TtsAsync(
                ttsText,
                lang,
                speaker,
                normalizedPreset,
                cancellationToken);

            if (gemini38Bytes != null && gemini38Bytes.Length > 0)
            {
                if (AudioCache.Count > 600)
                {
                    AudioCache.Clear();
                }
                AudioCache[cacheKey] = gemini38Bytes;
                return gemini38Bytes;
            }

            var gcpBytes = await TrySynthesizeGoogleCloudTtsAsync(
                ttsText,
                lang,
                speaker,
                normalizedPreset,
                cancellationToken);

            if (gcpBytes != null && gcpBytes.Length > 0)
            {
                if (AudioCache.Count > 600)
                {
                    AudioCache.Clear();
                }
                AudioCache[cacheKey] = gcpBytes;
                return gcpBytes;
            }

            return Array.Empty<byte>();
        }

        private static string PrepareTextForTts(string text, string lang)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return string.Empty;
            }

            if (lang == "el")
            {
                // Hyphenate Δι-κοινοτικές / δι-κοινοτικά so Greek TTS models articulate "κοινοτικές" (communal)
                // clearly instead of slurring or autocorrecting toward the more common "δικομματικές" (bipartisan).
                text = Regex.Replace(text, @"Δικοινοτικ", "Δι-κοινοτικ");
                text = Regex.Replace(text, @"δικοινοτικ", "δι-κοινοτικ");
            }

            return text;
        }

        private static async Task<string> GetGoogleAccessTokenAsync(CancellationToken cancellationToken)
        {
            if (_cachedCredential == null)
            {
                await CredentialLock.WaitAsync(cancellationToken);
                try
                {
                    if (_cachedCredential == null)
                    {
                        var cred = await GoogleCredential.GetApplicationDefaultAsync();
                        if (cred.IsCreateScopedRequired)
                        {
                            cred = cred.CreateScoped("https://www.googleapis.com/auth/cloud-platform");
                        }
                        _cachedCredential = cred;
                    }
                }
                finally
                {
                    CredentialLock.Release();
                }
            }

            return await ((ITokenAccess)_cachedCredential).GetAccessTokenForRequestAsync(
                cancellationToken: cancellationToken);
        }

        private static async Task<byte[]> TrySynthesizeGemini38TtsAsync(
            string text,
            string lang,
            string speaker,
            string voicePreset,
            CancellationToken cancellationToken)
        {
            try
            {
                var bearerToken = await GetGoogleAccessTokenAsync(cancellationToken);
                if (string.IsNullOrWhiteSpace(bearerToken))
                {
                    return null;
                }

                var (_, personaName, _, stylePrompt) = ResolveGoogleVoice(lang, speaker, voicePreset);
                var payload = new
                {
                    contents = new[]
                    {
                        new
                        {
                            role = "user",
                            parts = new[]
                            {
                                new
                                {
                                    text,
                                    speechMetadata = new
                                    {
                                        style = stylePrompt
                                    }
                                }
                            }
                        }
                    },
                    generationConfig = new
                    {
                        responseModalities = new[] { "AUDIO" },
                        speechConfig = new
                        {
                            voiceConfig = new
                            {
                                voice = personaName
                            }
                        }
                    }
                };

                var jsonPayload = JsonConvert.SerializeObject(payload);
                var modelsToTry = new[] { "gemini-3.8-flash-tts", "gemini-3.8-flash-lite-tts" };

                foreach (var model in modelsToTry)
                {
                    var url = $"https://aiplatform.googleapis.com/v1/projects/{GoogleCloudProjectId}/locations/global/publishers/google/models/{model}:generateContent";
                    using var req = new HttpRequestMessage(HttpMethod.Post, url)
                    {
                        Content = new StringContent(jsonPayload, Encoding.UTF8, "application/json")
                    };
                    req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);

                    using var resp = await GoogleTtsHttp.SendAsync(req, cancellationToken);
                    if (!resp.IsSuccessStatusCode)
                    {
                        continue;
                    }

                    var respJson = await resp.Content.ReadAsStringAsync(cancellationToken);
                    var root = JObject.Parse(respJson);
                    var base64Audio = root["candidates"]?[0]?["content"]?["parts"]?[0]?["inlineData"]?["data"]?.ToString();
                    if (!string.IsNullOrWhiteSpace(base64Audio))
                    {
                        return Convert.FromBase64String(base64Audio);
                    }
                }
            }
            catch
            {
                // Fall back cleanly if Vertex AI Gemini 3.8 TTS is unreachable
            }

            return null;
        }

        private static async Task<byte[]> TrySynthesizeGoogleCloudTtsAsync(
            string text,
            string lang,
            string speaker,
            string voicePreset,
            CancellationToken cancellationToken)
        {
            try
            {
                var (languageCode, _, voiceName, _) = ResolveGoogleVoice(lang, speaker, voicePreset);
                var payload = new
                {
                    input = new { text },
                    voice = new
                    {
                        languageCode,
                        name = voiceName
                    },
                    audioConfig = new
                    {
                        audioEncoding = "MP3",
                        speakingRate = 1.02
                    }
                };

                var jsonPayload = JsonConvert.SerializeObject(payload);
                var apiKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
                string url = "https://texttospeech.googleapis.com/v1/text:synthesize";
                string bearerToken = null;

                if (!string.IsNullOrWhiteSpace(apiKey))
                {
                    url = $"{url}?key={Uri.EscapeDataString(apiKey)}";
                }
                else
                {
                    bearerToken = await GetGoogleAccessTokenAsync(cancellationToken);
                    if (string.IsNullOrWhiteSpace(bearerToken))
                    {
                        return null;
                    }
                }

                for (int attempt = 0; attempt < 2; attempt++)
                {
                    using var req = new HttpRequestMessage(HttpMethod.Post, url)
                    {
                        Content = new StringContent(jsonPayload, Encoding.UTF8, "application/json")
                    };

                    if (!string.IsNullOrWhiteSpace(bearerToken))
                    {
                        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", bearerToken);
                        if (attempt == 0)
                        {
                            req.Headers.Add("x-goog-user-project", GoogleCloudProjectId);
                        }
                    }

                    using var resp = await GoogleTtsHttp.SendAsync(req, cancellationToken);
                    if (!resp.IsSuccessStatusCode)
                    {
                        continue;
                    }

                    var respJson = await resp.Content.ReadAsStringAsync(cancellationToken);
                    var root = JObject.Parse(respJson);
                    var base64Audio = root["audioContent"]?.ToString();
                    if (!string.IsNullOrWhiteSpace(base64Audio))
                    {
                        return Convert.FromBase64String(base64Audio);
                    }
                }
            }
            catch
            {
                // Fall back cleanly if Google Cloud TTS is unreachable
            }

            return null;
        }
    }
}
