import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedItemListTile extends StatelessWidget {
  final FeedItem item;

  FeedItemListTile({Key key, @required this.item})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        //height: 100,
        child: Card(
        elevation: 5,
        child: ListTile(
            title: Text(item.title, maxLines: 3, overflow: TextOverflow.ellipsis),
            subtitle: _subtitleText(),
            leading: _leadingImage(),
            //trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FeedItemView(item: item)))
                })));
  }

  Widget _subtitleText() {
    var subtitle = "${timeago.format(item.publishDate, locale: 'tr')}";
//    if (item.feed != null) {
//      subtitle = "${item.feed.title} • $subtitle";
//    }
    return Text(subtitle);
  }

  Widget _leadingImage() {

    var childWidget;

    if (item.imageUrl == null) {
      childWidget = Image.asset("assets/newsicon-128px.png");
    }
    else {
      childWidget = CachedNetworkImage(
          imageUrl: item.imageUrl,
          placeholder: (context, url) => new LinearProgressIndicator(),
          errorWidget: (context, url, error) =>
              Image.asset("assets/newsicon-128px.png"));
    }

    // Need to wrap into a SizedBox for some reason
    return SizedBox(
        width: 100.0,
        child: childWidget);
  }
}