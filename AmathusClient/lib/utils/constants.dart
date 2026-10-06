import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// urls
const String URL_MAIN =
    "https://amathus-web-1086570528700.europe-west1.run.app/api/v1";
const String URL_FEEDS = "$URL_MAIN/feeds";
const String URL_FEED_ITEMS = "$URL_MAIN/feeditems";
const String URL_TWITTER = "https://twitter.com/meteatamel";

// files / storage keys
const String FEEDS_FILE = "feeds_v2.json";
const String LANGUAGE_PREF_KEY = "app_language";

// contact
const String APP_EMAIL = "atameldev@gmail.com";

// language state ('tr' or 'en')
final ValueNotifier<String> languageNotifier = ValueNotifier<String>('tr');

String get currentLanguage => languageNotifier.value;
bool get isEnglish => languageNotifier.value == 'en';

Future<void> initLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(LANGUAGE_PREF_KEY);
  if (saved == 'en' || saved == 'tr') {
    languageNotifier.value = saved!;
  }
}

Future<void> setLanguage(String lang) async {
  if (lang != 'tr' && lang != 'en') return;
  languageNotifier.value = lang;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(LANGUAGE_PREF_KEY, lang);
}

// localized app strings
String get APP_NAME => isEnglish ? "North Cyprus News" : "Kuzey Kıbrıs Haber";
String get APP_SUBTITLE =>
    isEnglish ? "TRNC Daily News Sources" : "KKTC Güncel Haber Kaynakları";

// drawer & navigation
String get RECENT_NEWS => isEnglish ? "Latest News" : "Son Haberler";
String get NEWSPAPERS => isEnglish ? "Newspapers" : "Gazeteler";
String get ALL_NEWS => NEWSPAPERS;
String get SETTINGS => isEnglish ? "Settings" : "Ayarlar";
String get CONTACT => isEnglish ? "Contact" : "İletişim";

// settings_view
String get LANGUAGE_TITLE => isEnglish ? "Language" : "Dil Seçimi";
String get LANGUAGE_SUBTITLE => isEnglish
    ? "Switch the app interface between Turkish and English"
    : "Uygulama dilini Türkçe veya İngilizce olarak değiştirin";
String get REORDER_NEWS =>
    isEnglish ? "Reorder Newspapers" : "Gazete Sırasını Değiştir";
String get REORDER_HINT => isEnglish
    ? "Press, hold and drag to change the order"
    : "Sıralamayı değiştirmek için basılı tutup sürükleyin";

// feeditem_view & lists
String get SHARE => isEnglish ? "Share" : "Paylaş";
String get MORE => isEnglish ? "Read Full Article" : "Haberi Kaynağında Oku";
String get LOADING_NEWS =>
    isEnglish ? "Loading news..." : "Haberler yükleniyor...";
String get NO_NEWS_FOUND =>
    isEnglish ? "No news found yet." : "Henüz haber bulunamadı.";

// contact_view
String get CONTACT_INFO =>
    isEnglish ? "Contact Information" : "İletişim Bilgileri";
String get SEND_MESSAGE =>
    isEnglish ? "Send a Message" : "Bize Mesaj Gönderin";
String get FIRST_LAST_NAME => isEnglish ? "Full Name" : "İsim Soyisim";
String get FEEDBACK => isEnglish
    ? "Write your comment or feedback"
    : "Yorum veya geri bildiriminizi yazın";
String get NO_LEAVE_EMPTY =>
    isEnglish ? "Please do not leave empty" : "Lütfen boş bırakmayınız";
String get SEND => isEnglish ? "Send" : "Gönder";
String get EMAIL_CLIENT_OPENED =>
    isEnglish ? "Email client opened" : "E-posta istemcisi açıldı";
String get EMAIL_SENT => isEnglish ? "Email sent" : "E-posta gönderildi";
String get EMAIL_ERROR =>
    isEnglish ? "Error sending email" : "E-posta göndermede hata";
String get URL_ERROR =>
    isEnglish ? "Could not open link" : "Bağlantı açılamadı";

const Set<String> _darkLogoFeedIds = {
  'cyprustoday',
  'detaykibris',
  'gundemkibris',
  'haberalkibrisli',
  'kibrisgazetesi',
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