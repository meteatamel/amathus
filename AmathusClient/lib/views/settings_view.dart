import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/controllers/feeds_storage.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/flag_icon.dart';
import 'package:amathus/views/common/progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(Constants.SETTINGS),
      ),
      drawer: const AppDrawer(),
      body: const _ReorderableFeedList(),
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

    return ValueListenableBuilder<Set<String>>(
      valueListenable: Constants.hiddenFeedsNotifier,
      builder: (context, hiddenIds, _) {
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
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.language_rounded,
                                  color: Color(0xFF0F2942),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  Constants.LANGUAGE_TITLE,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Constants.LANGUAGE_SUBTITLE,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment<String>(
                                    value: 'tr',
                                    label: Text('Türkçe'),
                                    icon: FlagIcon(languageCode: 'tr'),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'el',
                                    label: Text('Ελληνικά'),
                                    icon: FlagIcon(languageCode: 'el'),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'en',
                                    label: Text('English'),
                                    icon: FlagIcon(languageCode: 'en'),
                                  ),
                                ],
                                selected: {Constants.currentLanguage},
                                onSelectionChanged: (selection) {
                                  if (selection.isNotEmpty) {
                                    Constants.setLanguage(selection.first);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: ValueListenableBuilder<String>(
                          valueListenable: Constants.sourceLanguageNotifier,
                          builder: (context, selectedSourceLang, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.filter_list_rounded,
                                      color: Color(0xFF0F2942),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      Constants.SOURCE_LANGUAGE_TITLE,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  Constants.SOURCE_LANGUAGE_SUBTITLE,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<String>(
                                    segments: [
                                      ButtonSegment<String>(
                                        value: 'all',
                                        label:
                                            Text(Constants.SOURCE_FILTER_ALL),
                                        icon: const Icon(
                                          Icons.public_rounded,
                                          size: 16,
                                        ),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'tr',
                                        label: Text(Constants.SOURCE_FILTER_TR),
                                        icon: const FlagIcon(
                                          languageCode: 'tr',
                                        ),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'el',
                                        label: Text(Constants.SOURCE_FILTER_EL),
                                        icon: const FlagIcon(
                                          languageCode: 'el',
                                        ),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'en',
                                        label: Text(Constants.SOURCE_FILTER_EN),
                                        icon: const FlagIcon(
                                          languageCode: 'en',
                                        ),
                                      ),
                                    ],
                                    selected: {selectedSourceLang},
                                    onSelectionChanged: (selection) {
                                      if (selection.isNotEmpty) {
                                        Constants.setSourceLanguage(
                                          selection.first,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.newspaper_rounded,
                          size: 20,
                          color: Color(0xFF0F2942),
                        ),
                        const SizedBox(width: 8),
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
