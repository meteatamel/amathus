
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
using System.Globalization;
using System.IO;
using System.Xml;

namespace Amathus.Common.Reader
{
    /// <summary>
    /// XmlTextReader implementation that reads any date format and does not enforce the RSS date format.
    /// It also tries to read Turkish dates (I know this violates single responsibility principle!)
    /// </summary>
    public class DateInvariantXmlReader : XmlTextReader
    {
        private static readonly CultureInfo EnglishCultureInfo = CultureInfo.CreateSpecificCulture("en-GB");
        private static readonly CultureInfo TurkishCultureInfo = CultureInfo.CreateSpecificCulture("tr-TR");

        private bool _readingDate;

        public DateInvariantXmlReader(Stream input): base(input)
        {
            // No-op.
        }

        public DateInvariantXmlReader(string inputUri): base(inputUri)
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
            if (_readingDate) _readingDate = false;
            base.ReadEndElement();
        }

        public override string ReadString()
        {
            if (!_readingDate) return base.ReadString();

            var dateString = base.ReadString();

            if (!DateTime.TryParse(dateString, EnglishCultureInfo, DateTimeStyles.None, out DateTime dt))
            {
                try
                {
                    dt = DateTime.Parse(dateString, TurkishCultureInfo);
                }
                catch (FormatException)
                {
                    dt = DateTime.Today;
                }
            }

            return dt.ToUniversalTime().ToString("R", CultureInfo.InvariantCulture);
        }
    }
}
