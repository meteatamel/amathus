import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/flag_icon.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppBarModeTabs extends StatelessWidget implements PreferredSizeWidget {
  final ValueNotifier<String> modeNotifier;
  final String topLabel;
  final String latestLabel;

  const AppBarModeTabs({
    super.key,
    required this.modeNotifier,
    required this.topLabel,
    required this.latestLabel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(42);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: modeNotifier,
      builder: (context, mode, _) {
        final isTop = mode != 'latest';
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Row(
                children: [
                  Expanded(
                    child: _AppBarModeTabButton(
                      emoji: '✨',
                      label: topLabel,
                      selected: isTop,
                      onTap: () => modeNotifier.value = 'top',
                    ),
                  ),
                  Expanded(
                    child: _AppBarModeTabButton(
                      emoji: '⚡',
                      label: latestLabel,
                      selected: !isTop,
                      onTap: () => modeNotifier.value = 'latest',
                    ),
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

class _AppBarModeTabButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppBarModeTabButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFBBF24);
    final inactiveColor = Colors.white.withValues(alpha: 0.74);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 41,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? activeColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 14,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SourceLanguageFilterBar extends StatelessWidget {
  final Widget? leadingSelector;
  final BulkTranslateController? bulkController;
  final bool Function(FeedItem)? itemFilter;
  final Widget? trailing;
  final bool showNewspaperSelector;
  final Widget? extraSelector;
  final ValueListenable<Set<String>?>? allowedNewspaperIdsListenable;

  const SourceLanguageFilterBar({
    super.key,
    this.leadingSelector,
    this.bulkController,
    this.itemFilter,
    this.trailing,
    this.showNewspaperSelector = false,
    this.extraSelector,
    this.allowedNewspaperIdsListenable,
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
    return const Text(
      '🌍',
      style: TextStyle(fontSize: 15, height: 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Constants.sourceLanguageNotifier,
      builder: (context, selectedLang, _) {
        final options = <(String, String)>[
          ('all', Constants.SOURCE_FILTER_ALL),
          ('el', Constants.SOURCE_FILTER_EL),
          ('tr', Constants.SOURCE_FILTER_TR),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (leadingSelector != null) ...[
                              leadingSelector!,
                              const SizedBox(width: 8),
                            ],
                            Text(
                              Constants.SOURCES_BAR_LABEL,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            PopupMenuButton<String>(
                              tooltip: Constants.SOURCE_LANGUAGE_TITLE,
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
                                              fontWeight:
                                                  selectedLang == option.$1
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
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _leadingFor(selectedLang),
                                    const SizedBox(width: 6),
                                    Text(
                                      _labelFor(selectedLang),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: Color(0xFF475569),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showNewspaperSelector) ...[
                              const SizedBox(width: 6),
                              NewspaperDropdownSelector(
                                allowedFeedIdsListenable:
                                    allowedNewspaperIdsListenable,
                              ),
                            ],
                            if (extraSelector != null) ...[
                              const SizedBox(width: 6),
                              extraSelector!,
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      trailing!,
                    ] else if (bulkController != null) ...[
                      const SizedBox(width: 6),
                      BulkTranslateIconButton(
                        controller: bulkController!,
                        itemFilter: itemFilter,
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

class ViewModeDropdownSelector extends StatelessWidget {
  final ValueNotifier<String> modeNotifier;
  final String topLabel;
  final String latestLabel;

  const ViewModeDropdownSelector({
    super.key,
    required this.modeNotifier,
    required this.topLabel,
    required this.latestLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: modeNotifier,
      builder: (context, mode, _) {
        final isTop = mode != 'latest';
        return PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            modeNotifier.value = value;
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'top',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✨',
                    style: TextStyle(fontSize: 16, height: 1.0),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (isTop) ...[
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
            PopupMenuItem<String>(
              value: 'latest',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚡',
                    style: TextStyle(fontSize: 16, height: 1.0),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      latestLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: !isTop ? FontWeight.w700 : FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (!isTop) ...[
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0F2942)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTop ? '✨' : '⚡',
                  style: const TextStyle(fontSize: 14, height: 1.0),
                ),
                const SizedBox(width: 5),
                Text(
                  isTop ? topLabel : latestLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NewspaperDropdownSelector extends StatefulWidget {
  final ValueListenable<Set<String>?>? allowedFeedIdsListenable;

  const NewspaperDropdownSelector({
    super.key,
    this.allowedFeedIdsListenable,
  });

  @override
  State<NewspaperDropdownSelector> createState() =>
      _NewspaperDropdownSelectorState();
}

class _NewspaperDropdownSelectorState extends State<NewspaperDropdownSelector> {
  final FeedsController _feedsController = FeedsController();
  List<Feed> _feeds = const [];

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    final stored = await _feedsController.readAllStored();
    if (stored != null && stored.isNotEmpty && mounted) {
      setState(() {
        _feeds = stored;
      });
    }
    final fresh = await _feedsController.readAll();
    if (fresh != null && fresh.isNotEmpty && mounted) {
      setState(() {
        _feeds = fresh;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.sourceLanguageNotifier,
        Constants.hiddenFeedsNotifier,
        Constants.selectedFeedIdNotifier,
        if (widget.allowedFeedIdsListenable != null)
          widget.allowedFeedIdsListenable!,
      ]),
      builder: (context, _) {
        final allowedIds = widget.allowedFeedIdsListenable?.value;
        final visibleFeeds = _feeds.where((f) {
          if (!Constants.matchesSourceLanguageOnly(f.id, f.language)) {
            return false;
          }
          if (allowedIds != null &&
              !allowedIds.contains(f.id.trim().toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

        final selectedId = Constants.selectedFeedIdNotifier.value;
        Feed? selectedFeed;
        if (selectedId != null) {
          for (final f in visibleFeeds) {
            if (f.id.trim().toLowerCase() == selectedId) {
              selectedFeed = f;
              break;
            }
          }
        }

        final hasSelectedLogo = selectedFeed != null &&
            Constants.resolveImageUrl(selectedFeed.imageUrl).isNotEmpty;

        return PopupMenuButton<String>(
          tooltip: Constants.NEWSPAPERS,
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(maxHeight: 420, minWidth: 220),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'all') {
              Constants.setSelectedFeedId(null);
            } else {
              Constants.setSelectedFeedId(value);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'all',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '📰',
                    style: TextStyle(fontSize: 16, height: 1.0),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Constants.ALL_NEWSPAPERS,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selectedFeed == null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (selectedFeed == null) ...[
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
            if (visibleFeeds.isNotEmpty) const PopupMenuDivider(),
            for (final feed in visibleFeeds)
              PopupMenuItem<String>(
                value: feed.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (Constants.resolveImageUrl(feed.imageUrl)
                        .isNotEmpty) ...[
                      FeedImage(
                        item: feed,
                        width: 48,
                        height: 22,
                        compact: true,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        feed.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedFeed?.id == feed.id
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (selectedFeed?.id == feed.id) ...[
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
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: selectedFeed == null
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selectedFeed == null
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF0F2942),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSelectedLogo) ...[
                  FeedImage(
                    item: selectedFeed,
                    width: 38,
                    height: 18,
                    compact: true,
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  const Text(
                    '📰',
                    style: TextStyle(fontSize: 14, height: 1.0),
                  ),
                  const SizedBox(width: 5),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    selectedFeed?.title ?? Constants.NEWSPAPERS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
              ],
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

class ColumnistDropdownSelector extends StatelessWidget {
  final ValueListenable<List<FeedItem>> itemsListenable;

  const ColumnistDropdownSelector({
    super.key,
    required this.itemsListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        itemsListenable,
        Constants.sourceLanguageNotifier,
        Constants.selectedFeedIdNotifier,
        Constants.hiddenFeedsNotifier,
        Constants.selectedColumnistNotifier,
      ]),
      builder: (context, _) {
        final allItems = itemsListenable.value;
        final authorToFeed = <String, Feed?>{};
        for (final item in allItems) {
          final matchesNewspaperAndLang = item.feed == null ||
              Constants.matchesSourceLanguage(
                item.feed?.id,
                item.feed?.language,
              );
          if (!matchesNewspaperAndLang) continue;
          final author = (item.author ?? '').trim();
          if (author.isEmpty) continue;
          authorToFeed.putIfAbsent(author, () => item.feed);
        }

        final authors = authorToFeed.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final selectedAuthor = Constants.selectedColumnistNotifier.value;
        final activeAuthor =
            (selectedAuthor != null && authorToFeed.containsKey(selectedAuthor))
                ? selectedAuthor
                : null;

        return PopupMenuButton<String>(
          tooltip: Constants.COLUMNISTS,
          position: PopupMenuPosition.under,
          constraints: const BoxConstraints(maxHeight: 420, minWidth: 230),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'all') {
              Constants.setSelectedColumnist(null);
            } else {
              Constants.setSelectedColumnist(value);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'all',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✍️',
                    style: TextStyle(fontSize: 16, height: 1.0),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Constants.ALL_COLUMNISTS,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: activeAuthor == null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (activeAuthor == null) ...[
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
            if (authors.isNotEmpty) const PopupMenuDivider(),
            for (final author in authors)
              PopupMenuItem<String>(
                value: author,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (authorToFeed[author] != null &&
                        Constants.resolveImageUrl(
                          authorToFeed[author]!.imageUrl,
                        ).isNotEmpty) ...[
                      FeedImage(
                        item: authorToFeed[author],
                        width: 44,
                        height: 20,
                        compact: true,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        author,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: activeAuthor == author
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (activeAuthor == author) ...[
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
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: activeAuthor == null
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeAuthor == null
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF0F2942),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '✍️',
                  style: TextStyle(fontSize: 14, height: 1.0),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    activeAuthor ?? Constants.COLUMNISTS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String topicEmojiFor(String topicCode) {
  switch (topicCode.trim().toLowerCase()) {
    case 'politics':
      return '🏛️';
    case 'society':
      return '⚖️';
    case 'economy':
      return '📈';
    case 'sports':
      return '⚽';
    case 'culture':
      return '🎭';
    case 'world':
      return '🌍';
    default:
      return '🔥';
  }
}

(Color bg, Color fg, Color border) topicColorsFor(String topicCode) {
  switch (topicCode.trim().toLowerCase()) {
    case 'politics':
      return (
        const Color(0xFFEFF6FF),
        const Color(0xFF1E40AF),
        const Color(0xFFBFDBFE),
      );
    case 'society':
      return (
        const Color(0xFFF5F3FF),
        const Color(0xFF5B21B6),
        const Color(0xFFDDD6FE),
      );
    case 'economy':
      return (
        const Color(0xFFECFDF5),
        const Color(0xFF065F46),
        const Color(0xFFA7F3D0),
      );
    case 'sports':
      return (
        const Color(0xFFFFFBEB),
        const Color(0xFF92400E),
        const Color(0xFFFDE68A),
      );
    case 'culture':
      return (
        const Color(0xFFFFF1F2),
        const Color(0xFF9F1239),
        const Color(0xFFFECDD3),
      );
    case 'world':
      return (
        const Color(0xFFF0FDFA),
        const Color(0xFF115E59),
        const Color(0xFF99F6E4),
      );
    default:
      return (
        const Color(0xFFF1F5F9),
        const Color(0xFF334155),
        const Color(0xFFCBD5E1),
      );
  }
}

class TopicFilterChipBar extends StatelessWidget {
  final Map<String, int>? countsByTopic;

  const TopicFilterChipBar({
    super.key,
    this.countsByTopic,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.selectedTopicNotifier,
      ]),
      builder: (context, _) {
        final selected = Constants.selectedTopicNotifier.value;
        final counts = countsByTopic;

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showLabels = constraints.maxWidth >= 660;
                  final visibleCodes = <String>[
                    for (final code in Constants.TOPIC_CODES)
                      if (code == 'all' ||
                          selected == code ||
                          counts == null ||
                          (counts[code] ?? 0) > 0)
                        code,
                  ];

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < visibleCodes.length; i++) ...[
                          if (i > 0)
                            SizedBox(width: showLabels ? 5 : 4),
                          _TopicChipButton(
                            topicCode: visibleCodes[i],
                            selected: selected == visibleCodes[i],
                            count: counts != null ? counts[visibleCodes[i]] : null,
                            showLabel: showLabels,
                            onTap: () {
                              final code = visibleCodes[i];
                              if (selected == code && code != 'all') {
                                Constants.setSelectedTopic('all');
                              } else {
                                Constants.setSelectedTopic(code);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopicChipButton extends StatelessWidget {
  final String topicCode;
  final bool selected;
  final int? count;
  final bool showLabel;
  final VoidCallback onTap;

  const _TopicChipButton({
    required this.topicCode,
    required this.selected,
    this.count,
    this.showLabel = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeNavy = Color(0xFF0F2942);
    final fullLabel = Constants.topicLabelFor(topicCode);
    final shortLabel = Constants.topicShortLabelFor(topicCode);
    final emoji = topicEmojiFor(topicCode);
    final tooltipText =
        count != null ? '$fullLabel ($count)' : fullLabel;

    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 8.5 : 7.5,
              vertical: 4.5,
            ),
            decoration: BoxDecoration(
              color: selected ? activeNavy : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? activeNavy : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.0,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(width: 4),
                  Text(
                    shortLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
                if (count != null) ...[
                  SizedBox(width: showLabel ? 3 : 3.5),
                  Text(
                    showLabel ? '($count)' : '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.82)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopicBadgePill extends StatelessWidget {
  final String topicCode;

  const TopicBadgePill({
    super.key,
    required this.topicCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.selectedTopicNotifier,
      ]),
      builder: (context, _) {
        final norm = Constants.normalizeTopic(topicCode) ?? 'society';
        final isSelected = Constants.selectedTopicNotifier.value == norm;
        final (bg, fg, border) = topicColorsFor(norm);
        final label = Constants.topicLabelFor(norm);
        final emoji = topicEmojiFor(norm);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isSelected) {
                Constants.setSelectedTopic('all');
              } else {
                Constants.setSelectedTopic(norm);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? fg : border,
                  width: isSelected ? 1.3 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
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
