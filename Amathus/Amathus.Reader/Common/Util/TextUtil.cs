﻿// Copyright 2019 Google LLC
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
using System.Text.RegularExpressions;
using System.Web;

namespace Amathus.Reader.Common.Util
{
    public static class TextUtil
    {
        public static string RemoveHtmlTabAndNewLine(string text)
        {
            return DecodeHtmlChars(RemoveHtml(RemoveTabAndNewLine(text)));
        }

        public static string RemoveHtml(string text)
        {
            return Regex.Replace(text, "<.+?>", string.Empty);
        }

        private static string RemoveTabAndNewLine(string text)
        {
            return Regex.Replace(text, @"\t|\n|\r|&nbsp;", "");
        }

        public static string ExtractImgSrc(string text)
        {
            return Regex.Match(text, "<img.+?src=[\"'](.+?)[\"'].+?>", RegexOptions.IgnoreCase).Groups[1].Value;
        }

        private static string DecodeHtmlChars(string text)
        {
            // This decodes chars like &#8217; into '
            return HttpUtility.HtmlDecode(text);
        }
    }
}
