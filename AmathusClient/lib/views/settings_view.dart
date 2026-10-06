import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/controllers/feeds_storage.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feed_image.dart';
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
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                                icon: Icon(Icons.translate_rounded, size: 18),
                              ),
                              ButtonSegment<String>(
                                value: 'en',
                                label: Text('English'),
                                icon: Icon(Icons.public_rounded, size: 18),
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
                const SizedBox(height: 22),
                Text(
                  Constants.REORDER_NEWS,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Constants.REORDER_HINT,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.blueGrey.shade600,
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
              ),
          ],
        ),
      ),
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

  const _FeedCard({
    super.key,
    required this.item,
    required this.index,
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
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        color: Colors.white,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: FeedImage(
            item: item,
            width: 84,
            height: 34,
            compact: true,
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          trailing: ReorderableDragStartListener(
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
        ),
      ),
    );
  }
}
