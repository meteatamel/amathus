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
