import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:amathus/utils/constants.dart' as Constants;

import 'common/drawer.dart';

class FeedItemsRecentView extends StatefulWidget {

  static const String routeName = '/feeds-recent';

  @override
  _FeedItemsRecentViewState createState() => _FeedItemsRecentViewState();
}

class _FeedItemsRecentViewState extends State<FeedItemsRecentView> {

  FeedItemsController _controller;
  Future<List<Feed>> _futureData;

  _FeedItemsRecentViewState() {
    _controller = FeedItemsController();
  }

  @override
  void initState() {
    super.initState();
    _futureData = _controller.readRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(Constants.RECENT_NEWS)),
        drawer: AppDrawer(),
        body: FutureBuilder<List<Feed>>(
            future: _futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                final feeds = snapshot.data;
                final feedItems = new List<FeedItem>();
                feeds.forEach((feed) => feedItems.addAll(feed.items));
                // TODO: Need to do this on the server side.
                feedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));
                return RefreshIndicator(
                    child: ListView.separated(
                        itemCount: feedItems.length,
                        padding: const EdgeInsets.only(top: kToolbarHeight + 75),
                        separatorBuilder: (BuildContext context,
                            int index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = feedItems[index];
                          return ListTile(
                            //contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              title: Text(item.title),
                              subtitle: Text(
                                  timeago.format(
                                      item.publishDate, locale: 'tr')),
                              leading: SizedBox(
                                  width: 100.0,
                                  child: item.imageUrl != null
                                      ? CachedNetworkImage(
                                      imageUrl: item.imageUrl,
                                      placeholder: (context, url) =>
                                      new LinearProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Image.asset(
                                              "assets/newsicon-128px.png"))
                                      : Image.asset(
                                      "assets/newsicon-128px.png")),
                              trailing: Icon(Icons.keyboard_arrow_right),
                              onTap: () =>
                              { Navigator.push(context,
                                  MaterialPageRoute(builder: (context) =>
                                      FeedItemView(item: item)))
                              });
                        }),
                      onRefresh: () async {
                        _futureData = _controller.readRecent();
                      },
                );
              }

              // if (snapshot.hasError) {
                // TODO: Handle
              //}

              return Center(
                  child: SizedBox(
                      height: 200.0,
                      width: 200.0,
                      child: CircularProgressIndicator()));
            }));
  }
}