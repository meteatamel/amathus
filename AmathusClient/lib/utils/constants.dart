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
const String URL_TRANSLATE = "$URL_MAIN/translate";
const String URL_TWITTER = "https://twitter.com/meteatamel";

// files / storage keys
const String FEEDS_FILE = "feeds_v3.json";
const String FEED_ITEMS_RECENT_KEY = "feed_items_recent_v1.json";
const String FEED_ITEMS_COLUMNISTS_KEY = "feed_items_columnists_v1.json";
const String FEED_ITEMS_BY_ID_PREFIX = "feed_items_by_id_v1_";
const String OVERVIEW_STORAGE_KEY = "news_overview_v1.json";
const String LANGUAGE_PREF_KEY = "app_language";
const String SOURCE_LANGUAGE_PREF_KEY = "source_language";
const String HIDDEN_FEEDS_PREF_KEY = "hidden_feeds";

// contact
const String APP_EMAIL = "atameldev@gmail.com";

// UI language state ('tr', 'el', or 'en')
final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

// News source language filter ('all', 'tr', 'el', or 'en')
final ValueNotifier<String> sourceLanguageNotifier =
    ValueNotifier<String>('all');

// Selected newspaper feed ID filter (null = all newspapers)
final ValueNotifier<String?> selectedFeedIdNotifier =
    ValueNotifier<String?>(null);

// Selected columnist author filter (null = all columnists)
final ValueNotifier<String?> selectedColumnistNotifier =
    ValueNotifier<String?>(null);

// Active translation language for Top Stories (null = original majority language per story)
final ValueNotifier<String?> overviewTranslateLanguageNotifier =
    ValueNotifier<String?>(null);

// Hidden newspaper feed IDs (lowercase)
final ValueNotifier<Set<String>> hiddenFeedsNotifier =
    ValueNotifier<Set<String>>(<String>{});

String get currentLanguage => languageNotifier.value;
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
  }
  final savedSourceLang = prefs.getString(SOURCE_LANGUAGE_PREF_KEY);
  if (savedSourceLang == 'all' ||
      savedSourceLang == 'tr' ||
      savedSourceLang == 'el' ||
      savedSourceLang == 'en') {
    sourceLanguageNotifier.value = savedSourceLang!;
  }
  final savedHidden = prefs.getStringList(HIDDEN_FEEDS_PREF_KEY);
  if (savedHidden != null) {
    hiddenFeedsNotifier.value =
        savedHidden.map((e) => e.trim().toLowerCase()).toSet();
  } else {
    hiddenFeedsNotifier.value = <String>{};
  }
}

Future<void> setLanguage(String lang) async {
  if (lang != 'tr' && lang != 'en' && lang != 'el') return;
  languageNotifier.value = lang;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(LANGUAGE_PREF_KEY, lang);
}

Future<void> setSourceLanguage(String lang) async {
  if (lang != 'all' && lang != 'tr' && lang != 'el' && lang != 'en') return;
  sourceLanguageNotifier.value = lang;
  final currentFeed = selectedFeedIdNotifier.value;
  if (currentFeed != null &&
      lang != 'all' &&
      resolveFeedLanguage(currentFeed, null) != lang) {
    selectedFeedIdNotifier.value = null;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(SOURCE_LANGUAGE_PREF_KEY, lang);
}

void setSelectedFeedId(String? feedId) {
  if (feedId == null || feedId.trim().isEmpty || feedId == 'all') {
    selectedFeedIdNotifier.value = null;
  } else {
    selectedFeedIdNotifier.value = feedId.trim().toLowerCase();
  }
}

void setSelectedColumnist(String? author) {
  if (author == null || author.trim().isEmpty || author == 'all') {
    selectedColumnistNotifier.value = null;
  } else {
    selectedColumnistNotifier.value = author.trim();
  }
}

void setOverviewTranslateLanguage(String? lang) {
  if (lang == null || lang == 'original' || lang.trim().isEmpty) {
    overviewTranslateLanguageNotifier.value = null;
  } else if (lang == 'el' || lang == 'tr' || lang == 'en') {
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
      return SOURCE_FILTER_TR;
    case 'el':
      return SOURCE_FILTER_EL;
    case 'en':
      return SOURCE_FILTER_EN;
    default:
      return langCode.toUpperCase();
  }
}

// localized app strings
String get APP_NAME => "Cyprus Bicommunal News";
String get APP_SUBTITLE => _trElEn(
      "Kıbrıs İki Toplumlu Güncel Haber Kaynakları",
      "Δικοινοτικές Πηγές Ειδήσεων από όλη την Κύπρο",
      "Daily Bicommunal News Sources Across Cyprus",
    );

// source language filter labels
String get SOURCES_BAR_LABEL =>
    _trElEn("Kaynaklar:", "Πηγές:", "Sources:");
String get READ_IN_LABEL =>
    _trElEn("Çevir:", "Μετάφραση:", "Translate:");
String get READ_IN_BUTTON =>
    _trElEn("Çevir", "Μετάφραση", "Translate");
String get SOURCE_BADGE_LABEL => _trElEn("Kaynak", "Πηγή", "Source");
String get TRANSLATED_BADGE_LABEL =>
    _trElEn("Çeviri", "Μετάφραση", "Translated");
String get TRANSLATE_TO_LABEL => READ_IN_LABEL;
String get SOURCE_FILTER_ALL => _trElEn("Tümü", "Όλα", "All");
String get ALL_NEWSPAPERS => _trElEn(
      "Tüm Gazeteler",
      "Όλες οι Εφημερίδες",
      "All Newspapers",
    );
String get SOURCE_FILTER_TR => "Türkçe";
String get SOURCE_FILTER_EL => "Ελληνικά";
String get SOURCE_FILTER_EN => "English";
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
String get OVERVIEW => _trElEn(
      "Öne Çıkan Haberler",
      "Κυριότερες Ειδήσεις",
      "Top Stories",
    );
String get TOP_STORIES_TITLE => OVERVIEW;
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
String sourcesCountLabel(int count) => _trElEn(
      "$count gazete",
      "$count ${count == 1 ? 'εφημερίδα' : 'εφημερίδες'}",
      "$count ${count == 1 ? 'newspaper' : 'newspapers'}",
    );
String get RECENT_NEWS =>
    _trElEn("Son Haberler", "Τελευταία Νέα", "Latest News");
String get RECENT_NEWS_BANNER => _trElEn(
      "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden son dakika ve güncel haberler.",
      "Τελευταία νέα από τουρκοκυπριακές, ελληνοκυπριακές και αγγλόφωνες εφημερίδες της Κύπρου.",
      "Latest news across Turkish, Greek, and English newspapers in Cyprus.",
    );
String get COLUMNISTS =>
    _trElEn("Köşe Yazarları", "Αρθρογράφοι", "Columnists");
String get COLUMNISTS_BANNER => _trElEn(
      "Kıbrıs genelindeki Türkçe, Yunanca ve İngilizce gazetelerden güncel köşe yazıları ve görüşler.",
      "Πρόσφατα άρθρα γνώμης και αρθρογραφία από εφημερίδες όλης της Κύπρου.",
      "Latest opinion pieces and columns across Turkish, Greek, and English newspapers in Cyprus.",
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
String get CONTACT => _trElEn("İletişim", "Επικοινωνία", "Contact");

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
      "Drag to reorder newspapers in the filter bar. Hidden newspapers are excluded from Top Stories and Latest News.",
    );

// feeditem_view & lists
String get SHARE => _trElEn("Paylaş", "Κοινοποίηση", "Share");
String get TRANSLATE => _trElEn("Çevir", "Μετάφραση", "Translate");
String get SHOW_ORIGINAL => _trElEn(
      "Orijinal Kaynak",
      "Πρωτότυπη Πηγή",
      "Original Source",
    );
String get TRANSLATING =>
    _trElEn("Çevriliyor...", "Μετάφραση...", "Translating...");
String get TRANSLATE_ERROR => _trElEn(
      "Çeviri yapılamadı",
      "Η μετάφραση απέτυχε",
      "Translation failed",
    );
String get MORE => _trElEn(
      "Haberi Kaynağında Oku",
      "Διαβάστε το πλήρες άρθρο",
      "Read Full Article",
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
      "Bize Mesaj Gönderin",
      "Στείλτε μας Μήνυμα",
      "Send a Message",
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