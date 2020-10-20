import 'package:amathus/models/feed.dart';
import 'package:amathus/views/feeditems_byid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FeedListTile extends StatelessWidget {
  final Feed item;

  FeedListTile({Key key, @required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
            title: Container(
                child: item.imageUrl != null
                    ? SizedBox(
                        width: 200,
                        height: 50,
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          placeholder: (context, url) =>
                              new LinearProgressIndicator(),
                          errorWidget: (context, url, error) => Text(item.title,
                              style: Theme.of(context).textTheme.headline4),
                        ))
                    : Text(item.title,
                        style: Theme.of(context).textTheme.headline4)),
            //trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FeedItemsByIdView(feed: item)))
                }));
  }
}
