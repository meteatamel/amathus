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
        private const string ImgPattern = "<img.+?src=[\"'](.+?)[\"'].+?>";
        private static readonly Regex ImgRegex = new Regex(ImgPattern);
        private const string BannedPattern = "(c|k)ovid|(c|k)orona|vir(u|ü)s|vaka";

        public static string RemoveHtmlTabAndNewLine(string text)
        {
            return RemoveHtml(RemoveTabAndNewLine(text));
        }

        public static string HtmlDecode(string text)
        {
            // Some feeds have extra space before or after
            return HttpUtility.HtmlDecode(text).Trim();
        }

        public static string RemoveHtml(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            return Regex.Replace(text, "<.+?>", string.Empty);
        }

        public static Uri GetImg(string text)
        {
            return string.IsNullOrEmpty(text) ? null : new Uri(text);
        }

        public static Uri ExtractImgSrc(string text)
        {
            var extracted = Regex.Match(text, ImgPattern, RegexOptions.IgnoreCase).Groups[1].Value;
            return string.IsNullOrEmpty(extracted)? null : new Uri(extracted);
        }

        public static string RemoveImgSrc(string text)
        {
            return ImgRegex.Replace(text, string.Empty, 1);
        }

        public static string RemoveSubtext(string text, string subtext)
        {
            var regex = new Regex(subtext);
            return regex.Replace(text, string.Empty, 1);
        }

        public static string RemoveFooter(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            if (Regex.IsMatch(text, "The post (.+?) appeared"))
            {
                return text.Substring(0, text.IndexOf("The post"));
            }

            return text;
        }

        public static string RemoveTabAndNewLine(string text)
        {
            if (string.IsNullOrEmpty(text))
            {
                return text;
            }

            return Regex.Replace(text, @"\t|\n|\r|&nbsp;", "").Trim();
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
