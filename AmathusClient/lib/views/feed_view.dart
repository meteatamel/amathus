import 'package:amathus/models/feed_model.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedView extends StatelessWidget {
  final Feed feed;

  FeedView({Key key, @required this.feed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: new Text(feed.title)),
      body: ListView.separated(
        itemCount: feed.items.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemBuilder: (context, index) {
          final item = feed.items[index];

          return ListTile(
            //contentPadding: EdgeInsets.symmetric(horizontal: 16),
              title: Text(item.title),
              subtitle: Text(timeago.format(item.publishDate, locale: 'tr')),
              leading: SizedBox(
                  width: 100.0,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      placeholder: (context, url) =>
                      new LinearProgressIndicator(),
                      errorWidget: (context, url, error) => Image.asset("assets/newsicon-128px.png")
                  )
                      : Image.asset("assets/newsicon-128px.png")),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () => {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FeedItemView(item: item)))
              });
        },
      ),
    );
  }
}
