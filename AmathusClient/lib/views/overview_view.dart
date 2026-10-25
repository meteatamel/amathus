import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/controllers/overview_controller.dart';
import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:amathus/views/common/offline_banner.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:amathus/views/common/pwa_install.dart';
import 'package:amathus/views/common/share_iconbutton.dart';
import 'package:amathus/views/common/source_language_filter_bar.dart';
import 'package:amathus/views/common/top_stories_podcast_card.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class OverviewView extends StatefulWidget {
  final Future<NewsOverview?> Function()? loadCachedCallback;
  final Future<NewsOverview?> Function({bool refresh})? loadServerCallback;

  const OverviewView({
    super.key,
    this.loadCachedCallback,
    this.loadServerCallback,
  });

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  final OverviewController _controller = OverviewController();
  final FeedItemsController _feedItemsController = FeedItemsController();
  final BulkTranslateController _bulkTranslateController =
      BulkTranslateController();
  final ValueNotifier<List<FeedItem>> _latestItemsNotifier =
      ValueNotifier<List<FeedItem>>(const []);
  NewsOverview? _overview;
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _maxVisibleTopStories = 20;
  bool _isLoadingMoreStories = false;

  @override
  void initState() {
    super.initState();
    if (widget.loadCachedCallback == null &&
        _controller.memoryCached != null &&
        _controller.memoryCached!.stories.isNotEmpty) {
      _overview = _controller.memoryCached;
      _isLoading = false;
    }
    Constants.overviewTranslateLanguageNotifier
        .addListener(_onTranslateLanguageChanged);
    ConnectivityController.instance.addReconnectListener(_onReconnected);
    _loadLatestCachedData();
    _loadInitial();
  }

  @override
  void dispose() {
    Constants.overviewTranslateLanguageNotifier
        .removeListener(_onTranslateLanguageChanged);
    ConnectivityController.instance.removeReconnectListener(_onReconnected);
    _latestItemsNotifier.dispose();
    super.dispose();
  }

  void _onReconnected() {
    _refreshFromServer(forceRefresh: false);
    _loadLatestData();
  }

  void _onTranslateLanguageChanged() {
    _translateVisibleStoriesIfNeeded();
  }

  void _translateVisibleStoriesIfNeeded() {
    if (ConnectivityController.instance.isOffline) return;
    final ov = _overview;
    final targetLang = Constants.overviewTranslateLanguageNotifier.value;
    if (ov == null || ov.stories.isEmpty || targetLang == null) return;
    final visibleSlice = ov.stories.take(_maxVisibleTopStories).toList();
    TranslateController.ensureOverviewStoriesTranslated(
      visibleSlice,
      targetLang,
      onUpdated: () {
        if (mounted) {
          setState(() {});
        }
      },
    ).then((_) {
      PodcastPlaybackController.instance.onStoriesUpdated();
    });
  }

  Future<void> _loadInitial() async {
    final cachedLoader = widget.loadCachedCallback ?? _controller.readStored;
    final cached = await cachedLoader();
    if (cached != null && cached.stories.isNotEmpty && mounted) {
      setState(() {
        _overview = cached;
        _isLoading = false;
      });
      _translateVisibleStoriesIfNeeded();
    }
    await _refreshFromServer(forceRefresh: false);
  }

  Future<void> _refreshFromServer({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        if (_overview != null) {
          _isRefreshing = true;
        } else {
          _isLoading = true;
        }
      });
    }

    final serverLoader = widget.loadServerCallback ?? _controller.read;
    final fresh = await serverLoader(refresh: forceRefresh);
    if (!mounted) return;

    setState(() {
      if (fresh != null && fresh.stories.isNotEmpty) {
        _overview = fresh;
      }
      _isLoading = false;
      _isRefreshing = false;
    });
    _translateVisibleStoriesIfNeeded();
  }

  List<OverviewStorySource> _visibleSourcesFor(OverviewStory story) {
    return story.sources
        .where(
          (s) => Constants.matchesSourceLanguageOnly(s.feedId, s.feedLanguage),
        )
        .toList();
  }

  bool _matchesVisibleLatestFilter(FeedItem item) {
    final matchesSource = item.feed == null ||
        Constants.matchesSourceLanguage(
          item.feed?.id,
          item.feed?.language,
        );
    if (!matchesSource) return false;
    return Constants.matchesSelectedTopic(item.effectiveTopic);
  }

  Map<String, int>? _computeSourceCounts(bool isTopMode) {
    final counts = <String, int>{
      'all': 0,
      'el': 0,
      'tr': 0,
      'en': 0,
    };
    if (isTopMode) {
      final ov = _overview;
      if (ov == null || ov.stories.isEmpty) return null;
      var total = 0;
      for (final story in ov.stories.take(_maxVisibleTopStories)) {
        if (!Constants.matchesSelectedTopic(story.effectiveTopic)) continue;
        final visibleSources = story.sources
            .where((s) => Constants.isFeedVisible(s.feedId))
            .toList();
        if (visibleSources.isEmpty) continue;
        total++;
        final seenLangs = <String>{};
        for (final s in visibleSources) {
          seenLangs.add(
            Constants.resolveFeedLanguage(s.feedId, s.feedLanguage),
          );
        }
        for (final lang in seenLangs) {
          counts[lang] = (counts[lang] ?? 0) + 1;
        }
      }
      if (total == 0) return null;
      counts['all'] = total;
      return counts;
    } else {
      final list = _latestItemsNotifier.value;
      if (list.isEmpty) return null;
      var total = 0;
      for (final item in list) {
        final feedId = item.feed?.id;
        if (!Constants.isFeedVisible(feedId)) continue;
        if (!Constants.matchesSelectedTopic(item.effectiveTopic)) continue;
        final lang =
            Constants.resolveFeedLanguage(feedId, item.feed?.language);
        counts[lang] = (counts[lang] ?? 0) + 1;
        total++;
      }
      if (total == 0) return null;
      counts['all'] = total;
      return counts;
    }
  }

  Map<String, int>? _computeTopicCounts(bool isTopMode) {
    final counts = <String, int>{
      for (final code in Constants.TOPIC_CODES) code: 0,
    };
    if (isTopMode) {
      final ov = _overview;
      if (ov == null || ov.stories.isEmpty) return null;
      var total = 0;
      for (final story in ov.stories.take(_maxVisibleTopStories)) {
        if (_visibleSourcesFor(story).isEmpty) continue;
        final t = story.effectiveTopic;
        counts[t] = (counts[t] ?? 0) + 1;
        total++;
      }
      if (total == 0) return null;
      counts['all'] = total;
      return counts;
    } else {
      final list = _latestItemsNotifier.value;
      if (list.isEmpty) return null;
      var total = 0;
      for (final item in list) {
        final matchesSource = item.feed == null ||
            Constants.matchesSourceLanguage(
              item.feed?.id,
              item.feed?.language,
            );
        if (!matchesSource) continue;
        final t = item.effectiveTopic;
        counts[t] = (counts[t] ?? 0) + 1;
        total++;
      }
      if (total == 0) return null;
      counts['all'] = total;
      return counts;
    }
  }

  Map<String, int>? _computeNewspaperCounts() {
    final list = _latestItemsNotifier.value;
    if (list.isEmpty) return null;
    final counts = <String, int>{'all': 0};
    var total = 0;
    for (final item in list) {
      final feedId = item.feed?.id.trim().toLowerCase();
      if (feedId == null || feedId.isEmpty) continue;
      if (!Constants.matchesSourceLanguageOnly(feedId, item.feed?.language)) {
        continue;
      }
      if (!Constants.matchesSelectedTopic(item.effectiveTopic)) continue;
      counts[feedId] = (counts[feedId] ?? 0) + 1;
      total++;
    }
    if (total == 0) return null;
    counts['all'] = total;
    return counts;
  }

  Future<void> _loadMoreTopStories() async {
    if (_maxVisibleTopStories >= 40 || _isLoadingMoreStories) return;
    final ov = _overview;
    if (ov == null) return;

    setState(() {
      _isLoadingMoreStories = true;
    });

    try {
      final minSpinnerDelay =
          Future<void>.delayed(const Duration(milliseconds: 650));
      var latestItems = _latestItemsNotifier.value;
      if (latestItems.isEmpty) {
        latestItems = await _loadLatestCachedData() ?? const [];
      }
      if (latestItems.isEmpty) {
        latestItems = await _loadLatestData() ?? const [];
      }
      await minSpinnerDelay;

      if (ov.stories.length < 40 && latestItems.isNotEmpty) {
        final existingUrls = <String>{};
        for (final s in ov.stories) {
          for (final src in s.sources) {
            final u = (src.article.url ?? '').trim();
            if (u.isNotEmpty) existingUrls.add(u);
          }
        }

        final extraStories = <OverviewStory>[];
        for (final item in latestItems) {
          if (ov.stories.length + extraStories.length >= 40) break;
          final url = (item.url ?? '').trim();
          if (url.isNotEmpty && existingUrls.contains(url)) continue;
          final feed = item.feed;
          if (feed == null) continue;
          if (url.isNotEmpty) existingUrls.add(url);

          final narrative = (item.summary ?? '').trim().isNotEmpty
              ? item.summary!.trim()
              : (item.detail ?? '').trim();
          final source = OverviewStorySource(
            feedId: feed.id,
            feedTitle: feed.title,
            feedLanguage:
                Constants.resolveFeedLanguage(feed.id, feed.language),
            feedImageUrl: feed.imageUrl,
            feedUrl: feed.url,
            article: item,
          );
          extraStories.add(
            OverviewStory(
              id: 'extra-${ov.stories.length + extraStories.length + 1}',
              titleEn: item.title,
              titleTr: item.title,
              titleEl: item.title,
              narrativeEn: narrative,
              narrativeTr: narrative,
              narrativeEl: narrative,
              imageUrl: item.imageUrl,
              publishDate: item.publishDate,
              topic: item.effectiveTopic,
              sources: [source],
            ),
          );
        }

        if (extraStories.isNotEmpty) {
          ov.stories.addAll(extraStories);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _maxVisibleTopStories = 40;
          _isLoadingMoreStories = false;
        });
        _translateVisibleStoriesIfNeeded();
      }
    }
  }

  Future<List<FeedItem>?> _loadLatestCachedData() async {
    final feeds = await _feedItemsController.readRecentStored();
    final items = _extractSortedLatestItems(feeds);
    if (items != null && items.isNotEmpty) {
      _latestItemsNotifier.value = items;
    }
    return items;
  }

  Future<List<FeedItem>?> _loadLatestData() async {
    final feeds = await _feedItemsController.readRecent();
    final items = _extractSortedLatestItems(feeds);
    if (items != null) {
      _latestItemsNotifier.value = items;
    }
    return items;
  }

  List<FeedItem>? _extractSortedLatestItems(List<dynamic>? feeds) {
    if (feeds == null) {
      return null;
    }

    final feedItems = <FeedItem>[];
    for (final feed in feeds) {
      if (feed.items != null) {
        for (final item in feed.items!) {
          if (!item.isColumnist) {
            feedItems.add(item);
          }
        }
      }
    }
    feedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.newsViewModeNotifier,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        final mode = Constants.newsViewModeNotifier.value;
        final isTopMode = mode != 'latest';
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            titleSpacing: 4,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Transform.scale(
                        scale: 1.14,
                        child: Image.asset(
                          'assets/launcher/icon.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Constants.APP_NAME,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Center(
                  child: isTopMode
                      ? const OverviewLanguageSelector(lightOnDark: true)
                      : BulkTranslateIconButton(
                          controller: _bulkTranslateController,
                          itemFilter: _matchesVisibleLatestFilter,
                          lightOnDark: true,
                        ),
                ),
              ),
            ],
            bottom: AppBarModeTabs(
              modeNotifier: Constants.newsViewModeNotifier,
              topLabel: Constants.OVERVIEW,
              latestLabel: Constants.RECENT_NEWS,
            ),
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              const OfflineBanner(),
              const PwaInstallBanner(),
              ListenableBuilder(
                listenable: Listenable.merge([
                  Constants.sourceLanguageNotifier,
                  Constants.selectedFeedIdNotifier,
                  Constants.hiddenFeedsNotifier,
                  Constants.selectedTopicNotifier,
                  _latestItemsNotifier,
                ]),
                builder: (context, _) => SourceLanguageFilterBar(
                  showNewspaperSelector: !isTopMode,
                  countsBySource: _computeSourceCounts(isTopMode),
                  countsByNewspaper:
                      !isTopMode ? _computeNewspaperCounts() : null,
                ),
              ),
              ListenableBuilder(
                listenable: Listenable.merge([
                  Constants.sourceLanguageNotifier,
                  Constants.selectedFeedIdNotifier,
                  Constants.hiddenFeedsNotifier,
                  _latestItemsNotifier,
                ]),
                builder: (context, _) => TopicFilterChipBar(
                  countsByTopic: _computeTopicCounts(isTopMode),
                ),
              ),
              if (isTopMode && (_isRefreshing || _isLoadingMoreStories))
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: isTopMode
                    ? _buildBody(context)
                    : FeedItemsList(
                        loadDataStorageCallback: _loadLatestCachedData,
                        loadDataCallback: _loadLatestData,
                        wideTile: true,
                        bulkController: _bulkTranslateController,
                        bannerText: Constants.RECENT_NEWS_BANNER,
                        customFilter: (item) => Constants.matchesSelectedTopic(
                          item.effectiveTopic,
                        ),
                        extraListenable: Constants.selectedTopicNotifier,
                      ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 0),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _overview == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CenteredProgressIndicator(),
              const SizedBox(height: 14),
              Text(
                Constants.OVERVIEW_LOADING,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final overview = _overview;
    if (overview == null || overview.stories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Constants.OVERVIEW_EMPTY,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _refreshFromServer(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.showOriginalNotifier,
        Constants.overviewTranslateLanguageNotifier,
        Constants.sourceLanguageNotifier,
        Constants.hiddenFeedsNotifier,
        Constants.selectedTopicNotifier,
      ]),
      builder: (context, _) {
        final activeTranslateLang =
            Constants.overviewTranslateLanguageNotifier.value;
        final bannerLang = Constants.currentLanguage;
        final visibleStories = <(OverviewStory, List<OverviewStorySource>)>[];

        for (final story in overview.stories.take(_maxVisibleTopStories)) {
          final sources = _visibleSourcesFor(story);
          if (sources.isNotEmpty &&
              Constants.matchesSelectedTopic(story.effectiveTopic)) {
            visibleStories.add((story, sources));
          }
        }

        if (visibleStories.isEmpty) {
          return Center(
            child: Text(
              Constants.NO_NEWS_FOUND,
              style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_maxVisibleTopStories < 40 &&
                !_isLoadingMoreStories &&
                notification.metrics.maxScrollExtent > 0 &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 250) {
              _loadMoreTopStories();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => _refreshFromServer(forceRefresh: false),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: visibleStories.length +
                      2 +
                      (_isLoadingMoreStories ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return PageIntroBanner(
                        text: Constants.TOP_STORIES_BANNER,
                        emoji: '✨',
                      );
                    }
                    if (index == 1) {
                      return TopStoriesPodcastCard(
                        overview: overview,
                        defaultLanguage: bannerLang,
                      );
                    }
                    final storyIdx = index - 2;
                    if (storyIdx >= visibleStories.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0F2942),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              Constants.LOADING_MORE,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final (story, sources) = visibleStories[storyIdx];
                    final card = OverviewStoryCard(
                      story: story,
                      sources: sources,
                      activeTranslateLanguage: activeTranslateLang,
                    );
                    if (storyIdx >= 20) {
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('anim-${story.id}'),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1.0 - value)),
                            child: child,
                          ),
                        ),
                        child: card,
                      );
                    }
                    return card;
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OverviewLanguageSelector extends StatelessWidget {
  final bool lightOnDark;

  const OverviewLanguageSelector({super.key, this.lightOnDark = false});

  @override
  Widget build(BuildContext context) {
    return AppLanguageButton(lightOnDark: lightOnDark);
  }
}

void _openOverviewSource(BuildContext context, OverviewStorySource source) {
  final feed = source.toFeed();
  final cached = FeedItemsController.findCachedItemByUrl(
    source.article.url,
  );
  final feedItem = cached ?? source.toFeedItem();
  feedItem.feed ??= feed;

  final activeOverviewLang =
      Constants.overviewTranslateLanguageNotifier.value;
  final sourceLang = Constants.resolveFeedLanguage(
    source.feedId,
    source.feedLanguage,
  );
  if (activeOverviewLang != null && activeOverviewLang != sourceLang) {
    TranslateController.activeLanguageNotifier(feedItem).value =
        activeOverviewLang;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FeedItemView(item: feedItem),
    ),
  );
}

class OverviewStoryCard extends StatelessWidget {
  final OverviewStory story;
  final List<OverviewStorySource> sources;
  final String? activeTranslateLanguage;

  const OverviewStoryCard({
    super.key,
    required this.story,
    required this.sources,
    required this.activeTranslateLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final sourceLang = story.majorityLanguage(sources);
    final effectiveLang = activeTranslateLanguage ?? sourceLang;
    final title = story.titleFor(effectiveLang);
    final narrative = story.narrativeFor(effectiveLang);
    final resolvedImage = Constants.resolveImageUrl(story.imageUrl);
    final time = timeago.format(
      story.publishDate,
      locale: Constants.currentLanguage,
    );
    final shareItem = FeedItem(
      title,
      story.publishDate,
      narrative,
      narrative,
      story.imageUrl,
      sources.isNotEmpty ? sources.first.article.url : null,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: sources.isNotEmpty
            ? () => _openOverviewSource(context, sources.first)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: TopicBadgePill(
                            topicCode: story.effectiveTopic,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.35,
                          ),
                        ),
                        if (narrative.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            narrative,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey.shade700,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (resolvedImage.isNotEmpty) ...[
                    const SizedBox(width: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 124,
                        height: 92,
                        child: kIsWeb
                            ? Image.network(
                                resolvedImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              )
                            : CachedNetworkImage(
                                imageUrl: resolvedImage,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Text(
                            Constants.READ_FROM_LABEL,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                        for (final source in sources)
                          _NewspaperStoryChip(source: source),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ShareIconButton(item: shareItem, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OverviewStoryView extends StatelessWidget {
  final OverviewStory story;

  const OverviewStoryView({super.key, required this.story});

  List<OverviewStorySource> _visibleSources() {
    final filtered = story.sources
        .where(
          (s) => Constants.matchesSourceLanguageOnly(s.feedId, s.feedLanguage),
        )
        .toList();
    return filtered.isNotEmpty ? filtered : story.sources;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.overviewTranslateLanguageNotifier,
        Constants.sourceLanguageNotifier,
        Constants.hiddenFeedsNotifier,
      ]),
      builder: (context, _) {
        final sources = _visibleSources();
        final sourceLang = story.majorityLanguage(sources);
        final activeTranslateLang =
            Constants.overviewTranslateLanguageNotifier.value;
        final effectiveLang = activeTranslateLang ?? sourceLang;
        final title = story.titleFor(effectiveLang);
        final narrative = story.narrativeFor(effectiveLang);
        final resolvedImage = Constants.resolveImageUrl(story.imageUrl);
        final shareItem = FeedItem(
          title,
          story.publishDate,
          narrative,
          narrative,
          story.imageUrl,
          sources.isNotEmpty ? sources.first.article.url : null,
        );

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Transform.scale(
                      scale: 1.14,
                      child: Image.asset(
                        'assets/launcher/icon.png',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    Constants.OVERVIEW,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(
                  child: OverviewLanguageSelector(lightOnDark: true),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Spacer(),
                          ShareIconButton(item: shareItem, showLabel: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    height: 1.32,
                                  ),
                                ),
                                if (resolvedImage.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 280,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: kIsWeb
                                              ? Image.network(
                                                  resolvedImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) =>
                                                      const SizedBox.shrink(),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl: resolvedImage,
                                                  fit: BoxFit.cover,
                                                  errorWidget: (
                                                    context,
                                                    url,
                                                    error,
                                                  ) =>
                                                      const SizedBox.shrink(),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (narrative.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    narrative,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.65,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                                if (sources.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    Constants.COVERED_BY,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final source in sources)
                                        _NewspaperStoryChip(source: source),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NewspaperStoryChip extends StatelessWidget {
  final OverviewStorySource source;

  const _NewspaperStoryChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final feed = source.toFeed();

    return Tooltip(
      message: source.feedTitle,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openOverviewSource(context, source),
          child: FeedImage(
            item: feed,
            width: 68,
            height: 28,
            compact: true,
          ),
        ),
      ),
    );
  }
}
