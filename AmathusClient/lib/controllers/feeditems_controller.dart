import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

import 'feeditems_storage.dart';

class FeedItemsController {
  final FeedItemsStorage _storage = FeedItemsStorage();

  static List<Feed>? _cachedRecentFeeds;
  static final Map<String, Feed> _cachedFeedsById = {};

  static void clearCache() {
    _cachedRecentFeeds = null;
    _cachedFeedsById.clear();
  }

  String _normId(String feedId) => feedId.trim().toLowerCase();

  Future<Feed?> readByIdStored(String feedId) async {
    final key = _normId(feedId);
    final inMemory = _cachedFeedsById[key];
    if (inMemory != null) {
      return inMemory;
    }

    final stored = await _storage.readById(key);
    if (stored != null) {
      _cachedFeedsById[key] = stored;
      return stored;
    }

    final recentFeeds = await readRecentStored();
    if (recentFeeds != null) {
      for (final feed in recentFeeds) {
        if (_normId(feed.id) == key) {
          _cachedFeedsById[key] = feed;
          return feed;
        }
      }
    }

    return null;
  }

  Future<Feed?> readById(String feedId) async {
    final key = _normId(feedId);
    try {
      final response =
          await http.get(Uri.parse("${Constants.URL_FEED_ITEMS}/$feedId"));
      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final feed = Feed.fromJson(decoded);
        _cachedFeedsById[key] = feed;
        await _storage.writeById(feed);
        return feed;
      }
    } catch (e) {
      // Ignore network error and fall back to cached feed items
    }

    return await readByIdStored(feedId);
  }

  Future<List<Feed>?> readRecentStored() async {
    if (_cachedRecentFeeds != null && _cachedRecentFeeds!.isNotEmpty) {
      return _cachedRecentFeeds;
    }

    final stored = await _storage.readRecent();
    if (stored != null && stored.isNotEmpty) {
      _cachedRecentFeeds = stored;
      for (final feed in stored) {
        _cachedFeedsById.putIfAbsent(_normId(feed.id), () => feed);
      }
      return stored;
    }

    return _cachedRecentFeeds;
  }

  Future<List<Feed>?> readRecent({int limit = 200}) async {
    try {
      final response =
          await http.get(Uri.parse("${Constants.URL_FEED_ITEMS}?limit=$limit"));
      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        final feeds = decoded
            .map((i) => Feed.fromJson(i as Map<String, dynamic>))
            .toList();
        if (feeds.isNotEmpty) {
          _cachedRecentFeeds = feeds;
          for (final feed in feeds) {
            _cachedFeedsById.putIfAbsent(_normId(feed.id), () => feed);
          }
          await _storage.writeRecent(feeds);
          return feeds;
        }
      }
    } catch (e) {
      // Ignore network error and fall back to cached recent feeds
    }

    return await readRecentStored();
  }
}
