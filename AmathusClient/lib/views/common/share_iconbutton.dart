import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareIconButton extends StatelessWidget {
  final FeedItem item;

  const ShareIconButton({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: Constants.SHARE,
      icon: const Icon(Icons.share_outlined, size: 20),
      onPressed: () async =>
          await _socialShare(context, item.title, item.url ?? ''),
    );
  }

  Future<void> _socialShare(
    BuildContext context,
    String title,
    String url,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: '${Constants.APP_NAME}: $title - $url',
        subject: '${Constants.APP_NAME}: $title',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }
}
