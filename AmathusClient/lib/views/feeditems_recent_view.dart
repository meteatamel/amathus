import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:amathus/views/common/source_language_filter_bar.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'common/drawer.dart';

class FeedItemsRecentView extends StatelessWidget {
  final FeedItemsController _controller = FeedItemsController();
  final BulkTranslateController _bulkTranslateController =
      BulkTranslateController();

  FeedItemsRecentView({super.key});

  bool _matchesVisibleFilter(FeedItem item) {
    return item.feed == null ||
        Constants.matchesSourceLanguage(
          item.feed?.id,
          item.feed?.language,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 4,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Transform.scale(
                    scale: 1.14,
                    child: Image.asset(
                      'assets/launcher/icon.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  Constants.RECENT_NEWS,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 12),
            child: Center(
              child: BulkTranslateIconButton(
                controller: _bulkTranslateController,
                itemFilter: _matchesVisibleFilter,
                lightOnDark: true,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const SourceLanguageFilterBar(
            showNewspaperSelector: true,
          ),
          Expanded(
            child: FeedItemsList(
              loadDataStorageCallback: loadCachedData,
              loadDataCallback: loadData,
              wideTile: true,
              bulkController: _bulkTranslateController,
              bannerText: Constants.RECENT_NEWS_BANNER,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 1),
    );
  }

  Future<List<FeedItem>?> loadCachedData() async {
    final feeds = await _controller.readRecentStored();
    return _extractSortedItems(feeds);
  }

  Future<List<FeedItem>?> loadData() async {
    final feeds = await _controller.readRecent();
    return _extractSortedItems(feeds);
  }

  List<FeedItem>? _extractSortedItems(List<dynamic>? feeds) {
    if (feeds == null) {
      return null;
    }

    final feedItems = <FeedItem>[];
    for (final feed in feeds) {
      if (feed.items != null) {
        for (final item in feed.items!) {
          if (!item.isColumnist) {
            feedItems.add(item);
          }
        }
      }
    }
    feedItems.sort((a, b) => b.publishDate.compareTo(a.publishDate));
    return feedItems;
  }
}
