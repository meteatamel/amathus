import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

import 'common/drawer.dart';

class FeedItemsRecentView extends StatelessWidget {

  static const String routeName = '/feeds-recent';

  final FeedItemsController _controller = FeedItemsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(Constants.RECENT_NEWS)),
        drawer: AppDrawer(),
        body: FeedItemsList(loadDataCallback: loadData)
    );
  }

  Future<List<FeedItem>> loadData() async {
    final feeds = await _controller.readRecent();
    final feedItems = new List<FeedItem>();
    if (feeds == null) {
      return null;
    }

    feeds.forEach((feed) => feedItems.addAll(feed.items));
    // TODO: Need to do this on the server side?
    feedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return feedItems;
  }
}
