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

        private static readonly Regex CyprusRegex = new Regex(
            @"(κύπρ|κυπριακ|λευκωσί|λεμεσ|λάρνακ|πάφο|αμμόχωστ|κερύνει|μόρφου|πύλα|παραλίμν|αγία\s+νάπα|τρόοδος|ακάμα|χριστοδουλίδ|ερχιουρμάν|τατάρ|αναστασιάδ|ακελ|δησυ|δηκο|ελαμ|εδεκ|δηπα|προεδρικό|κατεχόμεν|ψευδοκράτ|νεκρή\s+ζώνη|οδόφραγμ|οδοφράγματ|δικοινοτικ|τουρκοκύπρι|ελληνοκύπρι|γεσυ|οκυπυ|κεβε|οεβ|ποεδ|οελμεκ|kıbrıs|kibris|kktc|lefkoşa|lefkosa|girne|mağusa|magusa|gazimağusa|güzelyurt|iskele|lefke|mesarya|dipkarpaz|karpaz|maraş|pile|limasol|larnaka|\bbaf\b|güney\s+kıbrıs|kuzey\s+kıbrıs|\brum\b|rumlar|erhürman|erhurman|\btatar\b|üstel|hristodulidis|\bubp\b|\bctp\b|\bydp\b|\btdp\b|ara\s+bölge|sınır\s+kapısı|iki\s+toplumlu|kıb-tek|ktto|ktams|ktoeös|ktös|ercan\s+havalimanı|cyprus|cypriot|nicosia|limassol|larnaca|paphos|famagusta|kyrenia|morphou|\bpyla\b|buffer\s+zone|green\s+line|unficyp|trnc|bicommunal|christodoulides|troodos|akamas|ayia\s+napa|protaras|karpass)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex GreeceRegex = new Regex(
            @"(ελλάδ|ελλαδ|αθήνα|αθηνών|θεσσαλονίκ|μητσοτάκ|δένδια|γεραπετρίτ|αιγαί|κρήτη|\bρόδο|συριζα|πασοκ|νέα\s+δημοκρατία|μέγαρο\s+μαξίμου|yunanistan|\byunan\b|atina|selanik|miçotakis|micotakis|dendias|ege\s+denizi|girit|rodos|batı\s+trakya|greece|greek\s+government|athens|thessaloniki|mitsotakis|aegean|crete|rhodes|hellenic)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex TurkeyRegex = new Regex(
            @"(τουρκί|τουρκικ|άγκυρα|κωνσταντινούπολ|σμύρνη|ερντογάν|φιντάν|οζέλ|ζονγκουλντάκ|türkiye|ankara|istanbul|izmir|antalya|adana|mersin|bursa|konya|gaziantep|şanlıurfa|diyarbakır|kayseri|eskişehir|trabzon|samsun|zonguldak|erzurum|malatya|erdoğan|erdogan|hakan\s+fidan|özgür\s+özel|bahçeli|tbmm|ak\s+parti|\bchp\b|\bmhp\b|\bdem\s+parti\b|turkey|turkish\s+government|anatolia)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex WorldRegex = new Regex(
            @"(\bηπα\b|ουάσιγκτον|τραμπ|μπάιντεν|πεντάγωνο|ρωσί|μόσχα|πούτιν|κρεμλίνο|ουκρανί|ζελένσκι|κίεβο|κίνα|πεκίνο|ισραήλ|γάζα|νετανιάχου|ιράν|τεχεράνη|λιβάν|βυρητ|συρία|δαμασκ|γερμανί|βερολίνο|γαλλί|παρίσι|μακρόν|βρετανί|λονδίνο|βρυξέλλες|\babd\b|vaşington|washington|\btrump\b|\bbiden\b|pentagon|rusya|moskova|putin|kremlin|ukrayna|zelenski|kiev|\bçin\b|pekin|israil|gazze|netanyahu|\biran\b|tahran|lübnan|beyrut|suriye|şam|almanya|berlin|fransa|paris|macron|ingiltere|londra|brüksel|united\s+states|white\s+house|russia|moscow|ukraine|kyiv|zelensky|china|beijing|israel|gaza|netanyahu|tehran|lebanon|beirut|syria|damascus|germany|france|united\s+kingdom|london)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        /// <summary>
        /// Returns geographic priority tier in order:
        /// 4 = Explicit Cyprus news
        /// 3 = Local Cyprus news (no foreign country match in a Cyprus newspaper)
        /// 2 = Greece news
        /// 1 = Turkey news
        /// 0 = Rest of the World news
        /// </summary>
        public static int GetGeoRelevanceTier(string title, string summary = null, string detail = null)
        {
            var combined = $"{title} {summary} {detail}";
            if (string.IsNullOrWhiteSpace(combined))
            {
                return 0;
            }

            // If Cyprus is explicitly mentioned in title or summary, highest priority (4)
            var titleAndSummary = $"{title} {summary}";
            if (CyprusRegex.IsMatch(titleAndSummary))
            {
                return 4;
            }

            if (CyprusRegex.IsMatch(combined))
            {
                return 4;
            }

            bool isGreece = GreeceRegex.IsMatch(combined);
            bool isTurkey = TurkeyRegex.IsMatch(combined);
            bool isWorld = WorldRegex.IsMatch(combined);

            if (isGreece)
            {
                return 2;
            }

            if (isTurkey)
            {
                return 1;
            }

            if (isWorld)
            {
                return 0;
            }

            // Domestic local article in a Cyprus newspaper without foreign country references
            return 3;
        }

        public static string GetGeoRelevanceLabel(int tier)
        {
            return tier switch
            {
                >= 3 => "Cyprus",
                2 => "Greece",
                1 => "Turkey",
                _ => "World"
            };
        }
    }
}
