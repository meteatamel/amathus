import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedItemListTile extends StatelessWidget {
  final FeedItem item;
  final bool displayFeedTitle;

  FeedItemListTile({Key key, @required this.item, this.displayFeedTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
            title: Text(item.title),
            subtitle: Text(getSubtitle()),
            leading: SizedBox(
                width: 100.0,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        placeholder: (context, url) =>
                            new LinearProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            Image.asset("assets/newsicon-128px.png"))
                    : Image.asset("assets/newsicon-128px.png")),
            //trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FeedItemView(item: item)))
                }));
  }

  String getSubtitle() {
    var subtitle = "${timeago.format(item.publishDate, locale: 'tr')}";
    if (displayFeedTitle && item.feed != null) {
      subtitle = "${item.feed.title} • $subtitle";
    }
    return subtitle;
  }
}
