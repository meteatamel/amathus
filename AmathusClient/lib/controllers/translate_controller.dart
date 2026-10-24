import 'dart:convert';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/models/overview.dart';
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
        final langNotifier = activeLanguageNotifier(item);
        if (langNotifier.value == normalizedTarget) {
          langNotifier.value = null;
        }
        langNotifier.value = normalizedTarget;
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

  static final Set<String> _inFlightStoryTranslations = <String>{};

  static void clearTranslation(FeedItem item) {
    activeLanguageNotifier(item).value = null;
  }

  static Future<bool> translateOverviewStory(
    OverviewStory story,
    String targetLanguage,
  ) async {
    final normalizedTarget = targetLanguage.trim().toLowerCase();
    if (normalizedTarget != 'tr' &&
        normalizedTarget != 'el' &&
        normalizedTarget != 'en') {
      return false;
    }
    if (!story.needsTranslationFor(normalizedTarget)) {
      return false;
    }

    final flightKey = '${story.id}|$normalizedTarget';
    if (!_inFlightStoryTranslations.add(flightKey)) {
      return false;
    }

    try {
      final majLang = story.majorityLanguage();
      final sourceTitle = story.sources.isNotEmpty &&
              story.sources.first.article.title.trim().isNotEmpty
          ? story.sources.first.article.title.trim()
          : story.titleFor(majLang);
      final sourceNarrative = story.narrativeFor(majLang);

      final response = await http.post(
        Uri.parse(Constants.URL_TRANSLATE),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Title': sourceTitle,
          'Summary': sourceNarrative,
          'Detail': '',
          'SourceLanguage': '',
          'TargetLanguage': normalizedTarget,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final trTitle = (data['Title'] as String?)?.trim() ?? '';
        final trSummary = (data['Summary'] as String?)?.trim() ?? '';
        if (trTitle.isNotEmpty || trSummary.isNotEmpty) {
          story.applyTranslation(
            normalizedTarget,
            title: trTitle.isNotEmpty ? trTitle : sourceTitle,
            narrative: trSummary.isNotEmpty ? trSummary : sourceNarrative,
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('Failed to translate overview story ${story.id}: $e');
    } finally {
      _inFlightStoryTranslations.remove(flightKey);
    }
    return false;
  }

  static Future<void> ensureOverviewStoriesTranslated(
    List<OverviewStory> stories,
    String? targetLanguage, {
    VoidCallback? onUpdated,
  }) async {
    if (targetLanguage == null || targetLanguage.trim().isEmpty) return;
    final normalizedTarget = targetLanguage.trim().toLowerCase();
    if (normalizedTarget != 'tr' &&
        normalizedTarget != 'el' &&
        normalizedTarget != 'en') {
      return;
    }

    final pending = stories
        .where((s) => s.needsTranslationFor(normalizedTarget))
        .toList();
    if (pending.isEmpty) return;

    const int concurrency = 6;
    int nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        if (nextIndex >= pending.length) return;
        final story = pending[nextIndex++];
        final updated = await translateOverviewStory(story, normalizedTarget);
        if (updated && onUpdated != null) {
          onUpdated();
        }
      }
    }

    final workerCount =
        pending.length < concurrency ? pending.length : concurrency;
    await Future.wait(List.generate(workerCount, (_) => worker()));
  }

  static void seedOverviewTranslations(
    FeedItem item, {
    required String titleEl,
    required String summaryEl,
    required String titleTr,
    required String summaryTr,
    required String titleEn,
    required String summaryEn,
    String? activeTargetLang,
  }) {
    final key = _itemKey(item);
    final sourceLang = Constants.resolveFeedLanguage(
      item.feed?.id,
      item.feed?.language,
    );
    final entries = <String, (String, String)>{
      'el': (titleEl, summaryEl),
      'tr': (titleTr, summaryTr),
      'en': (titleEn, summaryEn),
    };
    for (final entry in entries.entries) {
      final lang = entry.key;
      final t = entry.value.$1.trim();
      final s = OverviewStory.cleanNarrativeText(entry.value.$2);
      if (t.isEmpty && s.isEmpty) continue;
      if (OverviewStory.isTextUntranslatedFor(
            t,
            lang,
            sourceLang: sourceLang,
          ) ||
          (lang != sourceLang &&
              t.isNotEmpty &&
              t == item.title.trim() &&
              titleEl.trim() == titleTr.trim() &&
              titleTr.trim() == titleEn.trim())) {
        continue;
      }
      final cacheKey = '$key|$lang';
      final prev = _cache[cacheKey];
      _cache[cacheKey] = TranslatedFeedItemContent(
        title: t.isNotEmpty ? t : item.title,
        summary: s.isNotEmpty ? s : (item.summary ?? ''),
        detail: prev?.detail ?? '',
        targetLanguage: lang,
      );
    }

    if (activeTargetLang != null &&
        activeTargetLang.trim().isNotEmpty &&
        activeTargetLang.trim().toLowerCase() != sourceLang) {
      final targetNorm = activeTargetLang.trim().toLowerCase();
      if (_cache.containsKey('$key|$targetNorm')) {
        activeLanguageNotifier(item).value = targetNorm;
      } else {
        translateItem(item, targetNorm, includeDetail: false);
      }
    } else {
      activeLanguageNotifier(item).value = null;
    }
  }
}

class BulkTranslateController {
  final ValueNotifier<String?> activeLanguageNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  List<FeedItem> _items = const [];
  int _runId = 0;

  void setItems(
    List<FeedItem> items, {
    bool Function(FeedItem)? filter,
  }) {
    _items = items;
    final activeLang = activeLanguageNotifier.value;
    if (activeLang != null) {
      translateAll(activeLang, filter: filter);
    }
  }

  Future<void> translateAll(
    String targetLanguage, {
    bool Function(FeedItem)? filter,
  }) async {
    final normalizedTarget = targetLanguage.trim().toLowerCase();
    final currentRun = ++_runId;

    if (normalizedTarget == 'original') {
      activeLanguageNotifier.value = null;
      loadingNotifier.value = false;
      for (final item in _items) {
        TranslateController.clearTranslation(item);
      }
      return;
    }

    activeLanguageNotifier.value = normalizedTarget;
    final targetItems = filter != null
        ? _items.where(filter).toList()
        : List<FeedItem>.from(_items);

    final pending = <FeedItem>[];
    for (final item in targetItems) {
      final sourceLang = Constants.resolveFeedLanguage(
        item.feed?.id,
        item.feed?.language,
      );
      if (sourceLang == normalizedTarget) {
        TranslateController.clearTranslation(item);
      } else if (TranslateController.getCached(item, normalizedTarget) !=
          null) {
        TranslateController.activeLanguageNotifier(item).value =
            normalizedTarget;
      } else {
        pending.add(item);
      }
    }

    if (pending.isEmpty) {
      loadingNotifier.value = false;
      return;
    }

    loadingNotifier.value = true;
    const int concurrency = 6;
    int nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        if (_runId != currentRun) return;
        if (nextIndex >= pending.length) return;
        final item = pending[nextIndex++];
        await TranslateController.translateItem(
          item,
          normalizedTarget,
          includeDetail: false,
        );
      }
    }

    try {
      final workerCount =
          pending.length < concurrency ? pending.length : concurrency;
      await Future.wait(List.generate(workerCount, (_) => worker()));
    } finally {
      if (_runId == currentRun) {
        loadingNotifier.value = false;
      }
    }
  }

  void clearAll() {
    ++_runId;
    activeLanguageNotifier.value = null;
    loadingNotifier.value = false;
    for (final item in _items) {
      TranslateController.clearTranslation(item);
    }
  }
}

