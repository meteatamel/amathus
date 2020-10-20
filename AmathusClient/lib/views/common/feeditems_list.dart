import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/feeditem_list_tile.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:flutter/material.dart';

typedef LoadDataCallback = Future<List<FeedItem>> Function();

class FeedItemsList extends StatefulWidget {

  final LoadDataCallback loadDataCallback;

  FeedItemsList({Key key, @required this.loadDataCallback}) : super(key: key);

  @override
  _FeedItemsListState createState() => _FeedItemsListState();
}

class _FeedItemsListState extends State<FeedItemsList> {

  List<FeedItem> _items;

  @override
  void initState() {
    super.initState();
    _loadDataAndUpdateState().whenComplete(() => {});
  }

  Future<void> _loadDataAndUpdateState() async {
    var items = await widget.loadDataCallback();
    setState(() {
      _items = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: _items == null
          ? CenteredProgressIndicator()
          : ListView.separated(
              itemCount: _items.length,
              // TODO: Add or remove after ads are fixed
              //padding: const EdgeInsets.only(top: kToolbarHeight + 75),
              padding: const EdgeInsets.only(top: 10),
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
              itemBuilder: (context, index) {
                return FeedItemListTile(item: _items[index]);
              }),
      onRefresh: () async {
        await _loadDataAndUpdateState();
      },
    );
  }
}
