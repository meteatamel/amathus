import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareIconButton extends StatelessWidget {
  final FeedItem item;
  final bool showLabel;

  const ShareIconButton({
    super.key,
    required this.item,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return Tooltip(
        message: Constants.SHARE,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async =>
              await _socialShare(context, item.title, item.url ?? ''),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.share_outlined,
                  size: 16,
                  color: Color(0xFF0F2942),
                ),
                const SizedBox(width: 8),
                Text(
                  Constants.SHARE,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
