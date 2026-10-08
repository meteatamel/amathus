import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/feeditem_list_tile.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:flutter/material.dart';

import 'feeditem_list_tile_wide.dart';

typedef LoadDataCallback = Future<List<FeedItem>?> Function();

class FeedItemsList extends StatefulWidget {
  final LoadDataCallback? loadDataStorageCallback;
  final LoadDataCallback loadDataCallback;
  final bool wideTile;
  final BulkTranslateController? bulkController;

  const FeedItemsList({
    super.key,
    this.loadDataStorageCallback,
    required this.loadDataCallback,
    this.wideTile = false,
    this.bulkController,
  });

  @override
  State<FeedItemsList> createState() => _FeedItemsListState();
}

class _FeedItemsListState extends State<FeedItemsList> {
  List<FeedItem>? _items;
  bool _isRefreshing = false;

  bool _matchesFilter(FeedItem item) {
    return item.feed == null ||
        Constants.matchesSourceLanguage(
          item.feed?.id,
          item.feed?.language,
        );
  }

  @override
  void initState() {
    super.initState();
    Constants.sourceLanguageNotifier.addListener(_onFilterChanged);
    Constants.hiddenFeedsNotifier.addListener(_onFilterChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    Constants.sourceLanguageNotifier.removeListener(_onFilterChanged);
    Constants.hiddenFeedsNotifier.removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() {
    final bulk = widget.bulkController;
    final activeLang = bulk?.activeLanguageNotifier.value;
    if (bulk != null && activeLang != null && _items != null) {
      bulk.translateAll(activeLang, filter: _matchesFilter);
    }
  }

  Future<void> _loadInitialData() async {
    final storageCallback = widget.loadDataStorageCallback;
    if (storageCallback != null) {
      final cachedItems = await storageCallback();
      if (cachedItems != null && cachedItems.isNotEmpty) {
        widget.bulkController?.setItems(cachedItems, filter: _matchesFilter);
        if (mounted) {
          setState(() {
            _items = cachedItems;
          });
        }
      }
    }
    await _loadDataAndUpdateState();
  }

  Future<void> _loadDataAndUpdateState() async {
    if (mounted && _items != null) {
      setState(() {
        _isRefreshing = true;
      });
    }

    final items = await widget.loadDataCallback();
    if (items != null) {
      widget.bulkController?.setItems(items, filter: _matchesFilter);
      if (mounted) {
        setState(() {
          _items = items;
          _isRefreshing = false;
        });
      }
    } else {
      final fallback = _items ?? <FeedItem>[];
      if (_items == null) {
        widget.bulkController?.setItems(fallback, filter: _matchesFilter);
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
        Constants.sourceLanguageNotifier,
        Constants.hiddenFeedsNotifier,
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
          content = RefreshIndicator(
            onRefresh: _loadDataAndUpdateState,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return widget.wideTile
                        ? FeedItemListTileWide(item: filteredItems[index])
                        : FeedItemListTile(item: filteredItems[index]);
                  },
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (_isRefreshing)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
