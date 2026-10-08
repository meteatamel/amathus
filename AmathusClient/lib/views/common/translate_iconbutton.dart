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
    if (translatedLang == null) {
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: activeLang == null
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activeLang == null
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF93C5FD),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1D4ED8),
                        ),
                      )
                    else
                      Icon(
                        Icons.translate_rounded,
                        size: 16,
                        color: activeLang == null
                            ? const Color(0xFF0F2942)
                            : const Color(0xFF1D4ED8),
                      ),
                    const SizedBox(width: 8),
                    if (activeLang != null) ...[
                      FlagIcon(
                        languageCode: activeLang,
                        width: 18,
                        height: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Constants.languageLabelFor(activeLang),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ] else
                      Text(
                        Constants.TRANSLATE,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: activeLang == null
                          ? const Color(0xFF475569)
                          : const Color(0xFF1D4ED8),
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.activeLanguageNotifier,
        controller.loadingNotifier,
        Constants.sourceLanguageNotifier,
      ]),
      builder: (context, _) {
        final activeLang = controller.activeLanguageNotifier.value;
        final isLoading = controller.loadingNotifier.value;
        final effectiveSource = fixedSourceLanguage ??
            Constants.sourceLanguageNotifier.value.toLowerCase();
        final targets = (effectiveSource == 'tr' ||
                effectiveSource == 'el' ||
                effectiveSource == 'en')
            ? Constants.targetTranslationLanguagesFor(effectiveSource)
            : const ['tr', 'el', 'en'];

        return PopupMenuButton<String>(
          tooltip: Constants.TRANSLATE,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (selected) async {
            if (selected == 'original' || selected == effectiveSource) {
              controller.clearAll();
              return;
            }
            await controller.translateAll(selected, filter: itemFilter);
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
                    if (effectiveSource == 'tr' ||
                        effectiveSource == 'el' ||
                        effectiveSource == 'en')
                      FlagIcon(
                        languageCode: effectiveSource,
                        width: 20,
                        height: 14,
                      )
                    else
                      const Icon(
                        Icons.restore_rounded,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (effectiveSource == 'tr' ||
                                effectiveSource == 'el' ||
                                effectiveSource == 'en')
                            ? Constants.languageLabelFor(effectiveSource)
                            : Constants.SHOW_ORIGINAL,
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
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: activeLang == null
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeLang == null
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF93C5FD),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1D4ED8),
                    ),
                  )
                else
                  Icon(
                    Icons.translate_rounded,
                    size: 16,
                    color: activeLang == null
                        ? const Color(0xFF0F2942)
                        : const Color(0xFF1D4ED8),
                  ),
                const SizedBox(width: 8),
                if (activeLang != null) ...[
                  FlagIcon(
                    languageCode: activeLang,
                    width: 18,
                    height: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Constants.languageLabelFor(activeLang),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ] else
                  Text(
                    Constants.TRANSLATE,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: activeLang == null
                      ? const Color(0xFF475569)
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

