import 'package:amathus/models/feed.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FeedImage extends StatelessWidget {
  final Feed item;

  FeedImage({Key key, @required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl == null) {
      return getReplacementText(context);
    }

    return CachedNetworkImage(
        width: 200,
        height: 50,
        imageUrl: item.imageUrl,
        placeholder: (context, url) => new LinearProgressIndicator(),
        errorWidget: (context, url, error) => getReplacementText(context));
  }

  Widget getReplacementText(BuildContext context) {
    return Text(item.title, style: Theme.of(context).textTheme.headline5);
  }
}
