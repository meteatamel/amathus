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

  @override
  void initState() {
    super.initState();
    loadCachedData();
    _loadInitialOverview();
  }

  @override
  void dispose() {
    _itemsNotifier.dispose();
    _columnistFeedIdsNotifier.dispose();
    super.dispose();
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
                    Constants.COLUMNISTS,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
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
              const PwaInstallBanner(),
              SourceLanguageFilterBar(
                showNewspaperSelector: !isTopMode,
                allowedNewspaperIdsListenable:
                    !isTopMode ? _columnistFeedIdsNotifier : null,
              ),
              if (isTopMode && _isRefreshingOverview)
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
                        bannerEmoji: '✍️',
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

        for (final story in overview.stories) {
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

        return RefreshIndicator(
          onRefresh: () => _refreshOverviewFromServer(forceRefresh: false),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: visibleStories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return PageIntroBanner(
                      text: Constants.TOP_COLUMNS_BANNER,
                      emoji: '✍️',
                    );
                  }
                  final (story, sources) = visibleStories[index - 1];
                  final item = _buildTopColumnFeedItem(
                    story,
                    sources.first,
                    activeTranslateLang,
                  );
                  return FeedItemListTileWide(item: item);
                },
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
