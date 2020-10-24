import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
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
            title: _titleText(),
            subtitle: _timeText(),
            trailing: _itemImage(),
            onTap: () => {
                  Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: FeedItemView(item: item)))
                })));
  }

  Widget _titleText() {
    return new Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
        child: Text(item.title,
            style: TextStyle(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis));
  }

  Widget _timeText() {
    var time = "${timeago.format(item.publishDate, locale: 'tr')}";
    return new Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
        child: Text(time));
  }

  Widget _itemImage() {

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