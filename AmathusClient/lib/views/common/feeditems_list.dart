import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/feeditem_list_tile.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:flutter/material.dart';

import 'feeditem_list_tile_wide.dart';

typedef LoadDataCallback = Future<List<FeedItem>?> Function();

class FeedItemsList extends StatefulWidget {
  final LoadDataCallback loadDataCallback;
  final bool wideTile;

  const FeedItemsList({
    super.key,
    required this.loadDataCallback,
    this.wideTile = false,
  });

  @override
  State<FeedItemsList> createState() => _FeedItemsListState();
}

class _FeedItemsListState extends State<FeedItemsList> {
  List<FeedItem>? _items;

  @override
  void initState() {
    super.initState();
    _loadDataAndUpdateState();
  }

  Future<void> _loadDataAndUpdateState() async {
    final items = await widget.loadDataCallback();
    if (mounted) {
      setState(() {
        _items = items ?? <FeedItem>[];
      });
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
        final filteredItems = items
            .where(
              (item) =>
                  item.feed == null ||
                  Constants.matchesSourceLanguage(
                    item.feed?.id,
                    item.feed?.language,
                  ),
            )
            .toList();

        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              Constants.NO_NEWS_FOUND,
              style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600),
            ),
          );
        }

        return RefreshIndicator(
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
      },
    );
  }
}
