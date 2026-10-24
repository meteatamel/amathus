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
    if (podcastTurns.isNotEmpty &&
        targetEdition == effectiveEdition &&
        podcastTurns.length > 2 &&
        (podcastTurns[2].storyId ?? '').isNotEmpty &&
        !PodcastDialogueTurn.hasMixedOrUntranslatedTurns(podcastTurns)) {
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
  static final RegExp _greekScriptRegex = RegExp(r'[\u0370-\u03FF\u1F00-\u1FFF]');
  static final RegExp _turkishSpecificRegex = RegExp(r'[ğĞşŞıİ]');
  static final RegExp _latinMultiWordRegex = RegExp(
    r'[A-Za-zÀ-ÖØ-öø-ÿğĞşŞıİçÇöÖüÜ]{4,}\s+[A-Za-zÀ-ÖØ-öø-ÿğĞşŞıİçÇöÖüÜ]{4,}\s+[A-Za-zÀ-ÖØ-öø-ÿğĞşŞıİçÇöÖüÜ]{4,}',
  );

  static bool hasMixedOrUntranslatedTurns(List<PodcastDialogueTurn> turns) {
    if (turns.length < 6) return true;
    for (final turn in turns) {
      final tr = turn.textTr.trim();
      final en = turn.textEn.trim();
      final el = turn.textEl.trim();
      if (tr.isEmpty || en.isEmpty || el.isEmpty) return true;
      if (_greekScriptRegex.hasMatch(tr) || _greekScriptRegex.hasMatch(en)) {
        return true;
      }
      if (_turkishSpecificRegex.hasMatch(en) ||
          _turkishSpecificRegex.hasMatch(el)) {
        return true;
      }
      if (!_greekScriptRegex.hasMatch(el) || _latinMultiWordRegex.hasMatch(el)) {
        return true;
      }
    }
    return false;
  }

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
      storyId: null,
      speakerNameEl: '',
      speakerNameTr: '',
      speakerNameEn: '',
      textEl:
          'Γεια σας φίλοι μας και καλωσορίσατε στις $titleEl! Πάρτε τον καφέ σας κι ελάτε να δούμε μαζί τι συζητιέται σήμερα σε όλο το νησί. Ξεκινάμε με μια γρήγορη ματιά στους πρώτους τίτλους: $rundownFirstEl',
      textTr:
          'Herkese merhaba! $titleTr bültenimize hoş geldiniz. Kahvenizi alın, gelin bugün adanın iki yakasında neler konuşuluyor hızlıca bir bakalım: $rundownFirstTr',
      textEn:
          'Hey everyone, welcome back to $titleEn! Grab a coffee and settle in — here is a quick look at what everyone is talking about across the island right now: $rundownFirstEn',
    ));

    turns.add(PodcastDialogueTurn(
      index: idx++,
      speaker: 'B',
      storyId: null,
      speakerNameEl: '',
      speakerNameTr: '',
      speakerNameEn: '',
      textEl: rundownSecondEl.isNotEmpty
          ? 'Και δεν είναι μόνο αυτά! Στην επικαιρότητα ξεχωρίζουν επίσης: $rundownSecondEl Πάμε λοιπόν να τα δούμε ένα-ένα πιο χαλαρά και αναλυτικά, ξεκινώντας από το πρώτο μας θέμα.'
          : 'Πάμε λοιπόν να τα δούμε ένα-ένα πιο χαλαρά και αναλυτικά, ξεκινώντας από το πρώτο μας θέμα.',
      textTr: rundownSecondTr.isNotEmpty
          ? 'Aynen öyle, gündem bugün oldukça hareketli! Öne çıkan diğer başlıklarda ise şunlar var: $rundownSecondTr Hadi gelin ilk haberimizle sohbete başlayalım.'
          : 'Hadi gelin ilk haberimizle sohbete başlayalım.',
      textEn: rundownSecondEn.isNotEmpty
          ? 'Yeah, plenty happening today! Also catching our eye right now: $rundownSecondEn Let\'s jump right in and unpack each story one by one.'
          : 'Let\'s jump right in and unpack each story one by one.',
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
            'Έτσι ακριβώς. Είναι ένα θέμα που συζητιέται έντονα σήμερα και θα έχει μεγάλο ενδιαφέρον να δούμε πώς θα εξελιχθεί.',
        textTr:
            'Kesinlikle. Bu gelişme bugün ada gündeminde en çok konuşulan başlıklar arasında yer alıyor.',
        textEn:
            'Yeah, totally — this is definitely one of those stories everyone across the island is keeping a close eye on today.',
      ));
    }

    turns.add(PodcastDialogueTurn(
      index: idx++,
      speaker: 'A',
      storyId: null,
      speakerNameEl: '',
      speakerNameTr: '',
      speakerNameEn: '',
      textEl:
          'Και κάπου εδώ ολοκληρώσαμε τη σημερινή μας ανασκόπηση! Αν θέλετε να διαβάσετε περισσότερα, απλώς πατήστε σε οποιαδήποτε κάρτα είδησης παρακάτω για να δείτε ολόκληρα τα άρθρα.',
      textTr:
          'Böylece bugünkü öne çıkan haber turumuzun sonuna geldik! Merak ettiğiniz haberlerin tamamını okumak için aşağıdaki kartlara dokunmanız yeterli.',
      textEn:
          'And that brings us to the end of today\'s roundup! If any story caught your ear, just tap on its card right below to read the full coverage.',
    ));

    final normEdition = edition.trim().toLowerCase();
    final closingEl = normEdition == 'morning'
        ? 'Σας ευχαριστούμε πολύ για την παρέα! Τα λέμε ξανά στη Μεσημεριανή μας έκδοση — να έχετε ένα υπέροχο πρωινό!'
        : (normEdition == 'midday'
            ? 'Σας ευχαριστούμε πολύ για την παρέα! Ανανεώνουμε το ραντεβού μας για τη Βραδινή μας έκδοση — καλό απόγευμα σε όλους!'
            : 'Σας ευχαριστούμε πολύ για την παρέα! Τα λέμε πάλι αύριο στην Πρωινή μας έκδοση — καλό σας βράδυ!');
    final closingTr = normEdition == 'morning'
        ? 'Bize katıldığınız için çok teşekkürler! Öğle bültenimizde yeniden buluşmak üzere, herkese harika bir sabah diliyoruz!'
        : (normEdition == 'midday'
            ? 'Bize katıldığınız için çok teşekkürler! Akşam bültenimizde yeniden görüşmek üzere, keyifli bir gün geçirmeniz dileğiyle!'
            : 'Bize katıldığınız için çok teşekkürler! Yarın Sabah bültenimizde yeniden buluşmak üzere, herkese iyi akşamlar!');
    final closingEn = normEdition == 'morning'
        ? 'Thanks so much for hanging out with us — have an awesome morning, and catch you again for our Mid-Day edition!'
        : (normEdition == 'midday'
            ? 'Thanks so much for tuning in — enjoy the rest of your afternoon, and we\'ll catch you back here for the Evening edition!'
            : 'Thanks so much for listening — have a relaxing evening, and we\'ll catch you again tomorrow for our Morning edition!');

    turns.add(PodcastDialogueTurn(
      index: idx++,
      speaker: 'B',
      storyId: null,
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
  static final RegExp _greekScriptRegex = RegExp(r'[\u0370-\u03FF\u1F00-\u1FFF]');
  static final RegExp _turkishSpecificRegex = RegExp(r'[ğĞşŞıİ]');
  static final RegExp _legacyReportsPrefixRegex = RegExp(
    r'(?:^|\s)[^:.]{1,40}\s+reports:\s*',
    caseSensitive: false,
  );
  static final RegExp _legacyCoveredBySuffixRegex = RegExp(
    r'\s*Covered by\s+[^.]+\.?\s*$',
    caseSensitive: false,
  );

  final String id;
  String titleEn;
  String titleTr;
  String titleEl;
  String narrativeEn;
  String narrativeTr;
  String narrativeEl;
  final String? imageUrl;
  final DateTime publishDate;
  final String? topic;
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
    this.topic,
    required this.sources,
  });

  static String cleanNarrativeText(String raw) {
    if (raw.trim().isEmpty) return '';
    var cleaned = raw.replaceAll(_legacyReportsPrefixRegex, ' ');
    cleaned = cleaned.replaceAll(_legacyCoveredBySuffixRegex, '');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool isTextUntranslatedFor(
    String text,
    String targetLang, {
    String? sourceLang,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final tl = targetLang.trim().toLowerCase();
    if (tl == 'el') {
      return !_greekScriptRegex.hasMatch(trimmed);
    }
    if (_greekScriptRegex.hasMatch(trimmed)) {
      return true;
    }
    if (tl == 'en' && _turkishSpecificRegex.hasMatch(trimmed)) {
      return true;
    }
    if (sourceLang != null &&
        sourceLang.trim().toLowerCase() != tl &&
        _legacyReportsPrefixRegex.hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  bool needsTranslationFor(String lang) {
    final tl = lang.trim().toLowerCase();
    if (tl != 'tr' && tl != 'el' && tl != 'en') return false;

    final majLang = majorityLanguage();
    final t = titleFor(tl).trim();
    final n = narrativeFor(tl).trim();

    if (isTextUntranslatedFor(t, tl, sourceLang: majLang) ||
        isTextUntranslatedFor(n, tl, sourceLang: majLang)) {
      return true;
    }

    if (majLang != tl) {
      final allTitlesSame = titleEn.trim().isNotEmpty &&
          titleEn.trim() == titleTr.trim() &&
          titleEn.trim() == titleEl.trim();
      if (allTitlesSame) return true;

      final allNarrativesSame = narrativeEn.trim().isNotEmpty &&
          narrativeEn.trim() == narrativeTr.trim() &&
          narrativeEn.trim() == narrativeEl.trim();
      if (allNarrativesSame) return true;
    }

    return false;
  }

  void applyTranslation(
    String lang, {
    required String title,
    required String narrative,
  }) {
    final cleanTitle = title.trim();
    final cleanNarr = cleanNarrativeText(narrative);
    switch (lang.trim().toLowerCase()) {
      case 'tr':
        if (cleanTitle.isNotEmpty) titleTr = cleanTitle;
        if (cleanNarr.isNotEmpty) narrativeTr = cleanNarr;
        break;
      case 'el':
        if (cleanTitle.isNotEmpty) titleEl = cleanTitle;
        if (cleanNarr.isNotEmpty) narrativeEl = cleanNarr;
        break;
      case 'en':
        if (cleanTitle.isNotEmpty) titleEn = cleanTitle;
        if (cleanNarr.isNotEmpty) narrativeEn = cleanNarr;
        break;
    }
  }

  String get effectiveTopic => Constants.resolveTopic(
        topic,
        title: '$titleEn $titleTr $titleEl',
        summary: '$narrativeEn $narrativeTr $narrativeEl',
        detail: sources.isNotEmpty ? sources.first.article.summary : null,
        url: sources.isNotEmpty ? sources.first.article.url : null,
      );

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
    String raw;
    switch (lang.toLowerCase()) {
      case 'tr':
        raw = narrativeTr.trim().isNotEmpty ? narrativeTr : narrativeEn;
        break;
      case 'el':
        raw = narrativeEl.trim().isNotEmpty ? narrativeEl : narrativeEn;
        break;
      default:
        raw = narrativeEn.trim().isNotEmpty ? narrativeEn : narrativeTr;
        break;
    }
    return cleanNarrativeText(raw);
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
      topic: (json['Topic'] as String?) ?? (json['topic'] as String?),
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
        'Topic': topic,
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
      topic: article.topic,
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
