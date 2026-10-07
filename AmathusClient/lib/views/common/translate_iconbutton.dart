import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/flag_icon.dart';
import 'package:flutter/material.dart';

class SourceAndTranslationBadges extends StatelessWidget {
  final String sourceLang;
  final String? activeTranslationLang;
  final bool compact;

  const SourceAndTranslationBadges({
    super.key,
    required this.sourceLang,
    this.activeTranslationLang,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final translatedLang = activeTranslationLang;
    final flagWidth = compact ? 18.0 : 20.0;
    final flagHeight = compact ? 13.0 : 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlagIcon(
          languageCode: sourceLang,
          width: flagWidth,
          height: flagHeight,
        ),
        if (translatedLang != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: Color(0xFF475569),
            ),
          ),
          FlagIcon(
            languageCode: translatedLang,
            width: flagWidth,
            height: flagHeight,
          ),
        ],
      ],
    );
  }
}

class TranslateIconButton extends StatelessWidget {
  final FeedItem item;
  final bool includeDetail;
  final bool lightOnDark;

  const TranslateIconButton({
    super.key,
    required this.item,
    this.includeDetail = false,
    this.lightOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final sourceLang = Constants.resolveFeedLanguage(
      item.feed?.id,
      item.feed?.language,
    );
    final targets = Constants.targetTranslationLanguagesFor(sourceLang);

    return ValueListenableBuilder<bool>(
      valueListenable: TranslateController.loadingNotifier(item),
      builder: (context, isLoading, _) {
        if (isLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: lightOnDark ? Colors.white : const Color(0xFF0F2942),
              ),
            ),
          );
        }

        return ValueListenableBuilder<String?>(
          valueListenable: TranslateController.activeLanguageNotifier(item),
          builder: (context, activeLang, _) {
            return PopupMenuButton<String>(
              tooltip: Constants.TRANSLATE,
              position: PopupMenuPosition.under,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (selected) async {
                if (selected == 'original' || selected == sourceLang) {
                  TranslateController.clearTranslation(item);
                  return;
                }
                final result = await TranslateController.translateItem(
                  item,
                  selected,
                  includeDetail: includeDetail,
                );
                if (result == null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Constants.TRANSLATE_ERROR),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                for (final lang in targets)
                  PopupMenuItem<String>(
                    value: lang,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlagIcon(languageCode: lang, width: 20, height: 14),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Constants.languageLabelFor(lang),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: activeLang == lang
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (activeLang == lang) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Color(0xFF1D4ED8),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (activeLang != null) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'original',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlagIcon(
                          languageCode: sourceLang,
                          width: 20,
                          height: 14,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Constants.languageLabelFor(sourceLang),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              icon: activeLang == null
                  ? Icon(
                      Icons.translate_rounded,
                      size: 20,
                      color: lightOnDark ? Colors.white : null,
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lightOnDark
                            ? Colors.white.withValues(alpha: 0.20)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: lightOnDark
                              ? Colors.white.withValues(alpha: 0.45)
                              : const Color(0xFF93C5FD),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 14,
                            color: lightOnDark
                                ? Colors.white
                                : const Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 4),
                          FlagIcon(
                            languageCode: activeLang,
                            width: 15,
                            height: 10.5,
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
