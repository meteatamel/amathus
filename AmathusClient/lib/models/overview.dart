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
  final String edition;
  final List<OverviewStory> stories;
  final List<PodcastDialogueTurn> podcastTurns;

  NewsOverview({
    required this.id,
    required this.generatedAt,
    required this.totalFeedsAnalyzed,
    required this.totalArticlesAnalyzed,
    required this.summaryEn,
    required this.summaryTr,
    required this.summaryEl,
    this.edition = '',
    required this.stories,
    this.podcastTurns = const [],
  });

  static String currentCyprusEdition([DateTime? nowUtc]) {
    final utc = (nowUtc ?? DateTime.now()).toUtc();
    final cyprusHour = utc.add(const Duration(hours: 3)).hour;
    if (cyprusHour >= 5 && cyprusHour < 12) return 'morning';
    if (cyprusHour >= 12 && cyprusHour < 17) return 'midday';
    return 'evening';
  }

  String get effectiveEdition {
    final norm = edition.trim().toLowerCase();
    if (norm == 'morning' || norm == 'midday' || norm == 'evening') {
      return norm;
    }
    return currentCyprusEdition();
  }

  List<PodcastDialogueTurn> turnsForEdition([String? requestedEdition]) {
    final targetEdition =
        (requestedEdition != null && requestedEdition.trim().isNotEmpty)
            ? requestedEdition.trim().toLowerCase()
            : effectiveEdition;
    if (podcastTurns.isNotEmpty && targetEdition == effectiveEdition) {
      return podcastTurns;
    }
    return PodcastDialogueTurn.buildClientTurns(this, targetEdition);
  }

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
    final rawTurns = (json['PodcastTurns'] as List<dynamic>?) ?? const [];
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
      edition: (json['Edition'] as String?) ?? '',
      stories: rawStories
          .map((e) => OverviewStory.fromJson(e as Map<String, dynamic>))
          .toList(),
      podcastTurns: rawTurns
          .map((e) => PodcastDialogueTurn.fromJson(e as Map<String, dynamic>))
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
        'Edition': edition,
        'Stories': stories.map((e) => e.toJson()).toList(),
        'PodcastTurns': podcastTurns.map((e) => e.toJson()).toList(),
      };
}

class PodcastDialogueTurn {
  final int index;
  final String speaker;
  final String? storyId;
  final String speakerNameEl;
  final String speakerNameTr;
  final String speakerNameEn;
  final String textEl;
  final String textTr;
  final String textEn;

  const PodcastDialogueTurn({
    required this.index,
    required this.speaker,
    this.storyId,
    required this.speakerNameEl,
    required this.speakerNameTr,
    required this.speakerNameEn,
    required this.textEl,
    required this.textTr,
    required this.textEn,
  });

  bool get isHostA => speaker.toUpperCase() != 'B';

  String speakerNameFor(String lang) {
    switch (lang.toLowerCase()) {
      case 'el':
        return speakerNameEl.trim().isNotEmpty
            ? speakerNameEl
            : (isHostA ? 'Αθηνά' : 'Νέστορας');
      case 'tr':
        return speakerNameTr.trim().isNotEmpty
            ? speakerNameTr
            : (isHostA ? 'Emel' : 'Ahmet');
      default:
        return speakerNameEn.trim().isNotEmpty
            ? speakerNameEn
            : (isHostA ? 'Sonia' : 'Ryan');
    }
  }

  String textFor(String lang) {
    switch (lang.toLowerCase()) {
      case 'el':
        return textEl.trim().isNotEmpty ? textEl : textEn;
      case 'tr':
        return textTr.trim().isNotEmpty ? textTr : textEn;
      default:
        return textEn.trim().isNotEmpty ? textEn : textTr;
    }
  }

  factory PodcastDialogueTurn.fromJson(Map<String, dynamic> json) {
    return PodcastDialogueTurn(
      index: (json['Index'] as num?)?.toInt() ?? 0,
      speaker: (json['Speaker'] as String?) ?? 'A',
      storyId: json['StoryId'] as String?,
      speakerNameEl: (json['SpeakerNameEl'] as String?) ?? '',
      speakerNameTr: (json['SpeakerNameTr'] as String?) ?? '',
      speakerNameEn: (json['SpeakerNameEn'] as String?) ?? '',
      textEl: (json['TextEl'] as String?) ?? '',
      textTr: (json['TextTr'] as String?) ?? '',
      textEn: (json['TextEn'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'Index': index,
        'Speaker': speaker,
        'StoryId': storyId,
        'SpeakerNameEl': speakerNameEl,
        'SpeakerNameTr': speakerNameTr,
        'SpeakerNameEn': speakerNameEn,
        'TextEl': textEl,
        'TextTr': textTr,
        'TextEn': textEn,
      };

  static List<PodcastDialogueTurn> buildClientTurns(
    NewsOverview overview,
    String edition,
  ) {
    final topStories = overview.stories.take(8).toList();
    if (topStories.isEmpty) return const [];

    final turns = <PodcastDialogueTurn>[];
    var idx = 0;

    final titleEl = Constants.podcastEditionTitleFor(edition, 'el');
    final titleTr = Constants.podcastEditionTitleFor(edition, 'tr');
    final titleEn = Constants.podcastEditionTitleFor(edition, 'en');

    final rundownFirstEl =
        topStories.take(3).map((s) => '${s.titleFor('el')}.').join(' ');
    final rundownFirstTr =
        topStories.take(3).map((s) => '${s.titleFor('tr')}.').join(' ');
    final rundownFirstEn =
        topStories.take(3).map((s) => '${s.titleFor('en')}.').join(' ');

    final rundownSecondEl = topStories
        .skip(3)
        .take(3)
        .map((s) => '${s.titleFor('el')}.')
        .join(' ');
    final rundownSecondTr = topStories
        .skip(3)
        .take(3)
        .map((s) => '${s.titleFor('tr')}.')
        .join(' ');
    final rundownSecondEn = topStories
        .skip(3)
        .take(3)
        .map((s) => '${s.titleFor('en')}.')
        .join(' ');

    turns.add(PodcastDialogueTurn(
      index: idx++,
      speaker: 'A',
      speakerNameEl: '',
      speakerNameTr: '',
      speakerNameEn: '',
      textEl:
          'Καλωσορίσατε στις $titleEl. Πριν περάσουμε στις λεπτομέρειες, ας δούμε συνοπτικά τους βασικούς τίτλους της επικαιρότητας: $rundownFirstEl',
      textTr:
          '$titleTr bültenine hoş geldiniz. Detaylara geçmeden önce günün öne çıkan başlıklarına hızlıca göz atalım: $rundownFirstTr',
      textEn:
          'Welcome to $titleEn. Before we dive into the details, here is a quick rundown of our top headlines: $rundownFirstEn',
    ));

    turns.add(PodcastDialogueTurn(
      index: idx++,
      speaker: 'B',
      storyId: topStories.first.id,
      speakerNameEl: '',
      speakerNameTr: '',
      speakerNameEn: '',
      textEl: rundownSecondEl.isNotEmpty
          ? 'Επίσης στους σημερινούς τίτλους: $rundownSecondEl Ας περάσουμε τώρα αναλυτικά σε κάθε είδηση, ξεκινώντας από το πρώτο μας θέμα.'
          : 'Ας περάσουμε τώρα αναλυτικά σε κάθε είδηση, ξεκινώντας από το πρώτο μας θέμα.',
      textTr: rundownSecondTr.isNotEmpty
          ? 'Gündemdeki diğer önemli başlıklarda ise: $rundownSecondTr Şimdi gelin bu gelişmelerin ayrıntılarına tek tek bakalım.'
          : 'Şimdi gelin bu gelişmelerin ayrıntılarına tek tek bakalım.',
      textEn: rundownSecondEn.isNotEmpty
          ? 'Also making headlines right now: $rundownSecondEn Now let\'s take a closer look at each story one by one.'
          : 'Now let\'s take a closer look at each story one by one.',
    ));

    for (var i = 0; i < topStories.length; i++) {
      final s = topStories[i];
      final hostALeads = i.isEven;

      turns.add(PodcastDialogueTurn(
        index: idx++,
        speaker: hostALeads ? 'A' : 'B',
        storyId: s.id,
        speakerNameEl: '',
        speakerNameTr: '',
        speakerNameEn: '',
        textEl: '${s.titleFor('el')}. ${s.narrativeFor('el')}',
        textTr: '${s.titleFor('tr')}. ${s.narrativeFor('tr')}',
        textEn: '${s.titleFor('en')}. ${s.narrativeFor('en')}',
      ));

      turns.add(PodcastDialogueTurn(
        index: idx++,
        speaker: hostALeads ? 'B' : 'A',
        storyId: s.id,
        speakerNameEl: '',
        speakerNameTr: '',
        speakerNameEn: '',
        textEl:
            'Πράγματι. Οι εξελίξεις παρακολουθούνται στενά, αναδεικνύοντας τη σημασία του θέματος στην επικαιρότητα της ημέρας.',
        textTr:
            'Kesinlikle. Bu gelişme ada gündeminde yakından takip edilen konular arasında yer alıyor.',
        textEn:
            'That\'s right. This story remains a key focus across the island today as events continue to unfold.',
      ));
    }

    turns.add(PodcastDialogueTurn(
      index: idx++,
      speaker: 'A',
      speakerNameEl: '',
      speakerNameTr: '',
      speakerNameEn: '',
      textEl:
          'Αυτές ήταν οι Κύριες Ειδήσεις της Κύπρου για αυτή την ώρα. Μπορείτε να πατήσετε σε οποιαδήποτε είδηση παρακάτω για να διαβάσετε ολόκληρα τα άρθρα.',
      textTr:
          'Kıbrıs Öne Çıkan Haberler bültenimizin sonuna geldik. Aşağıdaki haber kartlarına dokunarak tüm makaleleri detaylı olarak okuyabilirsiniz.',
      textEn:
          'And that wraps up our Cyprus Top Stories briefing. You can tap any story card below to read the full articles.',
    ));

    final normEdition = edition.trim().toLowerCase();
    final closingEl = normEdition == 'morning'
        ? 'Σας ευχαριστούμε που μας ακούσατε. Θα είμαστε ξανά μαζί σας στη Μεσημεριανή μας έκδοση!'
        : (normEdition == 'midday'
            ? 'Σας ευχαριστούμε που μας ακούσατε. Θα είμαστε ξανά μαζί σας στη Βραδινή μας έκδοση!'
            : 'Σας ευχαριστούμε που μας ακούσατε. Θα είμαστε ξανά μαζί σας αύριο στην Πρωινή μας έκδοση!');
    final closingTr = normEdition == 'morning'
        ? 'Bizi dinlediğiniz için teşekkürler. Öğle bültenimizde yeniden görüşmek üzere, hoşça kalın!'
        : (normEdition == 'midday'
            ? 'Bizi dinlediğiniz için teşekkürler. Akşam bültenimizde yeniden görüşmek üzere, hoşça kalın!'
            : 'Bizi dinlediğiniz için teşekkürler. Yarın Sabah bültenimizde yeniden görüşmek üzere, hoşça kalın!');
    final closingEn = normEdition == 'morning'
        ? 'Thanks for listening, and join us again for our Mid-Day edition!'
        : (normEdition == 'midday'
            ? 'Thanks for listening, and join us again for our Evening edition!'
            : 'Thanks for listening, and join us again tomorrow for our Morning edition!');

    turns.add(PodcastDialogueTurn(
      index: idx++,
      speaker: 'B',
      speakerNameEl: '',
      speakerNameTr: '',
      speakerNameEn: '',
      textEl: closingEl,
      textTr: closingTr,
      textEn: closingEn,
    ));

    return turns;
  }
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
      author: article.author,
      isColumnist: article.isColumnist,
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
