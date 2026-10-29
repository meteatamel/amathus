import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// urls
const String PROD_URL_MAIN =
    "https://amathus-web-1086570528700.europe-west1.run.app/api/v1";
const String LOCAL_URL_MAIN = "http://localhost:5002/api/v1";
const String URL_MAIN = String.fromEnvironment(
  'API_URL',
  defaultValue: kDebugMode ? LOCAL_URL_MAIN : PROD_URL_MAIN,
);
const String URL_FEEDS = "$URL_MAIN/feeds";
const String URL_FEED_ITEMS = "$URL_MAIN/feeditems";
const String URL_OVERVIEW = "$URL_MAIN/overview";
const String URL_PODCAST_AUDIO = "$URL_MAIN/overview/podcast/audio";
const String URL_TRANSLATE = "$URL_MAIN/translate";
const String URL_TWITTER = "https://twitter.com/meteatamel";

// files / storage keys
const String FEEDS_FILE = "feeds_v3.json";
const String FEED_ITEMS_RECENT_KEY = "feed_items_recent_v1.json";
const String FEED_ITEMS_COLUMNISTS_KEY = "feed_items_columnists_v1.json";
const String FEED_ITEMS_BY_ID_PREFIX = "feed_items_by_id_v1_";
const String OVERVIEW_STORAGE_KEY = "news_overview_v1.json";
const String COLUMNISTS_OVERVIEW_STORAGE_KEY = "columnists_overview_v1.json";
const String LANGUAGE_PREF_KEY = "app_language";
const String SHOW_ORIGINAL_PREF_KEY = "show_original";
const String SOURCE_LANGUAGE_PREF_KEY = "source_language";
const String HIDDEN_FEEDS_PREF_KEY = "hidden_feeds";
const String INSTALL_BANNER_DISMISSED_PREF_KEY = "install_banner_dismissed_v1";

// contact
const String APP_EMAIL = "atameldev@gmail.com";

// UI & reading language state ('tr', 'el', or 'en')
final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

// Whether to show headlines/articles in their original source language instead of auto-translating
final ValueNotifier<bool> showOriginalNotifier = ValueNotifier<bool>(false);

// News source language filter ('all', 'tr', 'el', or 'en')
final ValueNotifier<String> sourceLanguageNotifier =
    ValueNotifier<String>('all');

// Selected newspaper feed ID filter (null = all newspapers)
final ValueNotifier<String?> selectedFeedIdNotifier =
    ValueNotifier<String?>(null);

// Selected columnist author filter (null = all columnists)
final ValueNotifier<String?> selectedColumnistNotifier =
    ValueNotifier<String?>(null);

// Selected news topic filter ('all', 'politics', 'society', 'economy', 'sports', 'culture', 'world')
final ValueNotifier<String> selectedTopicNotifier =
    ValueNotifier<String>('all');

// Active translation language for Top Stories (null = original majority language per story)
final ValueNotifier<String?> overviewTranslateLanguageNotifier =
    ValueNotifier<String?>('en');

// Active sub-mode inside News tab ('top' = Top Stories, 'latest' = Latest News)
final ValueNotifier<String> newsViewModeNotifier = ValueNotifier<String>('top');

// Active sub-mode inside Columnists tab ('top' = Top Columns, 'latest' = Latest Columns)
final ValueNotifier<String> columnistsViewModeNotifier =
    ValueNotifier<String>('top');

// Hidden newspaper feed IDs (lowercase)
final ValueNotifier<Set<String>> hiddenFeedsNotifier =
    ValueNotifier<Set<String>>(<String>{});

// Whether the user dismissed the PWA install banner
final ValueNotifier<bool> installBannerDismissedNotifier =
    ValueNotifier<bool>(false);

String get currentLanguage => languageNotifier.value;
String? get effectiveTranslateLanguage =>
    showOriginalNotifier.value ? null : languageNotifier.value;
bool get isEnglish => languageNotifier.value == 'en';
bool get isGreek => languageNotifier.value == 'el';

String get currentSourceLanguage => sourceLanguageNotifier.value;

String _trElEn(String tr, String el, String en) {
  switch (languageNotifier.value) {
    case 'tr':
      return tr;
    case 'el':
      return el;
    default:
      return en;
  }
}

Future<void> initLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(LANGUAGE_PREF_KEY);
  if (saved == 'en' || saved == 'tr' || saved == 'el') {
    languageNotifier.value = saved!;
  } else {
    languageNotifier.value = 'en';
  }
  showOriginalNotifier.value = false;
  overviewTranslateLanguageNotifier.value = languageNotifier.value;

  final savedSourceLang = prefs.getString(SOURCE_LANGUAGE_PREF_KEY);
  if (savedSourceLang == 'all' ||
      savedSourceLang == 'tr' ||
      savedSourceLang == 'el' ||
      savedSourceLang == 'en') {
    sourceLanguageNotifier.value = savedSourceLang!;
  } else {
    sourceLanguageNotifier.value = 'all';
  }
  final savedHidden = prefs.getStringList(HIDDEN_FEEDS_PREF_KEY);
  if (savedHidden != null) {
    hiddenFeedsNotifier.value =
        savedHidden.map((e) => e.trim().toLowerCase()).toSet();
  } else {
    hiddenFeedsNotifier.value = <String>{};
  }
  installBannerDismissedNotifier.value =
      prefs.getBool(INSTALL_BANNER_DISMISSED_PREF_KEY) ?? false;
}

Future<void> dismissInstallBanner() async {
  installBannerDismissedNotifier.value = true;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(INSTALL_BANNER_DISMISSED_PREF_KEY, true);
}

Future<void> setLanguage(String lang) async {
  if (lang == 'original') {
    await setShowOriginal(true);
    return;
  }
  if (lang != 'tr' && lang != 'en' && lang != 'el') return;
  languageNotifier.value = lang;
  showOriginalNotifier.value = false;
  overviewTranslateLanguageNotifier.value = lang;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(LANGUAGE_PREF_KEY, lang);
  await prefs.setBool(SHOW_ORIGINAL_PREF_KEY, false);
}

Future<void> setShowOriginal(bool showOriginal) async {
  showOriginalNotifier.value = showOriginal;
  overviewTranslateLanguageNotifier.value =
      showOriginal ? null : languageNotifier.value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(SHOW_ORIGINAL_PREF_KEY, showOriginal);
}

Future<void> setSourceLanguage(String lang) async {
  if (lang != 'all' && lang != 'tr' && lang != 'el' && lang != 'en') return;
  sourceLanguageNotifier.value = lang;
  selectedFeedIdNotifier.value = null;
  if (lang == 'all') {
    selectedTopicNotifier.value = 'all';
    selectedColumnistNotifier.value = null;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(SOURCE_LANGUAGE_PREF_KEY, lang);
}

String get LOADING_MORE => _trElEn(
      "Daha fazlası yükleniyor...",
      "Φόρτωση περισσότερων...",
      "Loading more...",
    );

void setSelectedFeedId(String? feedId) {
  if (feedId == null || feedId.trim().isEmpty || feedId == 'all') {
    selectedFeedIdNotifier.value = null;
  } else {
    selectedFeedIdNotifier.value = feedId.trim().toLowerCase();
  }
}

void selectNewspaperFilter(
  String? feedId, {
  bool isColumnist = false,
  bool toggleIfSame = false,
}) {
  if (feedId == null || feedId.trim().isEmpty) return;
  final normalized = feedId.trim().toLowerCase();
  if (toggleIfSame && selectedFeedIdNotifier.value == normalized) {
    selectedFeedIdNotifier.value = null;
    return;
  }
  final currentSourceLang = sourceLanguageNotifier.value;
  if (currentSourceLang != 'all' &&
      resolveFeedLanguage(normalized, null) != currentSourceLang) {
    sourceLanguageNotifier.value = 'all';
  }
  selectedTopicNotifier.value = 'all';
  selectedFeedIdNotifier.value = normalized;
  if (isColumnist) {
    columnistsViewModeNotifier.value = 'latest';
  } else {
    newsViewModeNotifier.value = 'latest';
  }
}

void setSelectedColumnist(String? author) {
  if (author == null || author.trim().isEmpty || author == 'all') {
    selectedColumnistNotifier.value = null;
  } else {
    selectedColumnistNotifier.value = author.trim();
  }
}

const List<String> TOPIC_CODES = <String>[
  'all',
  'politics',
  'society',
  'economy',
  'sports',
  'culture',
  'world',
];

void setSelectedTopic(String? topic) {
  if (topic == null || topic.trim().isEmpty || topic == 'all') {
    selectedTopicNotifier.value = 'all';
    return;
  }
  final normalized = normalizeTopic(topic);
  selectedTopicNotifier.value = normalized ?? 'all';
}

String? normalizeTopic(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final norm = raw.trim().toLowerCase();
  switch (norm) {
    case 'politics':
    case 'siyaset':
    case 'politika':
    case 'πολιτική':
    case 'πολιτικη':
      return 'politics';
    case 'society':
    case 'toplum':
    case 'asayiş':
    case 'asayis':
    case 'κοινωνία':
    case 'κοινωνια':
    case 'local':
      return 'society';
    case 'economy':
    case 'ekonomi':
    case 'business':
    case 'finance':
    case 'οικονομία':
    case 'οικονομια':
      return 'economy';
    case 'sports':
    case 'sport':
    case 'spor':
    case 'αθλητισμός':
    case 'αθλητισμος':
    case 'αθλητικά':
      return 'sports';
    case 'culture':
    case 'culture & life':
    case 'lifestyle':
    case 'kültür':
    case 'yaşam':
    case 'πολιτισμός':
      return 'culture';
    case 'world':
    case 'dünya':
    case 'dunya':
    case 'international':
    case 'κόσμος':
    case 'διεθνή':
      return 'world';
    default:
      return null;
  }
}

final RegExp _topicSportsRegex = RegExp(
  r'(αθλητ|ποδόσφαιρ|μπάσκετ|καλαθόσφαιρ|τένις|ράλλυ|ομόνοια|αποελ|απόλλων|ανόρθωσ|\bαεκ\b|ολυμπιακ|παναθηναϊκ|\bπαοκ\b|ρεάλ|τσίτσιπας|πρωτάθλημ|γήπεδ|προπονητ|διαιτητ|κύπελλ|\bspor\b|futbol|basketbol|voleybol|tenis|ralli|\bmaç\b|\bmaçı\b|şampiyon|turnuva|stadyum|hakem|transfer|antrenör|fenerbahçe|galatasaray|beşiktaş|trabzonspor|ktff|çetinkaya|\bsport|\bfootball|basketball|tennis|rally|\bf1\b|hamilton|omonia|apoel|apollon|anorthosis|pafos\s+fc|olympiacos|panathinaikos|champions\s+league|euroleague|uefa|fifa)',
  caseSensitive: false,
);

final RegExp _topicCultureRegex = RegExp(
  r'(πολιτισμ|μουσικ|συναυλ|τραγουδ|ταινί|κινηματογράφ|θέατρ|ηθοποι|\bσειρές\b|φεστιβάλ|\bτέχνη|\bτέχνες|έκθεσ|μουσεί|βιβλί|μόδα|γαστρονομ|αρχαιολογ|βίσση|αργυρ|μόνροε|ουίλιαμ|kültür|sanat|müzik|konser|şarkı|\bfilm\b|sinema|tiyatro|oyuncu|\bdizi(si|ler|de)?\b|festival|sergi|müze|kitap|edebiyat|şiir|\bmoda\b|magazin|mutfak|gastronomi|arkeoloji|stranger\s+things|culture|music|concert|movie|cinema|theatre|actor|actress|netflix|\bart\b|exhibition|museum|book|fashion|celebrity|lifestyle|cuisine)',
  caseSensitive: false,
);

final RegExp _topicEconomyRegex = RegExp(
  r'(οικονομ|τράπεζ|πληθωρισμ|επιτόκι|φορολογ|\bφπα\b|επενδ|εμπόρι|ενέργει|ηλεκτρ|ηλεκτροκίνησ|φωτοβολταϊκ|τουρισμ|ξενοδοχ|εταιρ|επιχειρήσ|ακίνητ|ενοίκι|προϋπολογισμ|μισθ|σύνταξ|ανεργί|χρηματιστήρι|κεβε|οεβ|ekonom|banka|tcmb|\bfaiz|enflasyon|vergi|\bkdv\b|yatırım|ticaret|enerji|elektrik|kıb-tek|turizm|\botel|şirket|iş\s+dünyası|gayrimenkul|emlak|konut|\bkira\b|bütçe|maaş|asgari\s+ücret|emekli|işsizlik|borsa|döviz|sterlin|ihale|ktto|econom|eurostat|gini|\bbank|inflation|\btax|invest|trade|energy|solar|electricity|tourism|hotel|business|company|property|real\s+estate|budget|salary|wage|pension)',
  caseSensitive: false,
);

final RegExp _topicSocietyRegex = RegExp(
  r'(αστυνομ|δικαστ|κακουργιοδικ|ισόβι|ποιν|φυλακ|δολοφον|φόνο|ληστεί|κλοπ|χειροπέδες|σύλληψ|καταζητ|ναρκωτικ|κάνναβ|τελωνεί|τροχαίο|ατύχημ|δυστύχημ|πυρκαγι|πυροσβεστικ|νοσοκομ|υγεία|γιατρ|ασθεν|γεσυ|οκυπυ|σχολ|μαθητ|εκπαιδευτικ|δάσκαλ|καθηγητ|πανεπιστήμι|παιδεί|απεργία|συνδικαλ|ποεδ|οελμεκ|\bπεο\b|δήμο|δήμαρχ|αφαλάτωσ|αποχέτευσ|ανακύκλωσ|περιβάλλον|δασ|αγριν|φώκια|καιρ|κακοκαιρί|σεισμ|ναυάγι|polis|mahkeme|yüksek\s+mahkeme|ağır\s+ceza|yargıç|\bdava\b|hapis|cezaevi|cinayet|katil|soygun|hırsız|tutukl|zanlı|uyuşturucu|kaza|trafik|yangın|itfaiye|hastane|sağlık|doktor|hemşire|hasta|okul|öğrenci|öğretmen|üniversite|eğitim|grev|sendika|ktös|ktoeös|ktams|belediye|arıtma|çevre|orman|yağmur|fırtına|deprem|gemi\s+kazası|kayıp|soruşturma|police|court|murder|arrest|prison|cannabis|drug|hospital|health|school|education|strike|traffic|accident|fire|wildlife|seal|mouflon|municipality|water|desalination|shipwreck)',
  caseSensitive: false,
);

final RegExp _topicPoliticsRegex = RegExp(
  r'(πρόεδρ|πρωθυπουργ|υπουργ|κυβέρνησ|υπουργικό|βουλ|βουλευτ|κόμμα|εκλογ|υποψήφι|κάλπ|συμπολίτευσ|αντιπολίτευσ|\bοηε\b|νεκρή\s+ζώνη|οδόφραγμ|δικοινοτικ|κυπριακ|διαπραγματεύσ|ομοσπονδ|χριστοδουλίδ|ερχιουρμάν|τατάρ|αναστασιάδ|αννίτα|ακελ|δησυ|δικο|εδεκ|ελαμ|δηπα|διπλωματ|πρέσβ|\bαοζ\b|navtex|cumhurbaşkan|başbakan|bakan|bakanlık|hükümet|kabine|meclis|milletvekili|parti|seçim|aday|sandık|kurultay|koalisyon|muhalefet|\bbm\b|ara\s+bölge|sınır\s+kapısı|iki\s+toplumlu|kıbrıs\s+sorunu|müzakere|federasyon|iki\s+devlet|erhürman|erhurman|tatar|üstel|hristodulidis|\bubp\b|\bctp\b|\bydp\b|\btdp\b|\bhp\b|diplomat|büyükelçi|dışişleri|christodoulides|parliament|president|minister|government|election|unficyp|green\s+line|buffer\s+zone|bicommunal|cyprus\s+problem)',
  caseSensitive: false,
);

final RegExp _cyprusGeoRegex = RegExp(
  r'(κύπρ|κυπριακ|λευκωσί|λεμεσ|λάρνακ|πάφο|αμμόχωστ|κερύνει|μόρφου|πύλα|παραλίμν|αγία\s+νάπα|τρόοδος|ακάμα|χριστοδουλίδ|ερχιουρμάν|τατάρ|αναστασιάδ|ακελ|δησυ|δηκο|ελαμ|εδεκ|δηπα|προεδρικό|κατεχόμεν|ψευδοκράτ|νεκρή\s+ζώνη|οδόφραγμ|οδοφράγματ|δικοινοτικ|τουρκοκύπρι|ελληνοκύπρι|γεσυ|οκυπυ|κεβε|οεβ|ποεδ|οελμεκ|kıbrıs|kibris|kktc|lefkoşa|lefkosa|girne|mağusa|magusa|gazimağusa|güzelyurt|iskele|lefke|mesarya|dipkarpaz|karpaz|maraş|pile|limasol|larnaka|\bbaf\b|güney\s+kıbrıs|kuzey\s+kıbrıs|\brum\b|rumlar|erhürman|erhurman|\btatar\b|üstel|hristodulidis|\bubp\b|\bctp\b|\bydp\b|\btdp\b|ara\s+bölge|sınır\s+kapısı|iki\s+toplumlu|kıb-tek|ktto|ktams|ktoeös|ktös|ercan\s+havalimanı|cyprus|cypriot|nicosia|limassol|larnaca|paphos|famagusta|kyrenia|morphou|\bpyla\b|buffer\s+zone|green\s+line|unficyp|trnc|bicommunal|christodoulides|troodos|akamas|ayia\s+napa|protaras|karpass)',
  caseSensitive: false,
);

final RegExp _topicWorldRegex = RegExp(
  r'(ουκραν|ρωσ|μόσχα|κρεμλίν|ζελένσκι|πούτιν|γάζα|παλαιστιν|δυτική\s+όχθη|χαμάς|χεζμπολάχ|τεχεράν|πεντάγων|τραμπ|μπάιντεν|μακρόν|ισραήλ|ιράν|γαλλία|παρίσι|ισπανία|βρετανία|λονδίνο|\bηπα\b|ουάσιγκτον|κίνα|πεκίνο|γερμανί|βερολίνο|ιταλί|ρώμη|λιβάν|βυρητ|συρία|δαμασκ|αιγυπτ|κάιρο|ευρωπαϊκή\s+ένωση|βρυξέλλες|\bνατο\b|ελλάδ|αθήνα|θεσσαλονίκ|μητσοτάκ|τουρκί|άγκυρα|κωνσταντινούπολ|ερντογάν|ukrayna|rusya|moskova|kremlin|zelenski|putin|gazze|filistin|batı\s+şeria|hamas|hizbullah|tahran|pentagon|beyaz\s+saray|trump|biden|macron|israil|\biran\b|fransa|ispanya|ingiltere|londra|\babd\b|vaşington|washington|\bçin\b|pekin|almanya|berlin|italya|roma|lübnan|beyrut|suriye|şam|mısır|kahire|avrupa\s+birliği|brüksel|\bnato\b|yunanistan|atina|selanik|miçotakis|türkiye|ankara|istanbul|erdoğan|erdogan|ukraine|russia|moscow|zelensky|gaza|palestin|west\s+bank|israel|tehran|lebanon|beirut|syria|damascus|egypt|cairo|france|paris|spain|britain|united\s+kingdom|london|\busa\b|united\s+states|white\s+house|china|beijing|germany|berlin|italy|rome|brussels|\bnato\b|greece|athens|mitsotakis|turkey|ankara|istanbul|world|international|global)',
  caseSensitive: false,
);

bool isCyprusFocusedText(String text) {
  return _cyprusGeoRegex.hasMatch(text);
}

String resolveTopic(
  String? explicitTopic, {
  String? title,
  String? summary,
  String? detail,
  String? url,
}) {
  final safeTitle = title ?? '';
  final safeSummary = summary ?? '';
  final safeDetail = (detail != null && detail.length > 600)
      ? detail.substring(0, 600)
      : (detail ?? '');
  final safeUrl = url ?? '';
  final combined = '$safeTitle $safeSummary $safeDetail $safeUrl';
  final hasCyprus = _cyprusGeoRegex.hasMatch(combined);
  final hasWorld = _topicWorldRegex.hasMatch(combined);

  final direct = normalizeTopic(explicitTopic);
  if (direct != null) {
    if (direct == 'world') return 'world';
    // If an article/story has no Cyprus reference at all and strongly matches
    // international/world actors or countries (while not being sports/culture),
    // classify it as 'world' even if it was generically tagged 'politics' or 'society'.
    if ((direct == 'politics' || direct == 'society') &&
        !hasCyprus &&
        hasWorld &&
        !_topicSportsRegex.hasMatch(safeTitle) &&
        !_topicCultureRegex.hasMatch(safeTitle)) {
      return 'world';
    }
    return direct;
  }

  int scoreFor(RegExp rx) =>
      rx.allMatches(safeTitle).length * 3 +
      rx.allMatches(safeSummary).length * 2 +
      rx.allMatches(safeDetail).length +
      rx.allMatches(safeUrl).length * 2;

  var worldScore = scoreFor(_topicWorldRegex);
  if (!hasCyprus && worldScore > 0) {
    worldScore += 6;
  } else if (hasCyprus && worldScore > 0) {
    worldScore = (worldScore - 4).clamp(0, 999);
  }

  final candidates = <(String, int)>[
    ('sports', scoreFor(_topicSportsRegex)),
    ('economy', scoreFor(_topicEconomyRegex)),
    ('culture', scoreFor(_topicCultureRegex)),
    ('society', scoreFor(_topicSocietyRegex)),
    ('politics', scoreFor(_topicPoliticsRegex)),
    ('world', worldScore),
  ];

  var bestTopic = 'society';
  var bestScore = 0;
  for (final entry in candidates) {
    if (entry.$2 > bestScore) {
      bestScore = entry.$2;
      bestTopic = entry.$1;
    }
  }
  return bestTopic;
}

bool matchesSelectedTopic(String resolvedTopic) {
  final active = selectedTopicNotifier.value;
  if (active == 'all') return true;
  return resolvedTopic == active;
}

String topicLabelFor(String topicCode) {
  switch (topicCode.trim().toLowerCase()) {
    case 'politics':
      return _trElEn("Siyaset", "Πολιτική", "Politics");
    case 'society':
      return _trElEn("Toplum", "Κοινωνία", "Society");
    case 'economy':
      return _trElEn("Ekonomi", "Οικονομία", "Economy");
    case 'sports':
      return _trElEn("Spor", "Αθλητισμός", "Sports");
    case 'culture':
      return _trElEn("Kültür & Yaşam", "Πολιτισμός & Ζωή", "Culture & Life");
    case 'world':
      return _trElEn("Dünya", "Κόσμος", "World");
    default:
      return _trElEn("Tüm Konular", "Όλα τα Θέματα", "All Topics");
  }
}

String topicShortLabelFor(String topicCode) {
  switch (topicCode.trim().toLowerCase()) {
    case 'politics':
      return _trElEn("Siyaset", "Πολιτική", "Politics");
    case 'society':
      return _trElEn("Toplum", "Κοινωνία", "Society");
    case 'economy':
      return _trElEn("Ekonomi", "Οικονομία", "Economy");
    case 'sports':
      return _trElEn("Spor", "Αθλητικά", "Sports");
    case 'culture':
      return _trElEn("Kültür", "Πολιτισμός", "Culture");
    case 'world':
      return _trElEn("Dünya", "Κόσμος", "World");
    default:
      return _trElEn("Tüm Konular", "Όλα τα Θέματα", "All Topics");
  }
}

void setOverviewTranslateLanguage(String? lang) {
  if (lang == null || lang == 'original' || lang.trim().isEmpty) {
    showOriginalNotifier.value = true;
    overviewTranslateLanguageNotifier.value = null;
  } else if (lang == 'el' || lang == 'tr' || lang == 'en') {
    languageNotifier.value = lang;
    showOriginalNotifier.value = false;
    overviewTranslateLanguageNotifier.value = lang;
  }
}

bool isFeedVisible(String? feedId) {
  if (feedId == null || feedId.trim().isEmpty) return true;
  return !hiddenFeedsNotifier.value.contains(feedId.trim().toLowerCase());
}

Future<void> setFeedVisible(String feedId, bool visible) async {
  final normalized = feedId.trim().toLowerCase();
  final updated = Set<String>.from(hiddenFeedsNotifier.value);
  if (visible) {
    updated.remove(normalized);
  } else {
    updated.add(normalized);
    if (selectedFeedIdNotifier.value == normalized) {
      selectedFeedIdNotifier.value = null;
    }
  }
  hiddenFeedsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(HIDDEN_FEEDS_PREF_KEY, updated.toList());
}

Future<void> setAllFeedsVisible(Iterable<String> feedIds, bool visible) async {
  final updated = Set<String>.from(hiddenFeedsNotifier.value);
  for (final id in feedIds) {
    final normalized = id.trim().toLowerCase();
    if (visible) {
      updated.remove(normalized);
    } else {
      updated.add(normalized);
    }
  }
  hiddenFeedsNotifier.value = updated;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(HIDDEN_FEEDS_PREF_KEY, updated.toList());
}

const Map<String, String> _knownFeedLanguages = {
  'alphanews': 'el',
  'bagimsiz': 'tr',
  'bugunkibris': 'tr',
  'cyprusmail': 'en',
  'cyprustoday': 'en',
  'detaykibris': 'tr',
  'dialogos': 'el',
  'diyalog': 'tr',
  'financialmirror': 'en',
  'gazeddakibris': 'tr',
  'giynik': 'tr',
  'gundemkibris': 'tr',
  'guneskibris': 'tr',
  'haberalkibrisli': 'tr',
  'halkinsesi': 'tr',
  'havadis': 'tr',
  'kibrisgazetesi': 'tr',
  'kibrisgenctv': 'tr',
  'kibrisgercek': 'tr',
  'kibrismanset': 'tr',
  'kibrisobjektif': 'tr',
  'kibristime': 'tr',
  'lemesos': 'el',
  'londragazete': 'tr',
  'pafospress': 'el',
  'philenews': 'el',
  'politis': 'el',
  'politisen': 'en',
  'sigmalive': 'el',
  'tothemaonline': 'el',
  'tvine': 'en',
  'vatan': 'tr',
  'yenicag': 'tr',
  'yeniduzen': 'tr',
};

String resolveFeedLanguage(String? feedId, String? explicitLanguage) {
  if (explicitLanguage != null && explicitLanguage.trim().isNotEmpty) {
    return explicitLanguage.trim().toLowerCase();
  }
  if (feedId != null && feedId.trim().isNotEmpty) {
    return _knownFeedLanguages[feedId.trim().toLowerCase()] ?? 'tr';
  }
  return 'tr';
}

bool matchesSourceLanguageOnly(String? feedId, String? explicitLanguage) {
  if (!isFeedVisible(feedId)) return false;
  final filter = sourceLanguageNotifier.value;
  if (filter == 'all') return true;
  return resolveFeedLanguage(feedId, explicitLanguage) == filter;
}

bool matchesSourceLanguage(String? feedId, String? explicitLanguage) {
  if (!matchesSourceLanguageOnly(feedId, explicitLanguage)) return false;
  final selectedFeed = selectedFeedIdNotifier.value;
  if (selectedFeed == null) return true;
  if (feedId == null || feedId.trim().isEmpty) return false;
  return feedId.trim().toLowerCase() == selectedFeed;
}

List<String> targetTranslationLanguagesFor(String sourceLang) {
  switch (sourceLang.toLowerCase()) {
    case 'el':
      return const ['tr', 'en'];
    case 'tr':
      return const ['el', 'en'];
    case 'en':
      return const ['el', 'tr'];
    default:
      return const ['el', 'tr', 'en'];
  }
}

String languageLabelFor(String langCode) {
  switch (langCode.toLowerCase()) {
    case 'tr':
      return 'Türkçe';
    case 'el':
      return 'Ελληνικά';
    case 'en':
      return 'English';
    default:
      return langCode.toUpperCase();
  }
}

// localized app strings
String get APP_NAME => _trElEn(
      "Kıbrıs İki Toplumlu Haberler",
      "Δικοινοτικές Ειδήσεις Κύπρου",
      "Cyprus Bicommunal News",
    );
String get APP_SUBTITLE => _trElEn(
      "Kıbrıs genelinden günlük haberler",
      "Καθημερινές ειδήσεις από όλη την Κύπρο",
      "Daily news all across Cyprus",
    );

// source language filter labels
String get SOURCES_BAR_LABEL =>
    _trElEn("Kaynaklar:", "Πηγές:", "Sources:");
String get READ_IN_LABEL =>
    _trElEn("Dilde oku:", "Ανάγνωση σε:", "Read in:");
String get READ_IN_BUTTON =>
    _trElEn("Dilde oku", "Ανάγνωση σε", "Read in");
String get SOURCE_BADGE_LABEL => _trElEn("Kaynak", "Πηγή", "Source");
String get TRANSLATED_BADGE_LABEL =>
    _trElEn("Çeviri", "Μετάφραση", "Translated");
String get TRANSLATE_TO_LABEL => READ_IN_LABEL;
String get SOURCE_FILTER_ALL => _trElEn(
      "Tüm Kaynaklar",
      "Όλες οι Πηγές",
      "All Sources",
    );
String get FILTER_SHEET_TITLE => _trElEn(
      "Kaynak ve Konu Filtresi",
      "Φίλτρο Πηγών & Θεμάτων",
      "Filter Sources & Topics",
    );
String get RESET_FILTERS => _trElEn(
      "Sıfırla",
      "Επαναφορά",
      "Reset",
    );
String get DONE_BUTTON => _trElEn(
      "Tamam",
      "Τέλος",
      "Done",
    );
String get TOPICS_SECTION_TITLE => _trElEn(
      "Konular",
      "Θέματα",
      "Topics",
    );
String get TOP_COLUMNS_SHORT => _trElEn(
      "Öne Çıkan",
      "Κυριότερα",
      "Top",
    );
String get LATEST_COLUMNS_SHORT => _trElEn(
      "Tümü",
      "Όλα",
      "All",
    );
String get ALL_NEWSPAPERS => _trElEn(
      "Tüm Gazeteler",
      "Όλες οι Εφημερίδες",
      "All Newspapers",
    );
String get SOURCE_FILTER_TR => _trElEn("Türkçe", "Τουρκικά", "Turkish");
String get SOURCE_FILTER_EL => _trElEn("Yunanca", "Ελληνικά", "Greek");
String get SOURCE_FILTER_EN => _trElEn("İngilizce", "Αγγλικά", "English");

String sourceFilterTooltipFor(String code) {
  switch (code.trim().toLowerCase()) {
    case 'el':
      return _trElEn(
        "Kıbrıs Rum gazeteleri",
        "Ελληνοκυπριακές εφημερίδες",
        "Greek Cypriot newspapers",
      );
    case 'tr':
      return _trElEn(
        "Kıbrıs Türk gazeteleri",
        "Τουρκοκυπριακές εφημερίδες",
        "Turkish Cypriot newspapers",
      );
    case 'en':
      return _trElEn(
        "Kıbrıs'taki İngilizce gazeteler",
        "Αγγλόφωνες εφημερίδες στην Κύπρο",
        "English newspapers in Cyprus",
      );
    default:
      return _trElEn(
        "Tüm Kıbrıs Rum ve Türk gazeteleri",
        "Όλες οι ελληνοκυπριακές και τουρκοκυπριακές εφημερίδες",
        "All Greek and Turkish Cypriot newspapers",
      );
  }
}
String get SOURCE_LANGUAGE_TITLE => _trElEn(
      "Haber Kaynağı Dili",
      "Γλώσσα Πηγών Ειδήσεων",
      "News Source Language",
    );
String get SOURCE_LANGUAGE_SUBTITLE => _trElEn(
      "Görüntülemek istediğiniz haber kaynaklarının dilini seçin",
      "Επιλέξτε τη γλώσσα των πηγών ειδήσεων που θέλετε να βλέπετε",
      "Filter news sources by Turkish, Greek, or English",
    );

// drawer & navigation
String get NEWS => _trElEn("Haberler", "Ειδήσεις", "News");
String get OVERVIEW => _trElEn(
      "Öne Çıkan Haberler",
      "Κυριότερες Ειδήσεις",
      "Top Stories",
    );
String get TOP_COLUMNS => _trElEn(
      "Öne Çıkan Köşe Yazıları",
      "Κυριότερα Άρθρα Γνώμης",
      "Top Columns",
    );
String get LATEST_COLUMNS => _trElEn(
      "Tüm Köşe Yazıları",
      "Όλα τα Άρθρα Γνώμης",
      "All Columns",
    );
String get HAVE_FEEDBACK => _trElEn(
      "Geri bildirim?",
      "Σχόλια;",
      "Have feedback?",
    );
String get TOP_STORIES_TITLE => OVERVIEW;
String get READ_FROM_LABEL => _trElEn(
      "Kaynağından oku:",
      "Διαβάστε από:",
      "Read from:",
    );
String get COVERED_BY => _trElEn(
      "Haberi Yapan Gazeteler",
      "Κάλυψη από Εφημερίδες",
      "Covered by Newspapers",
    );
String get OVERVIEW_LOADING => _trElEn(
      "Haberler analiz ediliyor ve günün özeti hazırlanıyor...",
      "Ανάλυση ειδήσεων και προετοιμασία της επισκόπησης...",
      "Analyzing news and preparing today's overview...",
    );
String get OVERVIEW_EMPTY => _trElEn(
      "Günün özeti henüz hazır değil.",
      "Η επισκόπηση δεν είναι ακόμη διαθέσιμη.",
      "Today's overview is not available yet.",
    );

String podcastEditionTitleFor(
  String edition,
  String lang, {
  bool isColumnists = false,
}) {
  final normEdition = edition.trim().toLowerCase();
  switch (lang.trim().toLowerCase()) {
    case 'el':
      if (normEdition == 'morning') {
        return 'Δικοινοτικές Ειδήσεις Κύπρου - Πρωί';
      }
      if (normEdition == 'midday') {
        return 'Δικοινοτικές Ειδήσεις Κύπρου - Μεσημέρι';
      }
      return 'Δικοινοτικές Ειδήσεις Κύπρου - Βράδυ';
    case 'tr':
      if (normEdition == 'morning') {
        return 'Kıbrıs İki Toplumlu Haberler - Sabah';
      }
      if (normEdition == 'midday') {
        return 'Kıbrıs İki Toplumlu Haberler - Öğle';
      }
      return 'Kıbrıs İki Toplumlu Haberler - Akşam';
    default:
      if (normEdition == 'morning') {
        return 'Cyprus Bicommunal News - Morning';
      }
      if (normEdition == 'midday') {
        return 'Cyprus Bicommunal News - Mid-Day';
      }
      return 'Cyprus Bicommunal News - Evening';
  }
}

String podcastEditionShortLabelFor(String edition, String lang) {
  final normEdition = edition.trim().toLowerCase();
  switch (lang.trim().toLowerCase()) {
    case 'el':
      if (normEdition == 'morning') return 'Πρωί';
      if (normEdition == 'midday') return 'Μεσημέρι';
      return 'Βράδυ';
    case 'tr':
      if (normEdition == 'morning') return 'Sabah';
      if (normEdition == 'midday') return 'Öğle';
      return 'Akşam';
    default:
      if (normEdition == 'morning') return 'Morning';
      if (normEdition == 'midday') return 'Mid-Day';
      return 'Evening';
  }
}

String podcastSubtitleFor(String edition, String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'el':
      return '5λεπτη ενημέρωση με τις κυριότερες ειδήσεις κάθε πρωί, μεσημέρι και βράδυ';
    case 'tr':
      return 'Her sabah, öğle ve akşam 5 dakikalık öne çıkan haber özeti';
    default:
      return '5 minute top news update every morning, mid-day and evening';
  }
}

String podcastLastUpdatedLabelFor(String relativeTime, String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'el':
      return 'Ενημερώθηκε $relativeTime';
    case 'tr':
      return 'Son güncelleme: $relativeTime';
    default:
      return 'Updated $relativeTime';
  }
}

String podcastListenButtonFor(String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'el':
      return 'Ακούστε (5 λεπτά)';
    case 'tr':
      return 'Dinle (5 dk)';
    default:
      return 'Listen (5 min)';
  }
}

String podcastPauseButtonFor(String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'el':
      return 'Παύση';
    case 'tr':
      return 'Duraklat';
    default:
      return 'Pause';
  }
}

String podcastResumeButtonFor(String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'el':
      return 'Συνέχεια';
    case 'tr':
      return 'Devam Et';
    default:
      return 'Resume';
  }
}

String podcastScriptToggleFor(bool expanded, String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'el':
      return expanded ? 'Απόκρυψη Διαλόγου' : 'Προβολή Διαλόγου';
    case 'tr':
      return expanded ? 'Diyaloğu Gizle' : 'Diyaloğu Göster';
    default:
      return expanded ? 'Hide Transcript' : 'Show Transcript';
  }
}

String podcastOpenStoryLabelFor(String lang) {
  switch (lang.trim().toLowerCase()) {
    case 'el':
      return 'Άνοιγμα Είδησης';
    case 'tr':
      return 'Haberi Aç';
    default:
      return 'Open Story';
  }
}
String sourcesCountLabel(int count) => _trElEn(
      "$count gazete",
      "$count ${count == 1 ? 'εφημερίδα' : 'εφημερίδες'}",
      "$count ${count == 1 ? 'newspaper' : 'newspapers'}",
    );
String get RECENT_NEWS =>
    _trElEn("Tüm Haberler", "Όλες οι Ειδήσεις", "All News");
String get TOP_STORIES_BANNER => _trElEn(
      "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden yapay zeka ile özetlenen öne çıkan haberler.",
      "Οι κυριότερες ειδήσεις από τουρκοκυπριακές, ελληνοκυπριακές και αγγλόφωνες εφημερίδες της Κύπρου, συνοψισμένες με τεχνητή νοημοσύνη.",
      "Top stories across Turkish, Greek, and English newspapers in Cyprus, summarized by AI.",
    );
String get RECENT_NEWS_BANNER => _trElEn(
      "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden tüm güncel haberler.",
      "Όλες οι ειδήσεις από τουρκοκυπριακές, ελληνοκυπριακές και αγγλόφωνες εφημερίδες της Κύπρου.",
      "All news across Turkish, Greek, and English newspapers in Cyprus.",
    );
String get COLUMNISTS =>
    _trElEn("Köşe Yazarları", "Αρθρογράφοι", "Columnists");
String get TOP_COLUMNS_BANNER => _trElEn(
      "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden öne çıkan köşe yazıları ve görüşler.",
      "Τα κυριότερα άρθρα γνώμης και αρθρογραφία από εφημερίδες όλης της Κύπρου.",
      "Top opinion pieces and columns across Turkish, Greek, and English newspapers in Cyprus.",
    );
String get COLUMNISTS_BANNER => _trElEn(
      "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden tüm köşe yazıları ve görüşler.",
      "Όλα τα άρθρα γνώμης και αρθρογραφία από εφημερίδες όλης της Κύπρου.",
      "All opinion pieces and columns across Turkish, Greek, and English newspapers in Cyprus.",
    );
String get ALL_COLUMNISTS => _trElEn(
      "Tüm Yazarlar",
      "Όλοι οι Αρθρογράφοι",
      "All Columnists",
    );
String get COLUMNIST_BADGE_FALLBACK =>
    _trElEn("Köşe Yazısı", "Άποψη", "Opinion");
String get NEWSPAPERS => _trElEn("Gazeteler", "Εφημερίδες", "Newspapers");
String get ALL_NEWS => NEWSPAPERS;
String get SETTINGS => _trElEn("Ayarlar", "Ρυθμίσεις", "Settings");
String get CONTACT => _trElEn(
      "Hakkında & İletişim",
      "Σχετικά & Επικοινωνία",
      "About & Contact",
    );
String get ABOUT_TITLE => _trElEn(
      "Bu Uygulamayı Neden Yaptım?",
      "Γιατί Δημιούργησα Αυτή την Εφαρμογή",
      "Why I Built This App",
    );
String get ABOUT_BODY => _trElEn(
      "İnsanları her iki toplumun gazetelerini okumaya teşvik ederek Kıbrıs genelinde daha iyi bir anlayış, birlik ve uyuma katkıda bulunmak amacıyla geliştirilmiştir.",
      "Δημιουργήθηκε για να συμβάλει στην καλύτερη αλληλοκατανόηση, την ενότητα και την αρμονία σε όλη την Κύπρο, ενθαρρύνοντας τους ανθρώπους να διαβάζουν εφημερίδες και από τις δύο κοινότητες.",
      "Built to contribute to better understanding, unity, and harmony across Cyprus by encouraging people to read newspapers across the divide.",
    );
String get INSTALL_APP_TITLE => _trElEn(
      "Uygulamayı Yükle",
      "Εγκατάσταση Εφαρμογής",
      "Install App",
    );
String get INSTALL_APP_BANNER_TITLE => _trElEn(
      "Kıbrıs İki Toplumlu Haberler'i Yükleyin",
      "Εγκαταστήστε τις Δικοινοτικές Ειδήσεις Κύπρου",
      "Install Cyprus Bicommunal News",
    );
String get INSTALL_APP_BANNER_SUBTITLE => _trElEn(
      "Tek dokunuşla hızlı ve tam ekran erişim için ana ekranınıza ekleyin",
      "Προσθέστε στην αρχική οθόνη για γρήγορη πρόσβαση σε πλήρη οθόνη",
      "Add to your home screen or desktop for quick, full-screen access",
    );
String get INSTALL_APP_BUTTON => _trElEn(
      "Yükle",
      "Εγκατάσταση",
      "Install",
    );
String get INSTALL_IOS_STEP_1 => _trElEn(
      "Tarayıcı araç çubuğundaki Paylaş (⬆️) düğmesine dokunun.",
      "Πατήστε το κουμπί Κοινοποίηση (⬆️) στη γραμμή εργαλείων του Safari.",
      "Tap the Share (⬆️) button in your browser toolbar.",
    );
String get INSTALL_IOS_STEP_2 => _trElEn(
      "Aşağı kaydırıp \"Ana Ekrana Ekle\" (➕) seçeneğine dokunun.",
      "Κυλίστε προς τα κάτω και επιλέξτε «Προσθήκη στην οθόνη Αφετηρίας» (➕).",
      "Scroll down and tap \"Add to Home Screen\" (➕).",
    );
String get INSTALL_IOS_STEP_3 => _trElEn(
      "Sağ üst köşedeki \"Ekle\" düğmesine dokunun.",
      "Πατήστε «Προσθήκη» στην επάνω δεξιά γωνία.",
      "Tap \"Add\" in the top-right corner.",
    );
String get INSTALL_BROWSER_STEP_1 => _trElEn(
      "Adres çubuğundaki Yükle simgesine (📲) veya tarayıcı menüsüne (⋮) tıklayın.",
      "Κάντε κλικ στο εικονίδιο εγκατάστασης (📲) στη γραμμή διευθύνσεων ή στο μενού (⋮).",
      "Click the Install icon (📲) in the address bar or open the browser menu (⋮).",
    );
String get INSTALL_BROWSER_STEP_2 => _trElEn(
      "\"Uygulamayı Yükle\" veya \"Ana Ekrana / Dock'a Ekle\" seçeneğini seçin.",
      "Επιλέξτε «Εγκατάσταση εφαρμογής» ή «Προσθήκη στην αρχική οθόνη / Dock».",
      "Select \"Install App\" or \"Add to Home Screen / Dock\".",
    );
String get GOT_IT_BUTTON => _trElEn(
      "Anladım",
      "Εντάξει",
      "Got it",
    );
String get OFFLINE_BANNER_TEXT => _trElEn(
      "Çevrimdışı mod — önbellekteki haberler ve podcast gösteriliyor",
      "Εκτός σύνδεσης — εμφάνιση αποθηκευμένων ειδήσεων και podcast",
      "Offline mode — showing cached news & podcast",
    );

// settings_view
String get LANGUAGE_TITLE =>
    _trElEn("Uygulama Dili", "Γλώσσα Εφαρμογής", "App Language");
String get LANGUAGE_SUBTITLE => _trElEn(
      "Uygulama arayüz dilini Türkçe, Yunanca veya İngilizce olarak değiştirin",
      "Αλλάξτε τη γλώσσα της εφαρμογής σε Τουρκικά, Ελληνικά ή Αγγλικά",
      "Switch the app interface between Turkish, Greek, and English",
    );
String get REORDER_NEWS => _trElEn(
      "Gazeteleri Sırala ve Gizle",
      "Σειρά & Απόκρυψη Εφημερίδων",
      "Reorder & Hide Newspapers",
    );
String get REORDER_HINT => _trElEn(
      "Gazete filtre çubuğundaki sıralamayı değiştirmek için sürükleyin. Gizlenen gazeteler haber listelerinde gösterilmez.",
      "Σύρετε για αλλαγή σειράς στη γραμμή φίλτρου εφημερίδων. Οι κρυμμένες εφημερίδες δεν εμφανίζονται στις ειδήσεις.",
      "Drag to reorder newspapers in the filter bar. Hidden newspapers are excluded from Top Stories and All News.",
    );

// feeditem_view & lists
String get SHARE => _trElEn("Paylaş", "Κοινοποίηση", "Share");
String get TRANSLATE => READ_IN_BUTTON;
String get SHOW_ORIGINAL => _trElEn(
      "Orijinal Dilde Göster",
      "Προβολή στο Πρωτότυπο",
      "Show Original",
    );
String get SHOW_ORIGINAL_SHORT => _trElEn(
      "Orijinal",
      "Πρωτότυπο",
      "Original",
    );
String get TRANSLATING =>
    _trElEn("Çevriliyor...", "Μετάφραση...", "Translating...");
String get TRANSLATE_ERROR => _trElEn(
      "Çeviri yapılamadı",
      "Η μετάφραση απέτυχε",
      "Translation failed",
    );
String get MORE => _trElEn(
      "Orijinal makaleyi oku",
      "Διαβάστε το πρωτότυπο άρθρο",
      "Read original article",
    );
String get LOADING_NEWS => _trElEn(
      "Haberler yükleniyor...",
      "Φόρτωση ειδήσεων...",
      "Loading news...",
    );
String get NO_NEWS_FOUND => _trElEn(
      "Henüz haber bulunamadı.",
      "Δεν βρέθηκαν ειδήσεις.",
      "No news found yet.",
    );

// contact_view
String get CONTACT_INFO => _trElEn(
      "İletişim Bilgileri",
      "Στοιχεία Επικοινωνίας",
      "Contact Information",
    );
String get SEND_MESSAGE => _trElEn(
      "Geri bildiriminiz mi var? Bize mesaj gönderin",
      "Έχετε σχόλια; Στείλτε μας μήνυμα",
      "Have feedback? Send us a message",
    );
String get FIRST_LAST_NAME =>
    _trElEn("İsim Soyisim", "Ονοματεπώνυμο", "Full Name");
String get FEEDBACK => _trElEn(
      "Yorum veya geri bildiriminizi yazın",
      "Γράψτε το σχόλιο ή τα σχόλιά σας",
      "Write your comment or feedback",
    );
String get NO_LEAVE_EMPTY => _trElEn(
      "Lütfen boş bırakmayınız",
      "Παρακαλώ συμπληρώστε το πεδίο",
      "Please do not leave empty",
    );
String get SEND => _trElEn("Gönder", "Αποστολή", "Send");
String get EMAIL_CLIENT_OPENED => _trElEn(
      "E-posta istemcisi açıldı",
      "Άνοιξε η εφαρμογή email",
      "Email client opened",
    );
String get EMAIL_SENT =>
    _trElEn("E-posta gönderildi", "Το email στάλθηκε", "Email sent");
String get EMAIL_ERROR => _trElEn(
      "E-posta göndermede hata",
      "Σφάλμα κατά την αποστολή email",
      "Error sending email",
    );
String get URL_ERROR => _trElEn(
      "Bağlantı açılamadı",
      "Δεν ήταν δυνατό το άνοιγμα του συνδέσμου",
      "Could not open link",
    );

const Set<String> _darkLogoFeedIds = {
  'cyprustoday',
  'detaykibris',
  'gundemkibris',
  'haberalkibrisli',
  'kibrisgazetesi',
  'kibrisgercek',
  'londragazete',
};

bool needsDarkLogoBackground(String? feedId) {
  if (feedId == null) return false;
  return _darkLogoFeedIds.contains(feedId.toLowerCase());
}

String resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return '';
  }
  final trimmed = url.trim();
  if (kIsWeb &&
      (trimmed.startsWith('http://') || trimmed.startsWith('https://')) &&
      !trimmed.contains('/api/v1/imageproxy')) {
    return '$URL_MAIN/imageproxy?url=${Uri.encodeComponent(trimmed)}';
  }
  return trimmed;
}