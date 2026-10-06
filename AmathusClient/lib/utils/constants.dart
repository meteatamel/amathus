import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// urls
const String URL_MAIN =
    "https://amathus-web-1086570528700.europe-west1.run.app/api/v1";
const String URL_FEEDS = "$URL_MAIN/feeds";
const String URL_FEED_ITEMS = "$URL_MAIN/feeditems";
const String URL_TWITTER = "https://twitter.com/meteatamel";

// files / storage keys
const String FEEDS_FILE = "feeds_v3.json";
const String LANGUAGE_PREF_KEY = "app_language";
const String SOURCE_LANGUAGE_PREF_KEY = "source_language";

// contact
const String APP_EMAIL = "atameldev@gmail.com";

// UI language state ('tr', 'el', or 'en')
final ValueNotifier<String> languageNotifier = ValueNotifier<String>('tr');

// News source language filter ('all', 'tr', 'el', or 'en')
final ValueNotifier<String> sourceLanguageNotifier =
    ValueNotifier<String>('all');

String get currentLanguage => languageNotifier.value;
bool get isEnglish => languageNotifier.value == 'en';
bool get isGreek => languageNotifier.value == 'el';

String get currentSourceLanguage => sourceLanguageNotifier.value;

String _trElEn(String tr, String el, String en) {
  switch (languageNotifier.value) {
    case 'el':
      return el;
    case 'en':
      return en;
    default:
      return tr;
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
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(SOURCE_LANGUAGE_PREF_KEY, lang);
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

bool matchesSourceLanguage(String? feedId, String? explicitLanguage) {
  final filter = sourceLanguageNotifier.value;
  if (filter == 'all') return true;
  return resolveFeedLanguage(feedId, explicitLanguage) == filter;
}

// localized app strings
String get APP_NAME =>
    _trElEn("Kıbrıs Haber", "Ειδήσεις Κύπρου", "Cyprus News");
String get APP_SUBTITLE => _trElEn(
      "Kıbrıs Güncel Haber Kaynakları",
      "Πηγές Ειδήσεων από όλη την Κύπρο",
      "Daily News Sources Across Cyprus",
    );

// source language filter labels
String get SOURCE_FILTER_ALL => _trElEn("Tümü", "Όλα", "All");
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
String get RECENT_NEWS =>
    _trElEn("Son Haberler", "Τελευταία Νέα", "Latest News");
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
      "Gazete Sırasını Değiştir",
      "Αλλαγή Σειράς Εφημερίδων",
      "Reorder Newspapers",
    );
String get REORDER_HINT => _trElEn(
      "Sıralamayı değiştirmek için basılı tutup sürükleyin",
      "Πατήστε παρατεταμένα και σύρετε για να αλλάξετε τη σειρά",
      "Press, hold and drag to change the order",
    );

// feeditem_view & lists
String get SHARE => _trElEn("Paylaş", "Κοινοποίηση", "Share");
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