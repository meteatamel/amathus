import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/feeditem_list_tile.dart';
import 'package:amathus/views/common/offline_banner.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:amathus/views/common/top_stories_podcast_card.dart';
import 'package:flutter/material.dart';

import 'feeditem_list_tile_wide.dart';

typedef LoadDataCallback = Future<List<FeedItem>?> Function();

class FeedItemsList extends StatefulWidget {
  final LoadDataCallback? loadDataStorageCallback;
  final LoadDataCallback loadDataCallback;
  final bool wideTile;
  final BulkTranslateController? bulkController;
  final String? bannerText;
  final IconData? bannerIcon;
  final bool Function(FeedItem)? customFilter;
  final Listenable? extraListenable;
  final bool columnistsOnly;

  const FeedItemsList({
    super.key,
    this.loadDataStorageCallback,
    required this.loadDataCallback,
    this.wideTile = false,
    this.bulkController,
    this.bannerText,
    this.bannerIcon,
    this.customFilter,
    this.extraListenable,
    this.columnistsOnly = false,
  });

  @override
  State<FeedItemsList> createState() => _FeedItemsListState();
}

class _FeedItemsListState extends State<FeedItemsList> {
  final FeedItemsController _feedItemsController = FeedItemsController();
  final Set<String> _loadedFullFeedIds = <String>{};
  List<FeedItem>? _items;
  bool _isRefreshing = false;

  bool _matchesFilter(FeedItem item) {
    final baseMatch = item.feed == null ||
        Constants.matchesSourceLanguage(
          item.feed?.id,
          item.feed?.language,
        );
    if (!baseMatch) return false;
    if (widget.customFilter != null && !widget.customFilter!(item)) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    Constants.languageNotifier.addListener(_onFilterChanged);
    Constants.showOriginalNotifier.addListener(_onFilterChanged);
    Constants.sourceLanguageNotifier.addListener(_onFilterChanged);
    Constants.selectedFeedIdNotifier.addListener(_onSelectedFeedChanged);
    Constants.hiddenFeedsNotifier.addListener(_onFilterChanged);
    widget.extraListenable?.addListener(_onFilterChanged);
    ConnectivityController.instance.addReconnectListener(_loadDataAndUpdateState);
    _loadInitialData();
  }

  @override
  void dispose() {
    Constants.languageNotifier.removeListener(_onFilterChanged);
    Constants.showOriginalNotifier.removeListener(_onFilterChanged);
    Constants.sourceLanguageNotifier.removeListener(_onFilterChanged);
    Constants.selectedFeedIdNotifier.removeListener(_onSelectedFeedChanged);
    Constants.hiddenFeedsNotifier.removeListener(_onFilterChanged);
    widget.extraListenable?.removeListener(_onFilterChanged);
    ConnectivityController.instance.removeReconnectListener(_loadDataAndUpdateState);
    super.dispose();
  }

  void _onSelectedFeedChanged() {
    _onFilterChanged();
    final selectedId = Constants.selectedFeedIdNotifier.value;
    if (selectedId != null && !_loadedFullFeedIds.contains(selectedId)) {
      _loadFullFeedFor(selectedId);
    }
  }

  Future<void> _loadFullFeedFor(String feedId) async {
    _loadedFullFeedIds.add(feedId);
    final feed = await _feedItemsController.readById(feedId);
    if (feed?.items == null || feed!.items!.isEmpty || !mounted) {
      return;
    }

    final current = List<FeedItem>.from(_items ?? const []);
    final existingUrls = current
        .map((e) => '${e.feed?.id ?? ''}:${e.url ?? e.title}')
        .toSet();

    var added = false;
    for (final item in feed.items!) {
      if (widget.columnistsOnly && !item.isColumnist) {
        continue;
      }
      if (!widget.columnistsOnly && item.isColumnist) {
        continue;
      }
      item.feed ??= feed;
      final key = '${feed.id}:${item.url ?? item.title}';
      if (existingUrls.add(key)) {
        current.add(item);
        added = true;
      }
    }

    if (added && mounted) {
      current.sort((a, b) => b.publishDate.compareTo(a.publishDate));
      _syncBulkTranslation(current);
      setState(() {
        _items = current;
      });
    }
  }

  void _syncBulkTranslation(List<FeedItem>? items) {
    final bulk = widget.bulkController;
    if (bulk == null || items == null) return;
    final targetLang = Constants.effectiveTranslateLanguage;
    if (targetLang == null) {
      bulk.setItems(items, filter: _matchesFilter);
      bulk.clearAll();
    } else {
      bulk.activeLanguageNotifier.value = targetLang;
      bulk.setItems(items, filter: _matchesFilter);
    }
  }

  void _onFilterChanged() {
    _syncBulkTranslation(_items);
  }

  Future<void> _loadInitialData() async {
    final storageCallback = widget.loadDataStorageCallback;
    if (storageCallback != null) {
      final cachedItems = await storageCallback();
      if (cachedItems != null && cachedItems.isNotEmpty) {
        _syncBulkTranslation(cachedItems);
        if (mounted) {
          setState(() {
            _items = cachedItems;
          });
        }
      }
    }
    await _loadDataAndUpdateState();
    final selectedId = Constants.selectedFeedIdNotifier.value;
    if (selectedId != null) {
      await _loadFullFeedFor(selectedId);
    }
  }

  Future<void> _loadDataAndUpdateState() async {
    if (mounted && _items != null) {
      setState(() {
        _isRefreshing = true;
      });
    }

    final items = await widget.loadDataCallback();
    if (items != null) {
      _syncBulkTranslation(items);
      if (mounted) {
        setState(() {
          _items = items;
          _isRefreshing = false;
        });
      }
    } else {
      final fallback = _items ?? <FeedItem>[];
      if (_items == null) {
        _syncBulkTranslation(fallback);
      }
      if (mounted) {
        setState(() {
          _items = fallback;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) {
      return const CenteredProgressIndicator();
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.showOriginalNotifier,
        Constants.sourceLanguageNotifier,
        Constants.selectedFeedIdNotifier,
        Constants.hiddenFeedsNotifier,
        if (widget.extraListenable != null) widget.extraListenable!,
      ]),
      builder: (context, _) {
        final filteredItems = items.where(_matchesFilter).toList();

        Widget content;
        if (filteredItems.isEmpty) {
          content = Center(
            child: Text(
              Constants.NO_NEWS_FOUND,
              style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600),
            ),
          );
        } else {
          final banner = widget.bannerText;
          final hasBanner = banner != null && banner.trim().isNotEmpty;
          final totalCount = filteredItems.length + (hasBanner ? 1 : 0);

          content = RefreshIndicator(
            onRefresh: _loadDataAndUpdateState,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: totalCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (hasBanner && index == 0) {
                      return PageIntroBanner(
                        text: banner,
                        icon: widget.bannerIcon ??
                            (widget.columnistsOnly
                                ? Icons.edit_note_rounded
                                : Icons.schedule_rounded),
                      );
                    }
                    final itemIndex = hasBanner ? index - 1 : index;
                    return widget.wideTile
                        ? FeedItemListTileWide(item: filteredItems[itemIndex])
                        : FeedItemListTile(item: filteredItems[itemIndex]);
                  },
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
