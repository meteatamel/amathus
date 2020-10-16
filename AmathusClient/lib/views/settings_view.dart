import 'package:amathus/controllers/feeds_storage.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class SettingsView extends StatefulWidget {

  static const String routeName = '/settings';

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {

  FeedsStorage _storage;
  Future _fetchFeedsFuture;

  _SettingsViewState() {
    _storage = FeedsStorage();
  }

  @override
  void initState() {
    super.initState();
    _fetchFeedsFuture = _storage.read();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(Constants.SETTINGS)),
        drawer: AppDrawer(),
        body: FutureBuilder<List<Feed>>(
            future: _fetchFeedsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                var feeds = snapshot.data;
                return ReorderableListView(
                   header: Container(
                      padding: EdgeInsets.all(10),
                      child: Text(Constants.REORDER_NEWS, style: TextStyle(fontSize: 18))),
                  onReorder: _onReorder,
                  scrollDirection: Axis.vertical,
                  children: [
                    for (final item in feeds)
                      ListTile(
                          key: ValueKey(item.id),
                          title: Container(
                              padding: EdgeInsets.all(10),
                              child: Text(item.title, style: TextStyle(fontSize: 16))),
                          trailing: Icon(Icons.reorder, size:25),
                      ),
                  ],
                );
              }

              return Center(
                  child: SizedBox(
                      height: 200.0,
                      width: 200.0,
                      child: CircularProgressIndicator()));
            }));
  }

  void _onReorder(int oldIndex, int newIndex) {
    // TODO: Implement
  }
}
