import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/feed_list_tile.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:flutter/material.dart';

typedef LoadDataCallback = Future<List<Feed>> Function();

class FeedsList extends StatefulWidget {

  final LoadDataCallback loadDataStorageCallback;
  final LoadDataCallback loadDataServerCallback;

  FeedsList({Key key, @required this.loadDataStorageCallback, @required this.loadDataServerCallback }) : super(key: key);

  @override
  _FeedsListState createState() => _FeedsListState();
}

class _FeedsListState extends State<FeedsList> {
  List<Feed> _items;

  @override
  void initState() {
    super.initState();
    _loadDataAndUpdateState(widget.loadDataStorageCallback).whenComplete(()
        => _loadDataAndUpdateState(widget.loadDataServerCallback));
  }

  Future<void> _loadDataAndUpdateState(LoadDataCallback callback) async {
    var items = await callback();
    if (items != null) {
      setState(() {
        _items = items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _items == null
        ? CenteredProgressIndicator()
        : RefreshIndicator(
      child: ListView.separated(
        itemCount: _items.length,
        padding: const EdgeInsets.only(top: kToolbarHeight + 75),
        separatorBuilder: (BuildContext context, int index) =>
        const Divider(),
        itemBuilder: (context, index) {
          return FeedListTile(item: _items[index]);
        },
      ),
      onRefresh: () async {
        await _loadDataAndUpdateState(widget.loadDataServerCallback);
      },
    );
  }
}
