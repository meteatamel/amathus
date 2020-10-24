import 'package:amathus/controllers/feeditem_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedItemListTileWide extends StatelessWidget {
  final FeedItem item;

  static const height = 400.0;

  FeedItemListTileWide({Key key, @required this.item})
      : assert(item != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
          //height: height,
          child: InkWell(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: FeedItemListTileContent(item: item),
        ),
        onTap: () => {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => FeedItemView(item: item)))
        },
      )),
    );
  }
}

class FeedItemListTileContent extends StatelessWidget {
  final FeedItem item;
  final FeedItemController _controller = new FeedItemController();

  FeedItemListTileContent({Key key, @required this.item})
      : assert(item != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          //height: 200,
          child: _itemImage(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis)
            ],
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_favicon(), _sourceAndTimeText()])),
          IconButton(
            tooltip: Constants.SHARE,
            icon: const Icon(Icons.share),
            onPressed: () async =>
                await _controller.socialShare(context, item.title, item.url),
          ),
        ]),
      ],
    );
  }

  Widget _itemImage() {
    return (item.imageUrl == null)
        ? null
        : CachedNetworkImage(
            imageUrl: item.imageUrl,
            placeholder: (context, url) => new LinearProgressIndicator(),
          );
  }

  Widget _sourceAndTimeText() {
    var subtitle = "${timeago.format(item.publishDate, locale: 'tr')}";
    if (item.feed != null) {
      subtitle = " ${item.feed.title} • $subtitle";
    }
    return Text(subtitle, style: TextStyle(fontSize: 14));
  }

  Widget _favicon() {
    return CachedNetworkImage(
        width: 16,
        height: 16,
        imageUrl: item.feed.url + "favicon.ico",
        errorWidget: (context, url, error) =>
            Icon(Icons.description, size: 16));
  }
}
