import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/controllers/feeds_storage.dart';
import 'package:amathus/controllers/notifications_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Constants.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            titleSpacing: 4,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(Constants.SETTINGS),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(left: 8, right: 12),
                child: Center(
                  child: AppLanguageButton(lightOnDark: true),
                ),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: const _ReorderableFeedList(),
        );
      },
    );
  }
}

class _ReorderableFeedList extends StatefulWidget {
  const _ReorderableFeedList();

  @override
  State<_ReorderableFeedList> createState() => _ReorderableFeedListState();
}

class _ReorderableFeedListState extends State<_ReorderableFeedList> {
  final FeedsStorage _storage = FeedsStorage();
  final FeedsController _controller = FeedsController();
  List<Feed>? _items;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    var stored = await _storage.read();
    if (stored == null || stored.isEmpty) {
      stored = await _controller.readAll();
    }
    if (mounted) {
      setState(() {
        _items = stored ?? <Feed>[];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) {
      return const CenteredProgressIndicator();
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.hiddenFeedsNotifier,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        final visibleCount =
            items.where((f) => Constants.isFeedVisible(f.id)).length;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ReorderableListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              buildDefaultDragHandles: false,
              header: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _NotificationsSettingsCard(),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2942)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.newspaper_rounded,
                            size: 19,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Constants.REORDER_NEWS,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$visibleCount / ${items.length}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F2942),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Constants.REORDER_HINT,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.blueGrey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              onReorderItem: _onReorderItem,
              children: [
                for (var i = 0; i < items.length; i++)
                  _FeedCard(
                    key: ValueKey(items[i].id),
                    item: items[i],
                    index: i,
                    isVisible: Constants.isFeedVisible(items[i].id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    final items = _items;
    if (items == null) return;
    setState(() {
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });

    FeedsController.setCachedFeeds(items);
    _storage.write(items);
  }
}

class _FeedCard extends StatelessWidget {
  final Feed item;
  final int index;
  final bool isVisible;

  const _FeedCard({
    super.key,
    required this.item,
    required this.index,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isVisible
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        color: isVisible ? Colors.white : const Color(0xFFF8FAFC),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Opacity(
            opacity: isVisible ? 1.0 : 0.45,
            child: FeedImage(
              item: item,
              width: 84,
              height: 34,
              compact: true,
            ),
          ),
          title: Opacity(
            opacity: isVisible ? 1.0 : 0.5,
            child: Text(
              item.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                decoration: isVisible ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 21,
                  color: isVisible
                      ? const Color(0xFF0F2942)
                      : const Color(0xFF94A3B8),
                ),
                onPressed: () {
                  Constants.setFeedVisible(item.id, !isVisible);
                },
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 22,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsSettingsCard extends StatelessWidget {
  const _NotificationsSettingsCard();

  @override
  Widget build(BuildContext context) {
    final controller = NotificationsController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.enabledNotifier,
        controller.editionsNotifier,
        controller.syncingNotifier,
        controller.statusErrorNotifier,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        final isEnabled = controller.enabledNotifier.value;
        final editions = controller.editionsNotifier.value;
        final isSyncing = controller.syncingNotifier.value;
        final errorMsg = controller.statusErrorNotifier.value;
        final needsIosPwa = controller.needsIosHomeScreenInstall;

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2942).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        isEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_outlined,
                        size: 19,
                        color: const Color(0xFF0F2942),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Constants.NOTIFICATIONS_TITLE,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isSyncing)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                      ),
                    Switch.adaptive(
                      value: isEnabled,
                      activeTrackColor: const Color(0xFF0F2942),
                      onChanged: isSyncing
                          ? null
                          : (value) {
                              controller.setEnabled(value);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  Constants.NOTIFICATIONS_SUBTITLE,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.blueGrey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _EditionChip(
                      label: Constants.NOTIFICATIONS_MORNING,
                      icon: Icons.wb_sunny_outlined,
                      selected: editions.contains('morning'),
                      enabled: !isSyncing,
                      onSelected: () => controller.toggleEdition('morning'),
                    ),
                    _EditionChip(
                      label: Constants.NOTIFICATIONS_MIDDAY,
                      icon: Icons.light_mode_outlined,
                      selected: editions.contains('midday'),
                      enabled: !isSyncing,
                      onSelected: () => controller.toggleEdition('midday'),
                    ),
                    _EditionChip(
                      label: Constants.NOTIFICATIONS_EVENING,
                      icon: Icons.nights_stay_outlined,
                      selected: editions.contains('evening'),
                      enabled: !isSyncing,
                      onSelected: () => controller.toggleEdition('evening'),
                    ),
                  ],
                ),
                if (needsIosPwa) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.ios_share_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            Constants.NOTIFICATIONS_IOS_PWA_HINT,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (errorMsg != null && errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  const _EditionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : const Color(0xFF0F2942),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFF0F2942),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide(
        color: selected ? const Color(0xFF0F2942) : const Color(0xFFCBD5E1),
      ),
      onSelected: enabled ? (_) => onSelected() : null,
    );
  }
}
