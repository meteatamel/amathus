import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/feed_list_tile.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:flutter/material.dart';

typedef LoadDataCallback = Future<List<Feed>?> Function();

class FeedsList extends StatefulWidget {
  final LoadDataCallback loadDataStorageCallback;
  final LoadDataCallback loadDataServerCallback;

  const FeedsList({
    super.key,
    required this.loadDataStorageCallback,
    required this.loadDataServerCallback,
  });

  @override
  State<FeedsList> createState() => _FeedsListState();
}

class _FeedsListState extends State<FeedsList> {
  List<Feed>? _items;

  @override
  void initState() {
    super.initState();
    _loadDataAndUpdateState(widget.loadDataStorageCallback).whenComplete(
      () => _loadDataAndUpdateState(widget.loadDataServerCallback),
    );
  }

  Future<void> _loadDataAndUpdateState(LoadDataCallback callback) async {
    final items = await callback();
    if (mounted && items != null) {
      setState(() {
        _items = items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) {
      return const CenteredProgressIndicator();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDataAndUpdateState(widget.loadDataServerCallback);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 980
              ? 3
              : width >= 620
                  ? 2
                  : 1;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: crossAxisCount == 1
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return FeedListTile(item: items[index]);
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 80,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return FeedListTile(item: items[index]);
                      },
                    ),
            ),
          );
        },
      ),
    );
  }
}
