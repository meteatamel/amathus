import 'package:amathus/controllers/feed_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:amathus/ad_manager.dart';

class FeedView extends StatefulWidget {
  final Feed feed;

  FeedView({Key key, @required this.feed}) : super(key: key);

  @override
  _FeedViewState createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(widget.feed.title)),
        body: FutureBuilder<Feed>(
            future: fetchFeed(widget.feed.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                var feedItems = snapshot.data.items;
                return RefreshIndicator(
                    child: ListView.separated(
                        itemCount: feedItems.length,
                        separatorBuilder: (BuildContext context,
                            int index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = feedItems[index];
                          return ListTile(
                              contentPadding: const EdgeInsets.only(top: kToolbarHeight + 75),
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
                        setState(() {});
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
