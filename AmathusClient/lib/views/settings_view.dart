import 'package:amathus/controllers/feeds_storage.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(Constants.SETTINGS)),
        drawer: AppDrawer(),
        body: _ReorderableFeedList());
  }
}

class _ReorderableFeedList extends StatefulWidget {
  @override
  _ReorderableFeedListState createState() => _ReorderableFeedListState();
}

class _ReorderableFeedListState extends State<_ReorderableFeedList> {
  FeedsStorage _storage;
  List<Feed> _items;

  _ReorderableFeedListState() {
    _storage = FeedsStorage();
  }

  @override
  void initState() {
    super.initState();

    // TODO: Possible that there's no stored feeds.
    _storage.read().then((value) => {setState(() => _items = value)});
  }

  @override
  Widget build(BuildContext context) {
    return _items == null
        ? CenteredProgressIndicator()
        : ReorderableListView(
            header: Container(
                padding: EdgeInsets.all(10),
                child: Text(Constants.REORDER_NEWS,
                    style: TextStyle(fontSize: 18))),
            onReorder: _onReorder,
            scrollDirection: Axis.vertical,
            children: [
              for (final item in _items)
                _FeedCard(key: ValueKey(item.id), item: item),
            ],
          );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Feed item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    _storage.write(_items);
  }
}

class _FeedCard extends StatelessWidget {
  final Feed item;

  _FeedCard({Key key, this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
      title: Container(
          padding: EdgeInsets.all(10),
          child: Text(item.title, style: TextStyle(fontSize: 16))),
      trailing: Icon(Icons.reorder, size: 25),
    ));
  }
}
