import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/flag_icon.dart';
import 'package:flutter/foundation.dart';
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
    if (translatedLang == null || translatedLang == sourceLang) {
      return const SizedBox.shrink();
    }
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
    );
  }
}

class AppLanguageButton extends StatelessWidget {
  final bool lightOnDark;
  final ValueListenable<bool>? loadingListenable;
  final Future<void> Function(String selected)? onSelectedOverride;

  const AppLanguageButton({
    super.key,
    this.lightOnDark = false,
    this.loadingListenable,
    this.onSelectedOverride,
  });

  static const List<(String, String)> _languages = [
    ('el', 'Ελληνικά'),
    ('tr', 'Türkçe'),
    ('en', 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.overviewTranslateLanguageNotifier,
        if (loadingListenable != null) loadingListenable!,
      ]),
      builder: (context, _) {
        final currentLang = Constants.currentLanguage;
        final isLoading = loadingListenable?.value ?? false;

        return PopupMenuButton<String>(
          tooltip: Constants.LANGUAGE_TITLE,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (selected) async {
            if (onSelectedOverride != null) {
              await onSelectedOverride!(selected);
              return;
            }
            await Constants.setLanguage(selected);
          },
          itemBuilder: (context) => [
            for (final entry in _languages)
              PopupMenuItem<String>(
                value: entry.$1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlagIcon(languageCode: entry.$1, width: 20, height: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: currentLang == entry.$1
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (currentLang == entry.$1) ...[
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
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: lightOnDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: lightOnDark
                    ? Colors.white.withValues(alpha: 0.28)
                    : const Color(0xFF93C5FD),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          lightOnDark ? Colors.white : const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                FlagIcon(
                  languageCode: currentLang,
                  width: 22,
                  height: 15,
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: lightOnDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF1D4ED8),
                ),
              ],
            ),
          ),
        );
      },
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

    return AppLanguageButton(
      lightOnDark: lightOnDark,
      loadingListenable: TranslateController.loadingNotifier(item),
      onSelectedOverride: (selected) async {
        await Constants.setLanguage(selected);
        if (selected == sourceLang) {
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
    );
  }
}

class BulkTranslateIconButton extends StatelessWidget {
  final BulkTranslateController controller;
  final String? fixedSourceLanguage;
  final bool Function(FeedItem)? itemFilter;
  final bool lightOnDark;

  const BulkTranslateIconButton({
    super.key,
    required this.controller,
    this.fixedSourceLanguage,
    this.itemFilter,
    this.lightOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppLanguageButton(
      lightOnDark: lightOnDark,
      loadingListenable: controller.loadingNotifier,
      onSelectedOverride: (selected) async {
        await Constants.setLanguage(selected);
        await controller.translateAll(selected, filter: itemFilter);
      },
    );
  }
}
