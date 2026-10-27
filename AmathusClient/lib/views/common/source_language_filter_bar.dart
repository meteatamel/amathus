import 'dart:ui';

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

class _HorizontalChipScrollBehavior extends MaterialScrollBehavior {
  const _HorizontalChipScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class AppBarModeTabs extends StatelessWidget implements PreferredSizeWidget {
  final ValueNotifier<String> modeNotifier;
  final String topLabel;
  final String latestLabel;
  final IconData topIcon;
  final IconData topActiveIcon;
  final IconData latestIcon;
  final IconData latestActiveIcon;

  const AppBarModeTabs({
    super.key,
    required this.modeNotifier,
    required this.topLabel,
    required this.latestLabel,
    this.topIcon = Icons.auto_awesome_outlined,
    this.topActiveIcon = Icons.auto_awesome_rounded,
    this.latestIcon = Icons.schedule_outlined,
    this.latestActiveIcon = Icons.schedule_rounded,
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
                      icon: isTop ? topActiveIcon : topIcon,
                      label: topLabel,
                      selected: isTop,
                      onTap: () => modeNotifier.value = 'top',
                    ),
                  ),
                  Expanded(
                    child: _AppBarModeTabButton(
                      icon: !isTop ? latestActiveIcon : latestIcon,
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
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AppBarModeTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFBBF24);
    final inactiveColor = Colors.white.withValues(alpha: 0.74);
    final effectiveColor = selected ? activeColor : inactiveColor;

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
            Icon(
              icon,
              size: 16.5,
              color: effectiveColor,
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
                  color: effectiveColor,
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
  final Map<String, int>? countsBySource;
  final Map<String, int>? countsByNewspaper;

  const SourceLanguageFilterBar({
    super.key,
    this.leadingSelector,
    this.bulkController,
    this.itemFilter,
    this.trailing,
    this.showNewspaperSelector = false,
    this.extraSelector,
    this.allowedNewspaperIdsListenable,
    this.countsBySource,
    this.countsByNewspaper,
  });

  Widget _leadingFor(String code, {required bool selected}) {
    if (code == 'tr' || code == 'el' || code == 'en') {
      return FlagIcon(languageCode: code, width: 17, height: 12);
    }
    return Icon(
      Icons.public_rounded,
      size: 14.5,
      color: selected ? Colors.white : const Color(0xFF334155),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.sourceLanguageNotifier,
        Constants.selectedFeedIdNotifier,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        final selectedLang = Constants.sourceLanguageNotifier.value;
        final hasSelectedFeed = Constants.selectedFeedIdNotifier.value != null;
        final counts = countsBySource;
        final options = <(String, String)>[
          ('all', Constants.SOURCE_FILTER_ALL),
          ('el', Constants.SOURCE_FILTER_EL),
          ('tr', Constants.SOURCE_FILTER_TR),
          ('en', Constants.SOURCE_FILTER_EN),
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
                      final visibleOptions = options;

                      return ScrollConfiguration(
                        behavior: const _HorizontalChipScrollBehavior(),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (leadingSelector != null) ...[
                                leadingSelector!,
                                const SizedBox(width: 6),
                              ],
                              for (var i = 0; i < visibleOptions.length; i++) ...[
                                if (i > 0)
                                  SizedBox(width: showLabels ? 5 : 4),
                                _buildSourceChip(
                                  code: visibleOptions[i].$1,
                                  label: visibleOptions[i].$2,
                                  selected: !hasSelectedFeed &&
                                      selectedLang == visibleOptions[i].$1,
                                  count: counts != null
                                      ? counts[visibleOptions[i].$1]
                                      : null,
                                  showLabel: showLabels ||
                                      visibleOptions[i].$1 == 'all',
                                ),
                              ],
                              if (extraSelector != null) ...[
                                const SizedBox(width: 6),
                                extraSelector!,
                              ],
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
                      );
                    },
                  ),
                ),
              ),
            ),
            if (showNewspaperSelector)
              NewspaperFilterChipBar(
                allowedFeedIdsListenable: allowedNewspaperIdsListenable,
                countsByNewspaper: countsByNewspaper,
              ),
          ],
        );
      },
    );
  }

  Widget _buildSourceChip({
    required String code,
    required String label,
    required bool selected,
    int? count,
    bool showLabel = true,
  }) {
    const activeNavy = Color(0xFF0F2942);
    final baseTooltip = Constants.sourceFilterTooltipFor(code);
    final tooltipText =
        count != null ? '$baseTooltip ($count)' : baseTooltip;
    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (selected && code != 'all') {
              Constants.setSourceLanguage('all');
            } else {
              Constants.setSourceLanguage(code);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 9.0 : 8.0,
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
                _leadingFor(code, selected: selected),
                if (showLabel) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color:
                          selected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
                if (count != null) ...[
                  SizedBox(width: showLabel ? 3.5 : 4),
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
                  Icon(
                    isTop
                        ? Icons.auto_awesome_rounded
                        : Icons.auto_awesome_outlined,
                    size: 18,
                    color: const Color(0xFF0F2942),
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
                  Icon(
                    !isTop ? Icons.schedule_rounded : Icons.schedule_outlined,
                    size: 18,
                    color: const Color(0xFF0F2942),
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
                Icon(
                  isTop ? Icons.auto_awesome_rounded : Icons.schedule_rounded,
                  size: 15.5,
                  color: const Color(0xFF0F2942),
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

class NewspaperFilterChipBar extends StatefulWidget {
  final ValueListenable<Set<String>?>? allowedFeedIdsListenable;
  final Map<String, int>? countsByNewspaper;

  const NewspaperFilterChipBar({
    super.key,
    this.allowedFeedIdsListenable,
    this.countsByNewspaper,
  });

  @override
  State<NewspaperFilterChipBar> createState() => _NewspaperFilterChipBarState();
}

class _NewspaperFilterChipBarState extends State<NewspaperFilterChipBar> {
  final FeedsController _feedsController = FeedsController();
  final Map<String, GlobalKey> _chipKeys = <String, GlobalKey>{};
  List<Feed> _feeds = const [];
  String? _lastScrolledFeedId;

  @override
  void initState() {
    super.initState();
    Constants.selectedFeedIdNotifier.addListener(_onSelectedFeedChanged);
    _loadFeeds();
  }

  @override
  void dispose() {
    Constants.selectedFeedIdNotifier.removeListener(_onSelectedFeedChanged);
    super.dispose();
  }

  void _onSelectedFeedChanged() {
    final selectedId = Constants.selectedFeedIdNotifier.value;
    if (selectedId == _lastScrolledFeedId) return;
    _lastScrolledFeedId = selectedId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _chipKeys[selectedId ?? 'all'];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.35,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  GlobalKey _keyFor(String id) {
    return _chipKeys.putIfAbsent(id, () => GlobalKey());
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
        Constants.languageNotifier,
        Constants.sourceLanguageNotifier,
        Constants.hiddenFeedsNotifier,
        Constants.selectedFeedIdNotifier,
        if (widget.allowedFeedIdsListenable != null)
          widget.allowedFeedIdsListenable!,
      ]),
      builder: (context, _) {
        final allowedIds = widget.allowedFeedIdsListenable?.value;
        final counts = widget.countsByNewspaper;
        final selectedId = Constants.selectedFeedIdNotifier.value;

        final visibleFeeds = _feeds.where((f) {
          final normId = f.id.trim().toLowerCase();
          if (!Constants.matchesSourceLanguageOnly(f.id, f.language)) {
            return false;
          }
          if (allowedIds != null &&
              allowedIds.isNotEmpty &&
              !allowedIds.contains(normId) &&
              selectedId != normId) {
            return false;
          }
          return true;
        }).toList();

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
              child: ScrollConfiguration(
                behavior: const _HorizontalChipScrollBehavior(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAllNewspapersChip(
                        key: _keyFor('all'),
                        selected: selectedId == null,
                        count: counts != null ? counts['all'] : null,
                      ),
                      for (final feed in visibleFeeds) ...[
                        const SizedBox(width: 5),
                        _buildNewspaperChip(
                          key: _keyFor(feed.id.trim().toLowerCase()),
                          feed: feed,
                          selected: selectedId == feed.id.trim().toLowerCase(),
                          count: counts != null
                              ? counts[feed.id.trim().toLowerCase()]
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllNewspapersChip({
    Key? key,
    required bool selected,
    int? count,
  }) {
    const activeNavy = Color(0xFF0F2942);
    final label = Constants.ALL_NEWSPAPERS;
    final tooltipText = count != null ? '$label ($count)' : label;

    return Tooltip(
      key: key,
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Constants.setSelectedFeedId(null),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9.0,
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
                Icon(
                  selected ? Icons.newspaper_rounded : Icons.newspaper_outlined,
                  size: 14.5,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 3.5),
                  Text(
                    '($count)',
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

  Widget _buildNewspaperChip({
    Key? key,
    required Feed feed,
    required bool selected,
    int? count,
  }) {
    const activeNavy = Color(0xFF0F2942);
    final hasLogo = Constants.resolveImageUrl(feed.imageUrl).isNotEmpty;
    final tooltipText =
        count != null ? '${feed.title} ($count)' : feed.title;

    return Tooltip(
      key: key,
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (selected) {
              Constants.setSelectedFeedId(null);
            } else {
              Constants.setSelectedFeedId(feed.id);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.5,
              vertical: 4.0,
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
                if (hasLogo) ...[
                  FeedImage(
                    item: feed,
                    width: 28,
                    height: 15,
                    compact: true,
                  ),
                  const SizedBox(width: 5),
                ] else ...[
                  Icon(
                    selected
                        ? Icons.newspaper_rounded
                        : Icons.newspaper_outlined,
                    size: 14,
                    color: selected ? Colors.white : const Color(0xFF334155),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  feed.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 3.5),
                  Text(
                    '($count)',
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
        Constants.languageNotifier,
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
                  const Icon(
                    Icons.newspaper_rounded,
                    size: 18,
                    color: Color(0xFF0F2942),
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
                  const Icon(
                    Icons.newspaper_rounded,
                    size: 15.5,
                    color: Color(0xFF0F2942),
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
        Constants.languageNotifier,
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
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: Color(0xFF0F2942),
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
                const Icon(
                  Icons.edit_note_rounded,
                  size: 16,
                  color: Color(0xFF0F2942),
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

IconData topicIconFor(String topicCode, {bool selected = false}) {
  switch (topicCode.trim().toLowerCase()) {
    case 'all':
      return Icons.apps_rounded;
    case 'politics':
      return selected
          ? Icons.account_balance_rounded
          : Icons.account_balance_outlined;
    case 'society':
      return selected ? Icons.groups_rounded : Icons.groups_outlined;
    case 'economy':
      return Icons.trending_up_rounded;
    case 'sports':
      return selected
          ? Icons.sports_soccer_rounded
          : Icons.sports_soccer_outlined;
    case 'culture':
      return selected
          ? Icons.theater_comedy_rounded
          : Icons.theater_comedy_outlined;
    case 'world':
      return selected ? Icons.public_rounded : Icons.public_outlined;
    default:
      return selected ? Icons.label_rounded : Icons.label_outline_rounded;
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
            color: Color(0xFFF8FAFC),
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

                  return ScrollConfiguration(
                    behavior: const _HorizontalChipScrollBehavior(),
                    child: SingleChildScrollView(
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
                              count: counts != null
                                  ? counts[visibleCodes[i]]
                                  : null,
                              showLabel:
                                  showLabels || visibleCodes[i] == 'all',
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
    final iconData = topicIconFor(topicCode, selected: selected);
    final accentColor = topicColorsFor(topicCode).$2;
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
                Icon(
                  iconData,
                  size: 14.5,
                  color: selected ? Colors.white : accentColor,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 4.5),
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
        final iconData = topicIconFor(norm, selected: true);

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
                  Icon(
                    iconData,
                    size: 13.5,
                    color: fg,
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

class ColumnistBadgePill extends StatelessWidget {
  final String author;

  const ColumnistBadgePill({
    super.key,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = author.trim();
    final label =
        trimmed.isNotEmpty ? trimmed : Constants.COLUMNIST_BADGE_FALLBACK;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.edit_note_rounded,
            size: 14,
            color: Color(0xFF92400E),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnifiedNewsFilterBar extends StatelessWidget {
  final bool showNewspaperSelector;
  final Map<String, int>? countsBySource;
  final Map<String, int>? countsByNewspaper;
  final Map<String, int>? countsByTopic;
  final ValueListenable<Set<String>?>? allowedNewspaperIdsListenable;

  const UnifiedNewsFilterBar({
    super.key,
    this.showNewspaperSelector = false,
    this.countsBySource,
    this.countsByNewspaper,
    this.countsByTopic,
    this.allowedNewspaperIdsListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.sourceLanguageNotifier,
        Constants.selectedFeedIdNotifier,
        Constants.selectedTopicNotifier,
        Constants.hiddenFeedsNotifier,
      ]),
      builder: (context, _) {
        final selectedTopic = Constants.selectedTopicNotifier.value;
        final counts = countsByTopic;
        final visibleCodes = <String>[
          for (final code in Constants.TOPIC_CODES)
            if (code == 'all' ||
                selectedTopic == code ||
                counts == null ||
                (counts[code] ?? 0) > 0)
              code,
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
              child: ScrollConfiguration(
                behavior: const _HorizontalChipScrollBehavior(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SourcesTriggerPill(
                        showNewspaperSelector: showNewspaperSelector,
                        showTopicsInSheet: true,
                        countsBySource: countsBySource,
                        countsByNewspaper: countsByNewspaper,
                        countsByTopic: countsByTopic,
                        allowedNewspaperIdsListenable:
                            allowedNewspaperIdsListenable,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 20,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 8),
                      for (var i = 0; i < visibleCodes.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        _TopicChipButton(
                          topicCode: visibleCodes[i],
                          selected: selectedTopic == visibleCodes[i],
                          count: null,
                          showLabel: true,
                          onTap: () {
                            final code = visibleCodes[i];
                            if (selectedTopic == code && code != 'all') {
                              Constants.setSelectedTopic('all');
                            } else {
                              Constants.setSelectedTopic(code);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class UnifiedColumnsFilterBar extends StatelessWidget {
  final ValueNotifier<String> modeNotifier;
  final bool showNewspaperSelector;
  final ValueListenable<Set<String>?>? allowedNewspaperIdsListenable;
  final ValueListenable<List<FeedItem>>? itemsListenable;
  final Map<String, int>? countsBySource;
  final Map<String, int>? countsByNewspaper;

  const UnifiedColumnsFilterBar({
    super.key,
    required this.modeNotifier,
    this.showNewspaperSelector = false,
    this.allowedNewspaperIdsListenable,
    this.itemsListenable,
    this.countsBySource,
    this.countsByNewspaper,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.sourceLanguageNotifier,
        Constants.selectedFeedIdNotifier,
        Constants.selectedColumnistNotifier,
        Constants.hiddenFeedsNotifier,
        modeNotifier,
      ]),
      builder: (context, _) {
        final isTopMode = modeNotifier.value != 'latest';

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
              child: ScrollConfiguration(
                behavior: const _HorizontalChipScrollBehavior(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SourcesTriggerPill(
                        showNewspaperSelector: showNewspaperSelector,
                        showTopicsInSheet: false,
                        countsBySource: countsBySource,
                        countsByNewspaper: countsByNewspaper,
                        allowedNewspaperIdsListenable:
                            allowedNewspaperIdsListenable,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 20,
                        color: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 8),
                      _ColumnsModeSegmentedControl(
                        modeNotifier: modeNotifier,
                      ),
                      if (!isTopMode && itemsListenable != null) ...[
                        const SizedBox(width: 6),
                        ColumnistDropdownSelector(
                          itemsListenable: itemsListenable!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColumnsModeSegmentedControl extends StatelessWidget {
  final ValueNotifier<String> modeNotifier;

  const _ColumnsModeSegmentedControl({required this.modeNotifier});

  @override
  Widget build(BuildContext context) {
    final isTop = modeNotifier.value != 'latest';
    const activeNavy = Color(0xFF0F2942);

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegment(
            icon: isTop
                ? Icons.auto_awesome_rounded
                : Icons.auto_awesome_outlined,
            label: Constants.TOP_COLUMNS,
            selected: isTop,
            activeNavy: activeNavy,
            onTap: () => modeNotifier.value = 'top',
          ),
          const SizedBox(width: 2),
          _buildSegment(
            icon: !isTop ? Icons.schedule_rounded : Icons.schedule_outlined,
            label: Constants.LATEST_COLUMNS,
            selected: !isTop,
            activeNavy: activeNavy,
            onTap: () => modeNotifier.value = 'latest',
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required IconData icon,
    required String label,
    required bool selected,
    required Color activeNavy,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: selected ? activeNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13.5,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
              const SizedBox(width: 4.5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcesTriggerPill extends StatefulWidget {
  final bool showNewspaperSelector;
  final bool showTopicsInSheet;
  final Map<String, int>? countsBySource;
  final Map<String, int>? countsByNewspaper;
  final Map<String, int>? countsByTopic;
  final ValueListenable<Set<String>?>? allowedNewspaperIdsListenable;

  const _SourcesTriggerPill({
    required this.showNewspaperSelector,
    required this.showTopicsInSheet,
    this.countsBySource,
    this.countsByNewspaper,
    this.countsByTopic,
    this.allowedNewspaperIdsListenable,
  });

  @override
  State<_SourcesTriggerPill> createState() => _SourcesTriggerPillState();
}

class _SourcesTriggerPillState extends State<_SourcesTriggerPill> {
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

  String _sourceLabelFor(String code) {
    switch (code) {
      case 'el':
        return Constants.SOURCE_FILTER_EL;
      case 'tr':
        return Constants.SOURCE_FILTER_TR;
      case 'en':
        return Constants.SOURCE_FILTER_EN;
      default:
        return Constants.SOURCE_FILTER_ALL;
    }
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SourcesFilterBottomSheet(
          feeds: _feeds,
          showNewspaperSelector: widget.showNewspaperSelector,
          showTopicsInSheet: widget.showTopicsInSheet,
          countsBySource: widget.countsBySource,
          countsByNewspaper: widget.countsByNewspaper,
          countsByTopic: widget.countsByTopic,
          allowedNewspaperIdsListenable: widget.allowedNewspaperIdsListenable,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const activeNavy = Color(0xFF0F2942);
    final selectedLang = Constants.sourceLanguageNotifier.value;
    final selectedFeedId = widget.showNewspaperSelector
        ? Constants.selectedFeedIdNotifier.value
        : null;

    Feed? selectedFeed;
    if (selectedFeedId != null) {
      for (final f in _feeds) {
        if (f.id.trim().toLowerCase() == selectedFeedId) {
          selectedFeed = f;
          break;
        }
      }
    }

    final isFiltered = selectedFeed != null || selectedLang != 'all';

    Widget leading;
    String label;
    if (selectedFeed != null) {
      final feedLang = Constants.resolveFeedLanguage(
        selectedFeed.id,
        selectedFeed.language,
      );
      leading = FlagIcon(languageCode: feedLang, width: 16, height: 11.5);
      label = selectedFeed.title;
    } else if (selectedLang == 'el' ||
        selectedLang == 'tr' ||
        selectedLang == 'en') {
      leading = FlagIcon(languageCode: selectedLang, width: 16, height: 11.5);
      label = _sourceLabelFor(selectedLang);
    } else {
      leading = const Icon(
        Icons.public_rounded,
        size: 14.5,
        color: activeNavy,
      );
      label = Constants.SOURCE_FILTER_ALL;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openFilterSheet(context),
        child: Container(
          padding: EdgeInsets.only(
            left: 9.5,
            right: isFiltered ? 6.0 : 8.0,
            top: 4.5,
            bottom: 4.5,
          ),
          decoration: BoxDecoration(
            color: isFiltered ? activeNavy : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isFiltered ? activeNavy : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 5.5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isFiltered ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15.5,
                color: isFiltered
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF475569),
              ),
              if (isFiltered) ...[
                const SizedBox(width: 3),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (selectedFeed != null) {
                      Constants.setSelectedFeedId(null);
                    } else {
                      Constants.setSourceLanguage('all');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcesFilterBottomSheet extends StatelessWidget {
  final List<Feed> feeds;
  final bool showNewspaperSelector;
  final bool showTopicsInSheet;
  final Map<String, int>? countsBySource;
  final Map<String, int>? countsByNewspaper;
  final Map<String, int>? countsByTopic;
  final ValueListenable<Set<String>?>? allowedNewspaperIdsListenable;

  const _SourcesFilterBottomSheet({
    required this.feeds,
    required this.showNewspaperSelector,
    required this.showTopicsInSheet,
    this.countsBySource,
    this.countsByNewspaper,
    this.countsByTopic,
    this.allowedNewspaperIdsListenable,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.sourceLanguageNotifier,
        Constants.selectedFeedIdNotifier,
        Constants.selectedTopicNotifier,
        Constants.hiddenFeedsNotifier,
        if (allowedNewspaperIdsListenable != null)
          allowedNewspaperIdsListenable!,
      ]),
      builder: (context, _) {
        const activeNavy = Color(0xFF0F2942);
        final selectedLang = Constants.sourceLanguageNotifier.value;
        final selectedFeedId = Constants.selectedFeedIdNotifier.value;
        final selectedTopic = Constants.selectedTopicNotifier.value;
        final hasAnyFilter = selectedLang != 'all' ||
            (showNewspaperSelector && selectedFeedId != null) ||
            (showTopicsInSheet && selectedTopic != 'all');

        final sourceOptions = <(String, String)>[
          ('all', Constants.SOURCE_FILTER_ALL),
          ('el', Constants.SOURCE_FILTER_EL),
          ('tr', Constants.SOURCE_FILTER_TR),
          ('en', Constants.SOURCE_FILTER_EN),
        ];

        final allowedIds = allowedNewspaperIdsListenable?.value;
        final visibleFeeds = feeds.where((f) {
          final normId = f.id.trim().toLowerCase();
          if (!Constants.matchesSourceLanguageOnly(f.id, f.language)) {
            return false;
          }
          if (allowedIds != null &&
              allowedIds.isNotEmpty &&
              !allowedIds.contains(normId) &&
              selectedFeedId != normId) {
            return false;
          }
          return true;
        }).toList();

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 14, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 19,
                            color: activeNavy,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              Constants.FILTER_SHEET_TITLE,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (hasAnyFilter)
                            TextButton(
                              onPressed: () {
                                Constants.setSourceLanguage('all');
                                Constants.setSelectedFeedId(null);
                                if (showTopicsInSheet) {
                                  Constants.setSelectedTopic('all');
                                }
                              },
                              child: Text(
                                Constants.RESET_FILTERS,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: activeNavy,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: activeNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              Constants.DONE_BUTTON,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Constants.SOURCE_LANGUAGE_TITLE,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final opt in sourceOptions)
                                  _buildSheetSourceChip(
                                    code: opt.$1,
                                    label: opt.$2,
                                    selected: selectedFeedId == null &&
                                        selectedLang == opt.$1,
                                    count: countsBySource != null
                                        ? countsBySource![opt.$1]
                                        : null,
                                  ),
                              ],
                            ),
                            if (showNewspaperSelector &&
                                visibleFeeds.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text(
                                Constants.NEWSPAPERS,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  _buildSheetAllNewspapersChip(
                                    selected: selectedFeedId == null,
                                    count: countsByNewspaper != null
                                        ? countsByNewspaper!['all']
                                        : null,
                                  ),
                                  for (final feed in visibleFeeds)
                                    _buildSheetNewspaperChip(
                                      feed: feed,
                                      selected: selectedFeedId ==
                                          feed.id.trim().toLowerCase(),
                                      count: countsByNewspaper != null
                                          ? countsByNewspaper![
                                              feed.id.trim().toLowerCase()]
                                          : null,
                                    ),
                                ],
                              ),
                            ],
                            if (showTopicsInSheet) ...[
                              const SizedBox(height: 18),
                              Text(
                                Constants.TOPICS_SECTION_TITLE,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  for (final code in Constants.TOPIC_CODES)
                                    if (code == 'all' ||
                                        selectedTopic == code ||
                                        countsByTopic == null ||
                                        (countsByTopic![code] ?? 0) > 0)
                                      _TopicChipButton(
                                        topicCode: code,
                                        selected: selectedTopic == code,
                                        count: countsByTopic != null
                                            ? countsByTopic![code]
                                            : null,
                                        showLabel: true,
                                        onTap: () {
                                          if (selectedTopic == code &&
                                              code != 'all') {
                                            Constants.setSelectedTopic('all');
                                          } else {
                                            Constants.setSelectedTopic(code);
                                          }
                                        },
                                      ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Widget _buildSheetSourceChip({
    required String code,
    required String label,
    required bool selected,
    int? count,
  }) {
    const activeNavy = Color(0xFF0F2942);
    Widget leading;
    if (code == 'tr' || code == 'el' || code == 'en') {
      leading = FlagIcon(languageCode: code, width: 18, height: 12.5);
    } else {
      leading = Icon(
        Icons.public_rounded,
        size: 15,
        color: selected ? Colors.white : const Color(0xFF334155),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (selected && code != 'all') {
            Constants.setSourceLanguage('all');
          } else {
            Constants.setSourceLanguage(code);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
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
              leading,
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 11.5,
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
    );
  }

  Widget _buildSheetAllNewspapersChip({
    required bool selected,
    int? count,
  }) {
    const activeNavy = Color(0xFF0F2942);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Constants.setSelectedFeedId(null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
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
              Icon(
                selected ? Icons.newspaper_rounded : Icons.newspaper_outlined,
                size: 14.5,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
              const SizedBox(width: 5),
              Text(
                Constants.ALL_NEWSPAPERS,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 3.5),
                Text(
                  '($count)',
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
    );
  }

  Widget _buildSheetNewspaperChip({
    required Feed feed,
    required bool selected,
    int? count,
  }) {
    const activeNavy = Color(0xFF0F2942);
    final hasLogo = Constants.resolveImageUrl(feed.imageUrl).isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (selected) {
            Constants.setSelectedFeedId(null);
          } else {
            Constants.setSelectedFeedId(feed.id);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 5.0),
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
              if (hasLogo) ...[
                FeedImage(
                  item: feed,
                  width: 28,
                  height: 15,
                  compact: true,
                ),
                const SizedBox(width: 5),
              ] else ...[
                Icon(
                  selected ? Icons.newspaper_rounded : Icons.newspaper_outlined,
                  size: 14,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                feed.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 3.5),
                Text(
                  '($count)',
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
    );
  }
}
