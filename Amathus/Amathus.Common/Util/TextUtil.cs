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
using System.Collections.Generic;
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

        private static readonly Regex TopicSportsRegex = new Regex(
            @"(αθλητ|ποδόσφαιρ|μπάσκετ|καλαθόσφαιρ|τένις|ράλλυ|ομόνοια|αποελ|απόλλων|ανόρθωσ|\bαεκ\b|ολυμπιακ|παναθηναϊκ|\bπαοκ\b|ρεάλ|τσίτσιπας|πρωτάθλημ|γήπεδ|προπονητ|διαιτητ|κύπελλ|\bspor\b|futbol|basketbol|voleybol|tenis|ralli|\bmaç\b|\bmaçı\b|şampiyon|turnuva|stadyum|hakem|transfer|antrenör|fenerbahçe|galatasaray|beşiktaş|trabzonspor|ktff|çetinkaya|\bsport|\bfootball|basketball|tennis|rally|\bf1\b|hamilton|omonia|apoel|apollon|anorthosis|pafos\s+fc|olympiacos|panathinaikos|champions\s+league|euroleague|uefa|fifa)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex TopicCultureRegex = new Regex(
            @"(πολιτισμ|μουσικ|συναυλ|τραγουδ|ταινί|κινηματογράφ|θέατρ|ηθοποι|\bσειρές\b|φεστιβάλ|\bτέχνη|\bτέχνες|έκθεσ|μουσεί|βιβλί|μόδα|γαστρονομ|αρχαιολογ|βίσση|αργυρ|μόνροε|ουίλιαμ|kültür|sanat|müzik|konser|şarkı|\bfilm\b|sinema|tiyatro|oyuncu|\bdizi(si|ler|de)?\b|festival|sergi|müze|kitap|edebiyat|şiir|\bmoda\b|magazin|mutfak|gastronomi|arkeoloji|stranger\s+things|culture|music|concert|movie|cinema|theatre|actor|actress|netflix|\bart\b|exhibition|museum|book|fashion|celebrity|lifestyle|cuisine)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex TopicEconomyRegex = new Regex(
            @"(οικονομ|τράπεζ|πληθωρισμ|επιτόκι|φορολογ|\bφπα\b|επενδ|εμπόρι|ενέργει|ηλεκτρ|ηλεκτροκίνησ|φωτοβολταϊκ|τουρισμ|ξενοδοχ|εταιρ|επιχειρήσ|ακίνητ|ενοίκι|προϋπολογισμ|μισθ|σύνταξ|ανεργί|χρηματιστήρι|κεβε|οεβ|ekonom|banka|tcmb|\bfaiz|enflasyon|vergi|\bkdv\b|yatırım|ticaret|enerji|elektrik|kıb-tek|turizm|\botel|şirket|iş\s+dünyası|gayrimenkul|emlak|konut|\bkira\b|bütçe|maaş|asgari\s+ücret|emekli|işsizlik|borsa|döviz|sterlin|ihale|ktto|econom|eurostat|gini|\bbank|inflation|\btax|invest|trade|energy|solar|electricity|tourism|hotel|business|company|property|real\s+estate|budget|salary|wage|pension)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex TopicSocietyRegex = new Regex(
            @"(αστυνομ|δικαστ|κακουργιοδικ|ισόβι|ποιν|φυλακ|δολοφον|φόνο|ληστεί|κλοπ|χειροπέδες|σύλληψ|καταζητ|ναρκωτικ|κάνναβ|τελωνεί|τροχαίο|ατύχημ|δυστύχημ|πυρκαγι|πυροσβεστικ|νοσοκομ|υγεία|γιατρ|ασθεν|γεσυ|οκυπυ|σχολ|μαθητ|εκπαιδευτικ|δάσκαλ|καθηγητ|πανεπιστήμι|παιδεί|απεργία|συνδικαλ|ποεδ|οελμεκ|\bπεο\b|δήμο|δήμαρχ|αφαλάτωσ|αποχέτευσ|ανακύκλωσ|περιβάλλον|δασ|αγριν|φώκια|καιρ|κακοκαιρί|σεισμ|ναυάγι|polis|mahkeme|yüksek\s+mahkeme|ağır\s+ceza|yargıç|\bdava\b|hapis|cezaevi|cinayet|katil|soygun|hırsız|tutukl|zanlı|uyuşturucu|kaza|trafik|yangın|itfaiye|hastane|sağlık|doktor|hemşire|hasta|okul|öğrenci|öğretmen|üniversite|eğitim|grev|sendika|ktös|ktoeös|ktams|belediye|arıtma|çevre|orman|yağmur|fırtına|deprem|gemi\s+kazası|kayıp|soruşturma|police|court|murder|arrest|prison|cannabis|drug|hospital|health|school|education|strike|traffic|accident|fire|wildlife|seal|mouflon|municipality|water|desalination|shipwreck)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex TopicPoliticsRegex = new Regex(
            @"(πρόεδρ|πρωθυπουργ|υπουργ|κυβέρνησ|υπουργικό|βουλ|βουλευτ|κόμμα|εκλογ|υποψήφι|κάλπ|συμπολίτευσ|αντιπολίτευσ|\bοηε\b|νεκρή\s+ζώνη|οδόφραγμ|δικοινοτικ|κυπριακ|διαπραγματεύσ|ομοσπονδ|χριστοδουλίδ|ερχιουρμάν|τατάρ|αναστασιάδ|αννίτα|ακελ|δησυ|δικο|εδεκ|ελαμ|δηπα|διπλωματ|πρέσβ|\bαοζ\b|navtex|cumhurbaşkan|başbakan|bakan|bakanlık|hükümet|kabine|meclis|milletvekili|parti|seçim|aday|sandık|kurultay|koalisyon|muhalefet|\bbm\b|ara\s+bölge|sınır\s+kapısı|iki\s+toplumlu|kıbrıs\s+sorunu|müzakere|federasyon|iki\s+devlet|erhürman|erhurman|tatar|üstel|hristodulidis|\bubp\b|\bctp\b|\bydp\b|\btdp\b|\bhp\b|diplomat|büyükelçi|dışişleri|christodoulides|parliament|president|minister|government|election|unficyp|green\s+line|buffer\s+zone|bicommunal|cyprus\s+problem)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        private static readonly Regex TopicWorldRegex = new Regex(
            @"(ουκραν|ρωσ|μόσχα|κρεμλίν|ζελένσκι|πούτιν|γάζα|παλαιστιν|δυτική\s+όχθη|χαμάς|χεζμπολάχ|τεχεράν|πεντάγων|τραμπ|μπάιντεν|μακρόν|ισραήλ|ιράν|γαλλία|παρίσι|ισπανία|βρετανία|λονδίνο|\bηπα\b|ουάσιγκτον|κίνα|πεκίνο|γερμανί|βερολίνο|ιταλί|ρώμη|λιβάν|βυρητ|συρία|δαμασκ|αιγυπτ|κάιρο|ευρωπαϊκή\s+ένωση|βρυξέλλες|\bνατο\b|ελλάδ|αθήνα|θεσσαλονίκ|μητσοτάκ|τουρκί|άγκυρα|κωνσταντινούπολ|ερντογάν|ukrayna|rusya|moskova|kremlin|zelenski|putin|gazze|filistin|batı\s+şeria|hamas|hizbullah|tahran|pentagon|beyaz\s+saray|trump|biden|macron|israil|\biran\b|fransa|ispanya|ingiltere|londra|\babd\b|vaşington|washington|\bçin\b|pekin|almanya|berlin|italya|roma|lübnan|beyrut|suriye|şam|mısır|kahire|avrupa\s+birliği|brüksel|\bnato\b|yunanistan|atina|selanik|miçotakis|türkiye|ankara|istanbul|erdoğan|erdogan|ukraine|russia|moscow|zelensky|gaza|palestin|west\s+bank|israel|tehran|lebanon|beirut|syria|damascus|egypt|cairo|france|paris|spain|britain|united\s+kingdom|london|\busa\b|united\s+states|white\s+house|china|beijing|germany|berlin|italy|rome|brussels|\bnato\b|greece|athens|mitsotakis|turkey|ankara|istanbul|world|international|global)",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        public static string NormalizeTopic(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
            {
                return null;
            }

            var norm = raw.Trim().ToLowerInvariant();
            return norm switch
            {
                "politics" or "siyaset" or "politika" or "πολιτική" or "πολιτικη" => "politics",
                "society" or "toplum" or "asayiş" or "asayis" or "κοινωνία" or "κοινωνια" or "local" => "society",
                "economy" or "ekonomi" or "business" or "finance" or "οικονομία" or "οικονομια" => "economy",
                "sports" or "sport" or "spor" or "αθλητισμός" or "αθλητισμος" or "αθλητικά" => "sports",
                "culture" or "culture & life" or "lifestyle" or "kültür" or "yaşam" or "πολιτισμός" => "culture",
                "world" or "dünya" or "dunya" or "international" or "κόσμος" or "διεθνή" => "world",
                _ => null
            };
        }

        public static string ClassifyTopic(
            string title,
            string summary = null,
            string detail = null,
            string url = null,
            IEnumerable<string> categories = null)
        {
            if (categories != null)
            {
                foreach (var cat in categories)
                {
                    if (string.IsNullOrWhiteSpace(cat))
                    {
                        continue;
                    }
                    var direct = NormalizeTopic(cat);
                    if (direct != null)
                    {
                        return direct;
                    }
                    if (TopicSportsRegex.IsMatch(cat)) return "sports";
                    if (TopicEconomyRegex.IsMatch(cat)) return "economy";
                    if (TopicCultureRegex.IsMatch(cat)) return "culture";
                    if (TopicWorldRegex.IsMatch(cat)) return "world";
                    if (TopicSocietyRegex.IsMatch(cat)) return "society";
                    if (TopicPoliticsRegex.IsMatch(cat)) return "politics";
                }
            }

            var safeTitle = title ?? string.Empty;
            var safeSummary = summary ?? string.Empty;
            var safeDetail = !string.IsNullOrEmpty(detail) && detail.Length > 600
                ? detail.Substring(0, 600)
                : (detail ?? string.Empty);
            var safeUrl = url ?? string.Empty;

            int Score(Regex rx) =>
                rx.Matches(safeTitle).Count * 3 +
                rx.Matches(safeSummary).Count * 2 +
                rx.Matches(safeDetail).Count +
                rx.Matches(safeUrl).Count * 2;

            var combined = $"{safeTitle} {safeSummary} {safeDetail} {safeUrl}";
            bool hasCyprus = CyprusRegex.IsMatch(combined);
            int worldScore = Score(TopicWorldRegex);
            if (!hasCyprus && worldScore > 0)
            {
                worldScore += 6;
            }
            else if (hasCyprus && worldScore > 0)
            {
                worldScore = Math.Max(0, worldScore - 4);
            }

            var scores = new (string topic, int score)[]
            {
                ("sports", Score(TopicSportsRegex)),
                ("economy", Score(TopicEconomyRegex)),
                ("culture", Score(TopicCultureRegex)),
                ("society", Score(TopicSocietyRegex)),
                ("politics", Score(TopicPoliticsRegex)),
                ("world", worldScore)
            };

            string bestTopic = "society";
            int bestScore = 0;
            foreach (var (topic, score) in scores)
            {
                if (score > bestScore)
                {
                    bestScore = score;
                    bestTopic = topic;
                }
            }

            if (bestScore > 0)
            {
                return bestTopic;
            }

            var geoTier = GetGeoRelevanceTier(safeTitle, safeSummary, safeDetail);
            return geoTier == 0 ? "world" : "society";
        }
    }
}
