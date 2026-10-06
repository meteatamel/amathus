import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'common/drawer.dart';

class FeedItemsRecentView extends StatelessWidget {
  final FeedItemsController _controller = FeedItemsController();

  FeedItemsRecentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(Constants.RECENT_NEWS),
      ),
      drawer: const AppDrawer(),
      body: FeedItemsList(loadDataCallback: loadData, wideTile: true),
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 0),
    );
  }

  Future<List<FeedItem>?> loadData() async {
    final feeds = await _controller.readRecent();
    if (feeds == null) {
      return null;
    }

    final feedItems = <FeedItem>[];
    for (final feed in feeds) {
      if (feed.items != null) {
        feedItems.addAll(feed.items!);
      }
    }
    feedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return feedItems;
  }
}
