import 'package:amathus/models/feed.dart';
import 'package:amathus/views/feeditems_byid_view.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'feed_image.dart';

class FeedListTile extends StatelessWidget {
  final Feed item;

  FeedListTile({Key key, @required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        child: ListTile(
            title: FeedImage(item: item),
            onTap: () => {
                  Navigator.push(
                      context,
                      PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: FeedItemsByIdView(feed: item)))
                }));
  }
}
