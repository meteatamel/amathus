using System;

namespace Amathus.Reader.Common.Util
{
    public static class UrlUtil
    {
        public static Uri GetUrl(string text)
        {
            return string.IsNullOrEmpty(text) ? null : new Uri(text);
        }
    }
}
