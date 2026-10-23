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
import 'package:amathus/views/common/flag_icon.dart';
import 'package:amathus/views/common/progress_indicator.dart';
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
  NewsOverview? _overview;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _feedItemsController.readRecentStored();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final cachedLoader = widget.loadCachedCallback ?? _controller.readStored;
    final cached = await cachedLoader();
    if (cached != null && cached.stories.isNotEmpty && mounted) {
      setState(() {
        _overview = cached;
        _isLoading = false;
      });
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
  }

  List<OverviewStorySource> _visibleSourcesFor(OverviewStory story) {
    return story.sources
        .where(
          (s) => Constants.matchesSourceLanguageOnly(s.feedId, s.feedLanguage),
        )
        .toList();
  }

  bool _matchesVisibleLatestFilter(FeedItem item) {
    return item.feed == null ||
        Constants.matchesSourceLanguage(
          item.feed?.id,
          item.feed?.language,
        );
  }

  Future<List<FeedItem>?> _loadLatestCachedData() async {
    final feeds = await _feedItemsController.readRecentStored();
    return _extractSortedLatestItems(feeds);
  }

  Future<List<FeedItem>?> _loadLatestData() async {
    final feeds = await _feedItemsController.readRecent();
    return _extractSortedLatestItems(feeds);
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
    return ValueListenableBuilder<String>(
      valueListenable: Constants.newsViewModeNotifier,
      builder: (context, mode, _) {
        final isTopMode = mode != 'latest';
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/launcher/icon.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    Constants.NEWS,
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
              SourceLanguageFilterBar(
                showNewspaperSelector: !isTopMode,
              ),
              if (isTopMode && _isRefreshing)
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
        Constants.overviewTranslateLanguageNotifier,
        Constants.sourceLanguageNotifier,
        Constants.hiddenFeedsNotifier,
      ]),
      builder: (context, _) {
        final activeTranslateLang =
            Constants.overviewTranslateLanguageNotifier.value;
        final bannerLang = activeTranslateLang ?? 'en';
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
          onRefresh: () => _refreshFromServer(forceRefresh: false),
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
                    return TopStoriesPodcastCard(
                      overview: overview,
                      defaultLanguage: bannerLang,
                    );
                  }
                  final (story, sources) = visibleStories[index - 1];
                  return OverviewStoryCard(
                    story: story,
                    sources: sources,
                    activeTranslateLanguage: activeTranslateLang,
                  );
                },
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.overviewTranslateLanguageNotifier,
      ]),
      builder: (context, _) {
        final activeLang = Constants.overviewTranslateLanguageNotifier.value;
        return PopupMenuButton<String>(
          tooltip: Constants.TRANSLATE,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (lang) {
            if (lang == 'original' || lang == activeLang) {
              Constants.setOverviewTranslateLanguage(null);
            } else {
              Constants.setOverviewTranslateLanguage(lang);
            }
          },
          itemBuilder: (context) => [
            for (final entry in const [
              ('el', 'Ελληνικά'),
              ('tr', 'Türkçe'),
              ('en', 'English'),
            ])
              PopupMenuItem<String>(
                value: entry.$1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlagIcon(languageCode: entry.$1, width: 20, height: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: activeLang == entry.$1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (activeLang == entry.$1) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Color(0xFF1D4ED8),
                      ),
                    ],
                  ],
                ),
              ),
            if (activeLang != null) ...[
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'original',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.restore_rounded,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Constants.SHOW_ORIGINAL,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: lightOnDark
                  ? (activeLang == null
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white)
                  : (activeLang == null
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFFEFF6FF)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: lightOnDark
                    ? (activeLang == null
                        ? Colors.white.withValues(alpha: 0.30)
                        : Colors.white)
                    : (activeLang == null
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF93C5FD)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 15,
                  color: lightOnDark
                      ? (activeLang == null
                          ? Colors.white
                          : const Color(0xFF0F2942))
                      : (activeLang == null
                          ? const Color(0xFF0F2942)
                          : const Color(0xFF1D4ED8)),
                ),
                const SizedBox(width: 5),
                if (activeLang != null) ...[
                  FlagIcon(languageCode: activeLang, width: 18, height: 13),
                  const SizedBox(width: 5),
                  Text(
                    Constants.languageLabelFor(activeLang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: lightOnDark
                          ? const Color(0xFF0F2942)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ] else
                  Text(
                    Constants.READ_IN_BUTTON,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: lightOnDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: lightOnDark
                      ? (activeLang == null
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF0F2942))
                      : (activeLang == null
                          ? const Color(0xFF475569)
                          : const Color(0xFF1D4ED8)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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
                if (activeTranslateLanguage != null &&
                    activeTranslateLanguage != sourceLang)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SourceAndTranslationBadges(
                      sourceLang: sourceLang,
                      activeTranslationLang: activeTranslateLanguage,
                      compact: true,
                    ),
                  ),
                ShareIconButton(item: shareItem),
              ],
            ),
          ],
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
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/launcher/icon.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
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
                          SourceAndTranslationBadges(
                            sourceLang: sourceLang,
                            activeTranslationLang:
                                activeTranslateLang != sourceLang
                                    ? activeTranslateLang
                                    : null,
                          ),
                          const Spacer(),
                          const OverviewLanguageSelector(),
                          const SizedBox(width: 8),
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
          onTap: () {
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
            if (activeOverviewLang != null &&
                activeOverviewLang != sourceLang) {
              TranslateController.activeLanguageNotifier(feedItem).value =
                  activeOverviewLang;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeedItemView(item: feedItem),
              ),
            );
          },
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
