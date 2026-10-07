import 'dart:convert';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TranslatedFeedItemContent {
  final String title;
  final String summary;
  final String detail;
  final String targetLanguage;

  const TranslatedFeedItemContent({
    required this.title,
    required this.summary,
    required this.detail,
    required this.targetLanguage,
  });
}

class TranslateController {
  static final Map<String, TranslatedFeedItemContent> _cache = {};
  static final Map<String, ValueNotifier<String?>> _activeLangNotifiers = {};
  static final Map<String, ValueNotifier<bool>> _loadingNotifiers = {};

  static String _itemKey(FeedItem item) {
    final url = (item.url ?? '').trim();
    if (url.isNotEmpty) return url;
    return '${item.feed?.id ?? ''}:${item.title}';
  }

  static ValueNotifier<String?> activeLanguageNotifier(FeedItem item) {
    final key = _itemKey(item);
    return _activeLangNotifiers.putIfAbsent(key, () => ValueNotifier<String?>(null));
  }

  static ValueNotifier<bool> loadingNotifier(FeedItem item) {
    final key = _itemKey(item);
    return _loadingNotifiers.putIfAbsent(key, () => ValueNotifier<bool>(false));
  }

  static TranslatedFeedItemContent? getCached(
    FeedItem item,
    String targetLanguage, {
    bool requireDetail = false,
  }) {
    final cacheKey = '${_itemKey(item)}|$targetLanguage';
    final cached = _cache[cacheKey];
    if (cached == null) return null;
    if (requireDetail &&
        (item.detail ?? '').trim().isNotEmpty &&
        cached.detail.trim().isEmpty) {
      return null;
    }
    return cached;
  }

  static Future<TranslatedFeedItemContent?> translateItem(
    FeedItem item,
    String targetLanguage, {
    bool includeDetail = true,
  }) async {
    final sourceLang = Constants.resolveFeedLanguage(
      item.feed?.id,
      item.feed?.language,
    );
    final normalizedTarget = targetLanguage.trim().toLowerCase();

    if (normalizedTarget == sourceLang || normalizedTarget == 'original') {
      activeLanguageNotifier(item).value = null;
      return null;
    }

    final existing = getCached(
      item,
      normalizedTarget,
      requireDetail: includeDetail,
    );
    if (existing != null) {
      activeLanguageNotifier(item).value = normalizedTarget;
      return existing;
    }

    final isLoading = loadingNotifier(item);
    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse(Constants.URL_TRANSLATE),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Title': item.title,
          'Summary': item.summary ?? '',
          'Detail': includeDetail ? (item.detail ?? '') : '',
          'SourceLanguage': sourceLang,
          'TargetLanguage': normalizedTarget,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cacheKey = '${_itemKey(item)}|$normalizedTarget';
        final previous = _cache[cacheKey];

        final translated = TranslatedFeedItemContent(
          title: (data['Title'] as String?)?.trim().isNotEmpty == true
              ? (data['Title'] as String)
              : item.title,
          summary: (data['Summary'] as String?) ?? (item.summary ?? ''),
          detail: (data['Detail'] as String?)?.trim().isNotEmpty == true
              ? (data['Detail'] as String)
              : (previous?.detail ?? ''),
          targetLanguage: normalizedTarget,
        );
        _cache[cacheKey] = translated;
        activeLanguageNotifier(item).value = normalizedTarget;
        return translated;
      } else {
        debugPrint(
          'Translate API returned HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Failed to translate feed item: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  static void clearTranslation(FeedItem item) {
    activeLanguageNotifier(item).value = null;
  }
}
