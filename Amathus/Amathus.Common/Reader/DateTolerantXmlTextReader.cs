
// Copyright 2020 Google LLC
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
using System.Globalization;
using System.IO;
using System.Xml;

namespace Amathus.Common.Reader
{
    /// <summary>
    /// XmlTextReader implementation that is more tolerant for different date formats.
    /// </summary>
    public class DateTolerantXmlTextReader : XmlTextReader
    {
        // Custom format for Hakikat source
        const string CustomUtcDateTimeFormat = "Tddd, dd MMM yyyy HH:mm:ss zzzz"; // TFri, 09 Oct 2020 15:39:58 +0300

        private bool _readingDate;

        public DateTolerantXmlTextReader(Stream input) : base(input)
        {
            // No-op.
        }

        public DateTolerantXmlTextReader(string inputUri) : base(inputUri)
        {
            // No-op.
        }

        public override void ReadStartElement()
        {
            _readingDate = string.Equals(base.NamespaceURI, string.Empty, StringComparison.InvariantCultureIgnoreCase) &&
                (string.Equals(base.LocalName, "lastBuildDate", StringComparison.InvariantCultureIgnoreCase)
                || string.Equals(base.LocalName, "pubDate", StringComparison.InvariantCultureIgnoreCase));
            base.ReadStartElement();
        }

        public override void ReadEndElement()
        {
            if (_readingDate)
            {
                _readingDate = false;
            }
            base.ReadEndElement();
        }

        public override string ReadString()
        {
            if (!_readingDate)
            {
                return base.ReadString();
            }

            var dateString = base.ReadString();

            if (!DateTime.TryParse(dateString, out DateTime dt))
            {
                dt = DateTime.ParseExact(dateString, CustomUtcDateTimeFormat, CultureInfo.InvariantCulture);
            }

            return dt.ToUniversalTime().ToString("R", CultureInfo.InvariantCulture);
        }
    }
}