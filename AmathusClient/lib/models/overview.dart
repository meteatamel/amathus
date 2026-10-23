import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class NewsOverview {
  final String id;
  final DateTime generatedAt;
  final int totalFeedsAnalyzed;
  final int totalArticlesAnalyzed;
  final String summaryEn;
  final String summaryTr;
  final String summaryEl;
  final List<OverviewStory> stories;

  NewsOverview({
    required this.id,
    required this.generatedAt,
    required this.totalFeedsAnalyzed,
    required this.totalArticlesAnalyzed,
    required this.summaryEn,
    required this.summaryTr,
    required this.summaryEl,
    required this.stories,
  });

  String summaryFor(String lang) {
    switch (lang.toLowerCase()) {
      case 'tr':
        return summaryTr.trim().isNotEmpty ? summaryTr : summaryEn;
      case 'el':
        return summaryEl.trim().isNotEmpty ? summaryEl : summaryEn;
      default:
        return summaryEn.trim().isNotEmpty ? summaryEn : summaryTr;
    }
  }

  factory NewsOverview.fromJson(Map<String, dynamic> json) {
    final rawStories = (json['Stories'] as List<dynamic>?) ?? const [];
    return NewsOverview(
      id: (json['Id'] as String?) ?? 'latest',
      generatedAt: DateTime.tryParse((json['GeneratedAt'] as String?) ?? '') ??
          DateTime.now(),
      totalFeedsAnalyzed: (json['TotalFeedsAnalyzed'] as num?)?.toInt() ?? 0,
      totalArticlesAnalyzed:
          (json['TotalArticlesAnalyzed'] as num?)?.toInt() ?? 0,
      summaryEn: (json['SummaryEn'] as String?) ?? '',
      summaryTr: (json['SummaryTr'] as String?) ?? '',
      summaryEl: (json['SummaryEl'] as String?) ?? '',
      stories: rawStories
          .map((e) => OverviewStory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'Id': id,
        'GeneratedAt': generatedAt.toIso8601String(),
        'TotalFeedsAnalyzed': totalFeedsAnalyzed,
        'TotalArticlesAnalyzed': totalArticlesAnalyzed,
        'SummaryEn': summaryEn,
        'SummaryTr': summaryTr,
        'SummaryEl': summaryEl,
        'Stories': stories.map((e) => e.toJson()).toList(),
      };
}

class OverviewStory {
  final String id;
  final String titleEn;
  final String titleTr;
  final String titleEl;
  final String narrativeEn;
  final String narrativeTr;
  final String narrativeEl;
  final String? imageUrl;
  final DateTime publishDate;
  final List<OverviewStorySource> sources;

  OverviewStory({
    required this.id,
    required this.titleEn,
    required this.titleTr,
    required this.titleEl,
    required this.narrativeEn,
    required this.narrativeTr,
    required this.narrativeEl,
    this.imageUrl,
    required this.publishDate,
    required this.sources,
  });

  String titleFor(String lang) {
    switch (lang.toLowerCase()) {
      case 'tr':
        return titleTr.trim().isNotEmpty ? titleTr : titleEn;
      case 'el':
        return titleEl.trim().isNotEmpty ? titleEl : titleEn;
      default:
        return titleEn.trim().isNotEmpty ? titleEn : titleTr;
    }
  }

  String narrativeFor(String lang) {
    switch (lang.toLowerCase()) {
      case 'tr':
        return narrativeTr.trim().isNotEmpty ? narrativeTr : narrativeEn;
      case 'el':
        return narrativeEl.trim().isNotEmpty ? narrativeEl : narrativeEn;
      default:
        return narrativeEn.trim().isNotEmpty ? narrativeEn : narrativeTr;
    }
  }

  String majorityLanguage([List<OverviewStorySource>? visibleSources]) {
    final list = (visibleSources != null && visibleSources.isNotEmpty)
        ? visibleSources
        : sources;
    if (list.isEmpty) {
      return 'en';
    }

    final counts = <String, int>{};
    for (final s in list) {
      final lang = Constants.resolveFeedLanguage(s.feedId, s.feedLanguage);
      counts[lang] = (counts[lang] ?? 0) + 1;
    }

    var bestLang = Constants.resolveFeedLanguage(
      list.first.feedId,
      list.first.feedLanguage,
    );
    var bestCount = counts[bestLang] ?? 0;

    for (final lang in const ['el', 'tr', 'en']) {
      final count = counts[lang] ?? 0;
      if (count > bestCount) {
        bestLang = lang;
        bestCount = count;
      }
    }

    return bestLang;
  }

  factory OverviewStory.fromJson(Map<String, dynamic> json) {
    final rawSources = (json['Sources'] as List<dynamic>?) ?? const [];
    return OverviewStory(
      id: (json['Id'] as String?) ?? '',
      titleEn: (json['TitleEn'] as String?) ?? '',
      titleTr: (json['TitleTr'] as String?) ?? '',
      titleEl: (json['TitleEl'] as String?) ?? '',
      narrativeEn: (json['NarrativeEn'] as String?) ?? '',
      narrativeTr: (json['NarrativeTr'] as String?) ?? '',
      narrativeEl: (json['NarrativeEl'] as String?) ?? '',
      imageUrl: json['ImageUrl'] as String?,
      publishDate: DateTime.tryParse((json['PublishDate'] as String?) ?? '') ??
          DateTime.now(),
      sources: rawSources
          .map((e) => OverviewStorySource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'Id': id,
        'TitleEn': titleEn,
        'TitleTr': titleTr,
        'TitleEl': titleEl,
        'NarrativeEn': narrativeEn,
        'NarrativeTr': narrativeTr,
        'NarrativeEl': narrativeEl,
        'ImageUrl': imageUrl,
        'PublishDate': publishDate.toIso8601String(),
        'Sources': sources.map((e) => e.toJson()).toList(),
      };
}

class OverviewStorySource {
  final String feedId;
  final String feedTitle;
  final String feedLanguage;
  final String? feedImageUrl;
  final String? feedUrl;
  final FeedItem article;

  OverviewStorySource({
    required this.feedId,
    required this.feedTitle,
    required this.feedLanguage,
    this.feedImageUrl,
    this.feedUrl,
    required this.article,
  });

  Feed toFeed() {
    return Feed(
      feedId,
      feedTitle,
      article.publishDate,
      feedImageUrl,
      feedUrl,
      [article],
      feedLanguage,
    );
  }

  FeedItem toFeedItem() {
    final item = FeedItem(
      article.title,
      article.publishDate,
      article.summary,
      article.detail,
      article.imageUrl,
      article.url,
    );
    item.feed = toFeed();
    return item;
  }

  factory OverviewStorySource.fromJson(Map<String, dynamic> json) {
    final articleJson =
        (json['Article'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final article = FeedItem.fromJson(articleJson);
    final source = OverviewStorySource(
      feedId: (json['FeedId'] as String?) ?? '',
      feedTitle: (json['FeedTitle'] as String?) ?? '',
      feedLanguage: (json['FeedLanguage'] as String?) ?? 'tr',
      feedImageUrl: json['FeedImageUrl'] as String?,
      feedUrl: json['FeedUrl'] as String?,
      article: article,
    );
    article.feed = source.toFeed();
    return source;
  }

  Map<String, dynamic> toJson() => {
        'FeedId': feedId,
        'FeedTitle': feedTitle,
        'FeedLanguage': feedLanguage,
        'FeedImageUrl': feedImageUrl,
        'FeedUrl': feedUrl,
        'Article': article.toJson(),
      };
}
