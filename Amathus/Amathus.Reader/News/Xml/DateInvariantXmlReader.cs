using System;
using System.Globalization;
using System.Xml;

namespace Amathus.Reader.News.Xml
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
