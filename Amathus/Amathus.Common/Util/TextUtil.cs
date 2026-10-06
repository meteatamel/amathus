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
using System.Text.RegularExpressions;
using System.Web;

namespace Amathus.Common.Util
{
    public static class TextUtil
    {
        private const string ImgPattern = "<img.+?src=[\"'](.+?)[\"'].*?>";
        private static readonly Regex ImgRegex = new Regex(ImgPattern, RegexOptions.IgnoreCase | RegexOptions.Singleline);
        private const string BannedPattern = "(c|k)ovid|(c|k)orona|vir(u|ü)s|vaka";

        public static string RemoveHtmlTabAndNewLine(string text)
        {
            return RemoveHtml(RemoveTabAndNewLine(text));
        }

        public static string HtmlDecode(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return string.Empty;
            }
            // Some feeds have extra space before or after
            return HttpUtility.HtmlDecode(text).Trim();
        }

        public static string RemoveHtml(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            return Regex.Replace(text, "<.+?>", string.Empty, RegexOptions.Singleline).Trim();
        }

        public static Uri EnsureHttps(Uri uri)
        {
            if (uri == null)
            {
                return null;
            }
            if (uri.Scheme == Uri.UriSchemeHttp)
            {
                var builder = new UriBuilder(uri)
                {
                    Scheme = Uri.UriSchemeHttps,
                    Port = -1
                };
                return builder.Uri;
            }
            return uri;
        }

        public static Uri GetImg(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return null;
            }
            return Uri.TryCreate(text.Trim(), UriKind.Absolute, out var uri) ? EnsureHttps(uri) : null;
        }

        public static Uri ExtractImgSrc(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return null;
            }
            var extracted = ImgRegex.Match(text).Groups[1].Value;
            return GetImg(extracted);
        }

        public static string RemoveImgSrc(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }
            return ImgRegex.Replace(text, string.Empty, 1);
        }

        public static string RemoveSubtext(string text, string subtext)
        {
            if (string.IsNullOrEmpty(text) || string.IsNullOrEmpty(subtext))
            {
                return text;
            }
            var regex = new Regex(Regex.Escape(subtext));
            return regex.Replace(text, string.Empty, 1).Trim();
        }

        public static string RemoveFooter(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            if (Regex.IsMatch(text, "The post (.+?) appeared", RegexOptions.Singleline))
            {
                return text.Substring(0, text.IndexOf("The post")).Trim();
            }

            return text;
        }

        public static string RemoveTabAndNewLine(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            return Regex.Replace(text, @"\t|\n|\r|&nbsp;", " ").Trim();
        }

        public static string RemoveAmp(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            return Regex.Replace(text, "&amp;", "&").Trim();
        }

        public static bool ContainsBannedWords(string text)
        {
            return !string.IsNullOrEmpty(text) && Regex.IsMatch(text, BannedPattern, RegexOptions.IgnoreCase);
        }
    }
}
