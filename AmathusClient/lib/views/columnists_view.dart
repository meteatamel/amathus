import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/controllers/overview_controller.dart';
import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feeditem_list_tile_wide.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:amathus/views/common/offline_banner.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:amathus/views/common/pwa_install.dart';
import 'package:amathus/views/common/source_language_filter_bar.dart';
import 'package:amathus/views/common/top_stories_podcast_card.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:amathus/views/overview_view.dart';
import 'package:flutter/material.dart';

class ColumnistsView extends StatefulWidget {
  final Future<NewsOverview?> Function()? loadCachedOverviewCallback;
  final Future<NewsOverview?> Function({bool refresh})? loadServerOverviewCallback;

  const ColumnistsView({
    super.key,
    this.loadCachedOverviewCallback,
    this.loadServerOverviewCallback,
  });

  @override
  State<ColumnistsView> createState() => _ColumnistsViewState();
}

class _ColumnistsViewState extends State<ColumnistsView> {
  final OverviewController _overviewController =
      OverviewController(columnistsOnly: true);
  final FeedItemsController _controller = FeedItemsController();
  final BulkTranslateController _bulkTranslateController =
      BulkTranslateController();
  final ValueNotifier<List<FeedItem>> _itemsNotifier =
      ValueNotifier<List<FeedItem>>(const []);
  final ValueNotifier<Set<String>?> _columnistFeedIdsNotifier =
      ValueNotifier<Set<String>?>(null);

  NewsOverview? _overview;
  bool _isLoadingOverview = true;
  bool _isRefreshingOverview = false;
  int _maxVisibleTopStories = 20;
  bool _isLoadingMoreStories = false;

  @override
  void initState() {
    super.initState();
    if (widget.loadCachedOverviewCallback == null &&
        _overviewController.memoryCached != null &&
        _overviewController.memoryCached!.stories.isNotEmpty) {
      _overview = _overviewController.memoryCached;
      _isLoadingOverview = false;
    }
    Constants.overviewTranslateLanguageNotifier
        .addListener(_onTranslateLanguageChanged);
    ConnectivityController.instance.addReconnectListener(_onReconnected);
    loadCachedData();
    _loadInitialOverview();
  }

  @override
  void dispose() {
    Constants.overviewTranslateLanguageNotifier
        .removeListener(_onTranslateLanguageChanged);
    ConnectivityController.instance.removeReconnectListener(_onReconnected);
    _itemsNotifier.dispose();
    _columnistFeedIdsNotifier.dispose();
    super.dispose();
  }

  void _onReconnected() {
    _refreshOverviewFromServer(forceRefresh: false);
    loadData();
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

  Future<void> _loadInitialOverview() async {
    final cachedLoader =
        widget.loadCachedOverviewCallback ?? _overviewController.readStored;
    final cached = await cachedLoader();
    if (cached != null && cached.stories.isNotEmpty && mounted) {
      setState(() {
        _overview = cached;
        _isLoadingOverview = false;
      });
      _translateVisibleStoriesIfNeeded();
    }
    await _refreshOverviewFromServer(forceRefresh: false);
  }

  Future<void> _refreshOverviewFromServer({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        if (_overview != null) {
          _isRefreshingOverview = true;
        } else {
          _isLoadingOverview = true;
        }
      });
    }

    final serverLoader =
        widget.loadServerOverviewCallback ?? _overviewController.read;
    final fresh = await serverLoader(refresh: forceRefresh);
    if (!mounted) return;

    setState(() {
      if (fresh != null && fresh.stories.isNotEmpty) {
        _overview = fresh;
      }
      _isLoadingOverview = false;
      _isRefreshingOverview = false;
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

  bool _matchesVisibleFilter(FeedItem item) {
    return item.feed == null ||
        Constants.matchesSourceLanguage(
          item.feed?.id,
          item.feed?.language,
        );
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
      final list = _itemsNotifier.value;
      if (list.isEmpty) return null;
      var total = 0;
      for (final item in list) {
        final feedId = item.feed?.id;
        if (!Constants.isFeedVisible(feedId)) continue;
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

  Map<String, int>? _computeNewspaperCounts() {
    final list = _itemsNotifier.value;
    if (list.isEmpty) return null;
    final counts = <String, int>{'all': 0};
    var total = 0;
    for (final item in list) {
      final feedId = item.feed?.id.trim().toLowerCase();
      if (feedId == null || feedId.isEmpty) continue;
      if (!Constants.matchesSourceLanguageOnly(feedId, item.feed?.language)) {
        continue;
      }
      counts[feedId] = (counts[feedId] ?? 0) + 1;
      total++;
    }
    if (total == 0) return null;
    counts['all'] = total;
    return counts;
  }

  Future<void> _loadMoreTopColumns() async {
    if (_maxVisibleTopStories >= 40 || _isLoadingMoreStories) return;
    final ov = _overview;
    if (ov == null) return;

    setState(() {
      _isLoadingMoreStories = true;
    });

    try {
      final minSpinnerDelay =
          Future<void>.delayed(const Duration(milliseconds: 650));
      var allColumns = _itemsNotifier.value;
      if (allColumns.isEmpty) {
        allColumns = await loadCachedData() ?? const [];
      }
      if (allColumns.isEmpty) {
        allColumns = await loadData() ?? const [];
      }
      await minSpinnerDelay;

      if (ov.stories.length < 40 && allColumns.isNotEmpty) {
        final existingUrls = <String>{};
        for (final s in ov.stories) {
          for (final src in s.sources) {
            final u = (src.article.url ?? '').trim();
            if (u.isNotEmpty) existingUrls.add(u);
          }
        }

        final extraStories = <OverviewStory>[];
        for (final item in allColumns) {
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
              id: 'extra-col-${ov.stories.length + extraStories.length + 1}',
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

  FeedItem _buildTopColumnFeedItem(
    OverviewStory story,
    OverviewStorySource source,
    String? activeTranslateLang,
  ) {
    final cached = FeedItemsController.findCachedItemByUrl(source.article.url);
    final sourceLang = Constants.resolveFeedLanguage(
      source.feedId,
      source.feedLanguage,
    );
    final rawSummary = (source.article.summary ?? '').trim();
    final effectiveSummary = rawSummary.isNotEmpty
        ? rawSummary
        : ((cached?.summary ?? '').trim().isNotEmpty
            ? cached!.summary!
            : story.narrativeFor(sourceLang));
    final rawDetail = (source.article.detail ?? '').trim();
    final effectiveDetail =
        rawDetail.isNotEmpty ? rawDetail : (cached?.detail ?? effectiveSummary);
    final rawAuthor = (source.article.author ?? '').trim();
    final effectiveAuthor =
        rawAuthor.isNotEmpty ? rawAuthor : cached?.author;

    final item = FeedItem(
      source.article.title,
      source.article.publishDate,
      effectiveSummary,
      effectiveDetail,
      source.article.imageUrl ?? story.imageUrl ?? cached?.imageUrl,
      source.article.url,
      author: effectiveAuthor,
      isColumnist: true,
    )..feed = source.toFeed();

    TranslateController.seedOverviewTranslations(
      item,
      titleEl: story.titleEl,
      summaryEl: story.narrativeEl,
      titleTr: story.titleTr,
      summaryTr: story.narrativeTr,
      titleEn: story.titleEn,
      summaryEn: story.narrativeEn,
      activeTargetLang: activeTranslateLang,
    );
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.columnistsViewModeNotifier,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        final mode = Constants.columnistsViewModeNotifier.value;
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
                          itemFilter: _matchesVisibleFilter,
                          lightOnDark: true,
                        ),
                ),
              ),
            ],
            bottom: AppBarModeTabs(
              modeNotifier: Constants.columnistsViewModeNotifier,
              topLabel: Constants.TOP_COLUMNS,
              latestLabel: Constants.LATEST_COLUMNS,
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
                  _itemsNotifier,
                ]),
                builder: (context, _) => SourceLanguageFilterBar(
                  showNewspaperSelector: !isTopMode,
                  allowedNewspaperIdsListenable:
                      !isTopMode ? _columnistFeedIdsNotifier : null,
                  countsBySource: _computeSourceCounts(isTopMode),
                  countsByNewspaper:
                      !isTopMode ? _computeNewspaperCounts() : null,
                ),
              ),
              if (isTopMode && (_isRefreshingOverview || _isLoadingMoreStories))
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: isTopMode
                    ? _buildTopColumnsBody(context)
                    : FeedItemsList(
                        loadDataStorageCallback: loadCachedData,
                        loadDataCallback: loadData,
                        wideTile: true,
                        bulkController: _bulkTranslateController,
                        bannerText: Constants.COLUMNISTS_BANNER,
                        bannerEmoji: '📰',
                        columnistsOnly: true,
                      ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 1),
        );
      },
    );
  }

  Widget _buildTopColumnsBody(BuildContext context) {
    if (_isLoadingOverview && _overview == null) {
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
                onPressed: () => _refreshOverviewFromServer(forceRefresh: true),
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
      ]),
      builder: (context, _) {
        final activeTranslateLang =
            Constants.overviewTranslateLanguageNotifier.value;
        final visibleStories = <(OverviewStory, List<OverviewStorySource>)>[];

        for (final story in overview.stories.take(_maxVisibleTopStories)) {
          final sources = _visibleSourcesFor(story);
          if (sources.isNotEmpty) {
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
              _loadMoreTopColumns();
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => _refreshOverviewFromServer(forceRefresh: false),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: visibleStories.length +
                      1 +
                      (_isLoadingMoreStories ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return PageIntroBanner(
                        text: Constants.TOP_COLUMNS_BANNER,
                        emoji: '✨',
                      );
                    }
                    final storyIdx = index - 1;
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
                    final item = _buildTopColumnFeedItem(
                      story,
                      sources.first,
                      activeTranslateLang,
                    );
                    final tile = FeedItemListTileWide(item: item);
                    if (storyIdx >= 20) {
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('anim-col-${story.id}'),
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
                        child: tile,
                      );
                    }
                    return tile;
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<FeedItem>?> loadCachedData() async {
    final feeds = await _controller.readColumnistsStored();
    return _extractSortedItems(feeds);
  }

  Future<List<FeedItem>?> loadData() async {
    final feeds = await _controller.readColumnists();
    return _extractSortedItems(feeds);
  }

  List<FeedItem>? _extractSortedItems(List<dynamic>? feeds) {
    if (feeds == null) {
      return null;
    }

    final feedItems = <FeedItem>[];
    final feedIds = <String>{};
    for (final feed in feeds) {
      if (feed.items != null && feed.items!.isNotEmpty) {
        for (final item in feed.items!) {
          if (item.isColumnist) {
            feedItems.add(item);
            feedIds.add(feed.id.toString().trim().toLowerCase());
          }
        }
      }
    }
    feedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    _itemsNotifier.value = feedItems;
    if (feedIds.isNotEmpty) {
      _columnistFeedIdsNotifier.value = feedIds;
    }
    return feedItems;
  }
}
