import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/extensions.dart';
import 'common/drawer.dart';

class FeedItemsRecentView extends StatelessWidget {
  final FeedItemsController _controller = FeedItemsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar:
            AppBar(centerTitle: true, title: new Text(Constants.RECENT_NEWS))
                .withBottomAdmobBanner(context),
        drawer: AppDrawer(),
        body: FeedItemsList(loadDataCallback: loadData, wideTile: true),
        bottomNavigationBar: AppBottomNavigationBar(selectedIndex: 1));
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
