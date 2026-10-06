import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/flag_icon.dart';
import 'package:flutter/material.dart';

class SourceLanguageFilterBar extends StatelessWidget {
  const SourceLanguageFilterBar({super.key});

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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: options[i].$1 == 'all'
                            ? Icon(
                                Icons.public_rounded,
                                size: 16,
                                color: selectedLang == 'all'
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              )
                            : FlagIcon(languageCode: options[i].$1),
                        label: Text(options[i].$2),
                        selected: selectedLang == options[i].$1,
                        showCheckmark: false,
                        selectedColor: const Color(0xFF0F2942),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: selectedLang == options[i].$1
                              ? const Color(0xFF0F2942)
                              : const Color(0xFFE2E8F0),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedLang == options[i].$1
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          if (selected) {
                            Constants.setSourceLanguage(options[i].$1);
                          }
                        },
                      ),
                    ],
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
