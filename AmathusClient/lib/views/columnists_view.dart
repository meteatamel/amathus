import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:amathus/views/common/source_language_filter_bar.dart';
import 'package:flutter/material.dart';

class ColumnistsView extends StatefulWidget {
  const ColumnistsView({super.key});

  @override
  State<ColumnistsView> createState() => _ColumnistsViewState();
}

class _ColumnistsViewState extends State<ColumnistsView> {
  final FeedItemsController _controller = FeedItemsController();
  final BulkTranslateController _bulkTranslateController =
      BulkTranslateController();
  final ValueNotifier<List<FeedItem>> _itemsNotifier =
      ValueNotifier<List<FeedItem>>(const []);
  final ValueNotifier<Set<String>?> _columnistFeedIdsNotifier =
      ValueNotifier<Set<String>?>(null);

  @override
  void dispose() {
    _itemsNotifier.dispose();
    _columnistFeedIdsNotifier.dispose();
    super.dispose();
  }

  bool _matchesColumnistFilter(FeedItem item) {
    final selectedAuthor = Constants.selectedColumnistNotifier.value;
    if (selectedAuthor == null || selectedAuthor.trim().isEmpty) {
      return true;
    }
    return (item.author ?? '').trim() == selectedAuthor.trim();
  }

  bool _matchesVisibleFilter(FeedItem item) {
    final baseMatch = item.feed == null ||
        Constants.matchesSourceLanguage(
          item.feed?.id,
          item.feed?.language,
        );
    if (!baseMatch) return false;
    return _matchesColumnistFilter(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/launcher/icon.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                Constants.COLUMNISTS,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          SourceLanguageFilterBar(
            bulkController: _bulkTranslateController,
            itemFilter: _matchesVisibleFilter,
            showNewspaperSelector: true,
            allowedNewspaperIdsListenable: _columnistFeedIdsNotifier,
            extraSelector: ColumnistDropdownSelector(
              itemsListenable: _itemsNotifier,
            ),
          ),
          Expanded(
            child: FeedItemsList(
              loadDataStorageCallback: loadCachedData,
              loadDataCallback: loadData,
              wideTile: true,
              bulkController: _bulkTranslateController,
              bannerText: Constants.COLUMNISTS_BANNER,
              bannerIcon: Icons.edit_note_rounded,
              customFilter: _matchesColumnistFilter,
              extraListenable: Constants.selectedColumnistNotifier,
              columnistsOnly: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 2),
    );
  }

  Future<List<FeedItem>?> loadCachedData() async {
    final feeds = await _controller.readColumnistsStored();
    return _extractSortedItems(feeds);
  }

  Future<List<FeedItem>?> loadData() async {
    final feeds = await _controller.readColumnists();
    return _extractSortedItems(feeds);
  }

  List<FeedItem>? _extractSortedItems(List<dynamic>? feeds) {
    if (feeds == null) {
      return null;
    }

    final feedItems = <FeedItem>[];
    final feedIds = <String>{};
    for (final feed in feeds) {
      if (feed.items != null && feed.items!.isNotEmpty) {
        for (final item in feed.items!) {
          if (item.isColumnist) {
            feedItems.add(item);
            feedIds.add(feed.id.toString().trim().toLowerCase());
          }
        }
      }
    }
    feedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    _itemsNotifier.value = feedItems;
    if (feedIds.isNotEmpty) {
      _columnistFeedIdsNotifier.value = feedIds;
    }
    return feedItems;
  }
}
