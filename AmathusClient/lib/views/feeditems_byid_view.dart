import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/feed_items_list.dart';
import 'package:flutter/material.dart';

class FeedItemsByIdView extends StatefulWidget {

  final Feed feed;

  FeedItemsByIdView({Key key, @required this.feed}) : super(key: key);

  @override
  _FeedItemsByIdViewState createState() => _FeedItemsByIdViewState();
}

class _FeedItemsByIdViewState extends State<FeedItemsByIdView> {

  FeedItemsController _controller;

  _FeedItemsByIdViewState() {
    _controller = FeedItemsController();
  }

  Future<List<FeedItem>> loadData() async {
    final feed = await _controller.readById(widget.feed.id);
    return feed == null? null : feed.items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(widget.feed.title)),
        body: FeedItemsList(loadDataCallback: loadData));
  }
}
