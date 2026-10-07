import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/flag_icon.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:flutter/material.dart';

class SourceLanguageFilterBar extends StatelessWidget {
  final BulkTranslateController? bulkController;
  final bool Function(FeedItem)? itemFilter;

  const SourceLanguageFilterBar({
    super.key,
    this.bulkController,
    this.itemFilter,
  });

  String _labelFor(String code) {
    switch (code) {
      case 'tr':
        return Constants.SOURCE_FILTER_TR;
      case 'el':
        return Constants.SOURCE_FILTER_EL;
      case 'en':
        return Constants.SOURCE_FILTER_EN;
      default:
        return Constants.SOURCE_FILTER_ALL;
    }
  }

  Widget _leadingFor(String code) {
    if (code == 'tr' || code == 'el' || code == 'en') {
      return FlagIcon(languageCode: code, width: 20, height: 14);
    }
    return const Icon(
      Icons.public_rounded,
      size: 16,
      color: Color(0xFF0F2942),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Constants.sourceLanguageNotifier,
      builder: (context, selectedLang, _) {
        final options = <(String, String)>[
          ('all', Constants.SOURCE_FILTER_ALL),
          ('tr', Constants.SOURCE_FILTER_TR),
          ('el', Constants.SOURCE_FILTER_EL),
          ('en', Constants.SOURCE_FILTER_EN),
        ];

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<String>(
                      position: PopupMenuPosition.under,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        Constants.setSourceLanguage(value);
                      },
                      itemBuilder: (context) => [
                        for (final option in options)
                          PopupMenuItem<String>(
                            value: option.$1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _leadingFor(option.$1),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    option.$2,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selectedLang == option.$1
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (selectedLang == option.$1) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Color(0xFF0F2942),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
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
                            _leadingFor(selectedLang),
                            const SizedBox(width: 8),
                            Text(
                              _labelFor(selectedLang),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (bulkController != null)
                      BulkTranslateIconButton(
                        controller: bulkController!,
                        itemFilter: itemFilter,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NewspaperLanguageBar extends StatelessWidget {
  final String sourceLanguage;
  final BulkTranslateController bulkController;

  const NewspaperLanguageBar({
    super.key,
    required this.sourceLanguage,
    required this.bulkController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BulkTranslateIconButton(
                  controller: bulkController,
                  fixedSourceLanguage: sourceLanguage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

