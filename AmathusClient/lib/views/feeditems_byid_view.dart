import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:flutter/material.dart';

class FeedItemsByIdView extends StatelessWidget {

  final Feed feed;
  final FeedItemsController _controller = FeedItemsController();

  FeedItemsByIdView({Key key, @required this.feed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(feed.title)),
        body: FeedItemsList(loadDataCallback: loadData));
  }

  Future<List<FeedItem>> loadData() async {
    final updatedFeed = await _controller.readById(feed.id);
    return updatedFeed == null? null : updatedFeed.items;
  }
}
