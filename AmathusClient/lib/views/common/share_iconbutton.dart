import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:share/share.dart';

class ShareIconButton extends StatelessWidget {
  final FeedItem item;

  ShareIconButton({Key key, @required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
        tooltip: Constants.SHARE,
        icon: const Icon(Icons.share),
        onPressed: () async =>
            await _socialShare(context, item.title, item.url));
  }

  Future<void> _socialShare(BuildContext context, title, String url) async {
    final RenderBox box = context.findRenderObject();
    await Share.share('${Constants.APP_NAME}: $title - $url',
        subject: '${Constants.APP_NAME}: $title',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }
}
