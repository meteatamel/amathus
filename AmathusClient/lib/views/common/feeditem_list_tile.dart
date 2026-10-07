import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/share_iconbutton.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedItemListTile extends StatelessWidget {
  final FeedItem item;

  const FeedItemListTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final resolvedImage = Constants.resolveImageUrl(item.imageUrl);
    final time = timeago.format(
      item.publishDate,
      locale: Constants.currentLanguage,
    );
    final sourceTitle = item.feed?.title ?? '';
    final sourceLang = Constants.resolveFeedLanguage(
      item.feed?.id,
      item.feed?.language,
    );

    return ValueListenableBuilder<String?>(
      valueListenable: TranslateController.activeLanguageNotifier(item),
      builder: (context, activeLang, _) {
        final translated = activeLang != null
            ? TranslateController.getCached(item, activeLang)
            : null;
        final displayTitle =
            (translated != null && translated.title.trim().isNotEmpty)
                ? translated.title
                : item.title;
        final rawSummary = (item.summary ?? '').trim();
        final summary =
            (translated != null && translated.summary.trim().isNotEmpty)
                ? translated.summary.trim()
                : rawSummary;

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedItemView(item: item),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (summary.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                summary,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.blueGrey.shade600,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (resolvedImage.isNotEmpty) ...[
                        const SizedBox(width: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 96,
                            height: 76,
                            child: Image.network(
                              resolvedImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: const Color(0xFFF1F5F9),
                                child: Icon(
                                  Icons.article_outlined,
                                  color: Colors.blueGrey.shade300,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.feed != null) ...[
                        FeedImage(
                          item: item.feed,
                          width: 68,
                          height: 26,
                          compact: true,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              sourceTitle.isNotEmpty
                                  ? '$sourceTitle • $time'
                                  : time,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            SourceAndTranslationBadges(
                              sourceLang: sourceLang,
                              activeTranslationLang: activeLang,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                      TranslateIconButton(item: item),
                      ShareIconButton(item: item),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
