import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/share_iconbutton.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class FeedItemView extends StatelessWidget {
  final FeedItem item;

  const FeedItemView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: item.feed != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FeedImage(
                    item: item.feed,
                    width: 88,
                    height: 32,
                    compact: true,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      item.feed!.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            : Text(Constants.APP_NAME),
        centerTitle: true,
        actions: [ShareIconButton(item: item)],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow(),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.32,
                        ),
                      ),
                      _buildItemImage(),
                      const SizedBox(height: 16),
                      _buildItemDetail(),
                      const SizedBox(height: 24),
                      _buildMoreButton(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow() {
    final time = timeago.format(
      item.publishDate,
      locale: Constants.currentLanguage,
    );
    final sourceTitle = item.feed?.title ?? '';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Text(
                sourceTitle.isNotEmpty ? '$sourceTitle • $time' : time,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage() {
    final resolvedImage = Constants.resolveImageUrl(item.imageUrl);
    if (resolvedImage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: SizedBox(
            width: double.infinity,
            child: Image.network(
              resolvedImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetail() {
    final detail = (item.detail ?? '').trim();
    if (detail.isNotEmpty) {
      return HtmlWidget(
        detail,
        textStyle: const TextStyle(
          fontSize: 16,
          height: 1.65,
          color: Color(0xFF1E293B),
        ),
        onTapUrl: (url) async {
          await _launchURL(url);
          return true;
        },
      );
    }

    final summary = (item.summary ?? '').trim();
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      summary,
      style: const TextStyle(
        fontSize: 16,
        height: 1.65,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final url = item.url ?? '';
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0F2942),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async => await _launchURL(url),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: Text(
          Constants.MORE,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
