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
using System.IO;
using System.Net.WebSockets;
using System.Security;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace Amathus.Common.Overview
{
    public static class PodcastTtsService
    {
        private const string TrustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
        private const string SecMsGecVersion = "1-130.0.2849.68";

        private static readonly SemaphoreSlim SynthesisLock = new(1, 1);
        private static readonly ConcurrentDictionary<string, byte[]> AudioCache = new();

        private static ClientWebSocket _sharedSocket;
        private static DateTime _sharedSocketConnectedAtUtc = DateTime.MinValue;

        public static string ResolveVoiceName(string language, string speaker)
        {
            var lang = (language ?? "en").Trim().ToLowerInvariant();
            var isHostB = string.Equals(speaker?.Trim(), "B", StringComparison.OrdinalIgnoreCase);

            // Strictly 1 female (Host A) and 1 male (Host B) voice per language
            return lang switch
            {
                "el" => isHostB ? "el-GR-NestorasNeural" : "el-GR-AthinaNeural",
                "tr" => isHostB ? "tr-TR-AhmetNeural" : "tr-TR-EmelNeural",
                _ => isHostB ? "en-GB-RyanNeural" : "en-GB-SoniaNeural"
            };
        }

        public static string ResolveXmlLang(string language)
        {
            var lang = (language ?? "en").Trim().ToLowerInvariant();
            return lang switch
            {
                "el" => "el-GR",
                "tr" => "tr-TR",
                _ => "en-GB"
            };
        }

        public static async Task<byte[]> SynthesizeMp3Async(
            string text,
            string language,
            string speaker,
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

            var voice = ResolveVoiceName(lang, speaker);
            var xmlLang = ResolveXmlLang(lang);
            // Uniform natural rate across all speakers and languages
            const string rate = "+0%";
            var cacheKey = $"{voice}:{rate}:{cleanedText}";

            if (AudioCache.TryGetValue(cacheKey, out var cached) && cached != null && cached.Length > 0)
            {
                return cached;
            }

            await SynthesisLock.WaitAsync(cancellationToken);
            try
            {
                if (AudioCache.TryGetValue(cacheKey, out cached) && cached != null && cached.Length > 0)
                {
                    return cached;
                }

                byte[] audioBytes = null;
                for (int attempt = 0; attempt < 3; attempt++)
                {
                    try
                    {
                        audioBytes = await SynthesizeOnSharedSocketAsync(
                            cleanedText,
                            voice,
                            xmlLang,
                            rate,
                            cancellationToken);

                        if (audioBytes != null && audioBytes.Length > 0)
                        {
                            break;
                        }
                    }
                    catch
                    {
                        DisposeSharedSocket();
                        if (attempt < 2)
                        {
                            await Task.Delay(350 * (attempt + 1), cancellationToken);
                        }
                    }
                }

                if (audioBytes != null && audioBytes.Length > 0)
                {
                    if (AudioCache.Count > 600)
                    {
                        AudioCache.Clear();
                    }
                    AudioCache[cacheKey] = audioBytes;
                    return audioBytes;
                }

                return Array.Empty<byte>();
            }
            finally
            {
                SynthesisLock.Release();
            }
        }

        private static async Task<ClientWebSocket> GetOrConnectSharedSocketAsync(CancellationToken cancellationToken)
        {
            if (_sharedSocket != null &&
                _sharedSocket.State == WebSocketState.Open &&
                (DateTime.UtcNow - _sharedSocketConnectedAtUtc) < TimeSpan.FromMinutes(2))
            {
                return _sharedSocket;
            }

            DisposeSharedSocket();

            var secMsGec = GenerateSecMsGec();
            var connectionId = Guid.NewGuid().ToString("N");
            var muid = Guid.NewGuid().ToString("N").ToUpperInvariant();
            var uri = new Uri(
                $"wss://api.msedgeservices.com/tts/cognitiveservices/websocket/v1?Ocp-Apim-Subscription-Key={TrustedClientToken}&Sec-MS-GEC={secMsGec}&Sec-MS-GEC-Version={SecMsGecVersion}&ConnectionId={connectionId}");

            var ws = new ClientWebSocket();
            ws.Options.SetRequestHeader("Origin", "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold");
            ws.Options.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0");
            ws.Options.SetRequestHeader("Cookie", $"MUID={muid};");

            await ws.ConnectAsync(uri, cancellationToken);

            var timestamp = DateTime.UtcNow.ToString(
                "ddd MMM dd yyyy HH:mm:ss 'GMT+0000 (Coordinated Universal Time)'",
                System.Globalization.CultureInfo.InvariantCulture);

            var configMsg =
                $"X-Timestamp:{timestamp}\r\n" +
                "Content-Type:application/json; charset=utf-8\r\n" +
                "Path:speech.config\r\n\r\n" +
                "{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{\"sentenceBoundaryEnabled\":\"false\",\"wordBoundaryEnabled\":\"false\"},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}";

            var configBytes = Encoding.UTF8.GetBytes(configMsg);
            await ws.SendAsync(new ArraySegment<byte>(configBytes), WebSocketMessageType.Text, true, cancellationToken);

            _sharedSocket = ws;
            _sharedSocketConnectedAtUtc = DateTime.UtcNow;
            return _sharedSocket;
        }

        private static void DisposeSharedSocket()
        {
            if (_sharedSocket != null)
            {
                try
                {
                    _sharedSocket.Dispose();
                }
                catch
                {
                }
                _sharedSocket = null;
            }
        }

        private static async Task<byte[]> SynthesizeOnSharedSocketAsync(
            string text,
            string voice,
            string xmlLang,
            string rate,
            CancellationToken cancellationToken)
        {
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            cts.CancelAfter(TimeSpan.FromSeconds(15));

            var ws = await GetOrConnectSharedSocketAsync(cts.Token);

            var timestamp = DateTime.UtcNow.ToString(
                "ddd MMM dd yyyy HH:mm:ss 'GMT+0000 (Coordinated Universal Time)'",
                System.Globalization.CultureInfo.InvariantCulture);
            var requestId = Guid.NewGuid().ToString("N");
            var escapedText = SecurityElement.Escape(text);
            var ssmlMsg =
                $"X-RequestId:{requestId}\r\n" +
                "Content-Type:application/ssml+xml\r\n" +
                $"X-Timestamp:{timestamp}Z\r\n" +
                "Path:ssml\r\n\r\n" +
                $"<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='{xmlLang}'><voice name='{voice}'><prosody rate='{rate}'>{escapedText}</prosody></voice></speak>";

            var ssmlBytes = Encoding.UTF8.GetBytes(ssmlMsg);
            await ws.SendAsync(new ArraySegment<byte>(ssmlBytes), WebSocketMessageType.Text, true, cts.Token);

            using var audioStream = new MemoryStream();
            var receiveBuffer = new byte[16 * 1024];

            while (ws.State == WebSocketState.Open)
            {
                using var frameStream = new MemoryStream();
                WebSocketReceiveResult result;
                do
                {
                    result = await ws.ReceiveAsync(new ArraySegment<byte>(receiveBuffer), cts.Token);
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        DisposeSharedSocket();
                        break;
                    }
                    frameStream.Write(receiveBuffer, 0, result.Count);
                } while (!result.EndOfMessage);

                if (result.MessageType == WebSocketMessageType.Close)
                {
                    break;
                }

                var frameBytes = frameStream.ToArray();
                if (result.MessageType == WebSocketMessageType.Text)
                {
                    var messageText = Encoding.UTF8.GetString(frameBytes);
                    if (messageText.Contains("Path:turn.end", StringComparison.Ordinal))
                    {
                        break;
                    }
                }
                else if (result.MessageType == WebSocketMessageType.Binary && frameBytes.Length > 2)
                {
                    int headerLength = (frameBytes[0] << 8) | frameBytes[1];
                    if (frameBytes.Length > 2 + headerLength)
                    {
                        var headerText = Encoding.UTF8.GetString(frameBytes, 2, headerLength);
                        if (headerText.Contains("Path:audio", StringComparison.Ordinal))
                        {
                            int audioOffset = 2 + headerLength;
                            audioStream.Write(frameBytes, audioOffset, frameBytes.Length - audioOffset);
                        }
                    }
                }
            }

            var resultBytes = audioStream.ToArray();
            if (resultBytes.Length == 0)
            {
                DisposeSharedSocket();
            }
            return resultBytes;
        }

        private static string GenerateSecMsGec()
        {
            long unixSeconds = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            long ticks = (unixSeconds + 11644473600L) * 10000000L;
            ticks -= ticks % 3000000000L;
            var toHash = $"{ticks}{TrustedClientToken}";
            using var sha256 = SHA256.Create();
            var hashBytes = sha256.ComputeHash(Encoding.ASCII.GetBytes(toHash));
            return BitConverter.ToString(hashBytes).Replace("-", "").ToUpperInvariant();
        }
    }
}
