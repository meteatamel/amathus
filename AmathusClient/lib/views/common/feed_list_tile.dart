import 'package:amathus/models/feed.dart';
import 'package:amathus/views/feeditems_byid_view.dart';
import 'package:flutter/material.dart';

import 'feed_image.dart';

class FeedListTile extends StatelessWidget {
  final Feed item;

  FeedListTile({Key key, @required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
            title: FeedImage(item: item),
            //trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FeedItemsByIdView(feed: item)))
                }));
  }
}
