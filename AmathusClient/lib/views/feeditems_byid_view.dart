import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/feed_image.dart';
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:flutter/material.dart';

class FeedItemsByIdView extends StatelessWidget {
  final Feed feed;
  final FeedItemsController _controller = FeedItemsController();
  final BulkTranslateController _bulkTranslateController =
      BulkTranslateController();

  FeedItemsByIdView({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    final sourceLang = Constants.resolveFeedLanguage(feed.id, feed.language);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeedImage(item: feed, width: 92, height: 34, compact: true),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                feed.title,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: BulkTranslateIconButton(
                controller: _bulkTranslateController,
                fixedSourceLanguage: sourceLang,
                lightOnDark: true,
              ),
            ),
          ),
        ],
      ),
      body: FeedItemsList(
        loadDataStorageCallback: loadCachedData,
        loadDataCallback: loadData,
        bulkController: _bulkTranslateController,
      ),
    );
  }

  Future<List<FeedItem>?> loadCachedData() async {
    final cachedFeed = await _controller.readByIdStored(feed.id);
    return cachedFeed?.items ?? feed.items;
  }

  Future<List<FeedItem>?> loadData() async {
    final updatedFeed = await _controller.readById(feed.id);
    return updatedFeed?.items;
  }
}
