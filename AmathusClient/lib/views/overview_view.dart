import 'package:amathus/controllers/overview_controller.dart';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/flag_icon.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:amathus/views/common/source_language_filter_bar.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  NewsOverview? _overview;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
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
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          SourceLanguageFilterBar(
            trailing: _OverviewLanguageSelector(),
          ),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 0),
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
        Constants.sourceLanguageNotifier,
        Constants.hiddenFeedsNotifier,
      ]),
      builder: (context, _) {
        final lang = Constants.currentLanguage;
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
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _OverviewHeaderBanner(
                      overview: overview,
                      language: lang,
                    );
                  }
                  final (story, sources) = visibleStories[index - 1];
                  return _OverviewStoryCard(
                    story: story,
                    sources: sources,
                    language: lang,
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

class _OverviewLanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = Constants.currentLanguage;
    return PopupMenuButton<String>(
      tooltip: Constants.LANGUAGE_TITLE,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (lang) => Constants.setLanguage(lang),
      itemBuilder: (context) => [
        for (final entry in const [
          ('en', 'English'),
          ('tr', 'Türkçe'),
          ('el', 'Ελληνικά'),
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
                      fontWeight: current == entry.$1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (current == entry.$1) ...[
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
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF93C5FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 16,
              color: Color(0xFF1D4ED8),
            ),
            const SizedBox(width: 6),
            Text(
              Constants.READ_IN_LABEL,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 6),
            FlagIcon(languageCode: current, width: 18, height: 13),
            const SizedBox(width: 6),
            Text(
              Constants.languageLabelFor(current),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF1D4ED8),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewHeaderBanner extends StatelessWidget {
  final NewsOverview overview;
  final String language;

  const _OverviewHeaderBanner({
    required this.overview,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final summary = overview.summaryFor(language);
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2942), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 20,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.94),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStoryCard extends StatelessWidget {
  final OverviewStory story;
  final List<OverviewStorySource> sources;
  final String language;

  const _OverviewStoryCard({
    required this.story,
    required this.sources,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final title = story.titleFor(language);
    final narrative = story.narrativeFor(language);
    final resolvedImage = Constants.resolveImageUrl(story.imageUrl);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.32,
                        ),
                      ),
                      if (narrative.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          narrative,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF334155),
                            height: 1.55,
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
                      width: 132,
                      height: 98,
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
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final source in sources)
                  _NewspaperStoryChip(source: source),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewspaperStoryChip extends StatelessWidget {
  final OverviewStorySource source;

  const _NewspaperStoryChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final feed = source.toFeed();
    final feedItem = source.toFeedItem();
    final hasLogo = Constants.resolveImageUrl(feed.imageUrl).isNotEmpty;

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FeedItemView(item: feedItem),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLogo) ...[
                FeedImage(
                  item: feed,
                  width: 54,
                  height: 22,
                  compact: true,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                source.feedTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F2942),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
