import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FeedImage extends StatelessWidget {
  final Feed? item;
  final double width;
  final double height;
  final bool compact;

  const FeedImage({
    super.key,
    required this.item,
    this.width = 140,
    this.height = 42,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final feed = item;
    if (feed == null) {
      return const SizedBox.shrink();
    }

    final resolvedUrl = Constants.resolveImageUrl(feed.imageUrl);
    if (resolvedUrl.isEmpty) {
      return _buildReplacementText(context, feed.title);
    }

    final darkBg = Constants.needsDarkLogoBackground(feed.id);
    final bgColor = darkBg ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        darkBg ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: kIsWeb
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildReplacementText(context, feed.title, darkBg: darkBg),
            )
          : CachedNetworkImage(
              imageUrl: resolvedUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: darkBg
                        ? Colors.white70
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) =>
                  _buildReplacementText(context, feed.title, darkBg: darkBg),
            ),
    );
  }

  Widget _buildReplacementText(
    BuildContext context,
    String title, {
    bool darkBg = false,
  }) {
    return Center(
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w700,
          color: darkBg ? Colors.white : const Color(0xFF0F2942),
        ),
      ),
    );
  }
}
