import 'dart:convert';

import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:shared_preferences/shared_preferences.dart';

class FeedItemsStorage {
  String _byIdKey(String feedId) =>
      '${Constants.FEED_ITEMS_BY_ID_PREFIX}${feedId.trim().toLowerCase()}';

  Future<List<Feed>?> readRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedsJson = prefs.getString(Constants.FEED_ITEMS_RECENT_KEY);
      if (feedsJson == null || feedsJson.isEmpty) {
        return null;
      }
      final decoded = json.decode(feedsJson) as List<dynamic>;
      return decoded
          .map((i) => Feed.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  Future<bool> writeRecent(List<Feed> feeds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedsJson = json.encode(feeds.map((f) => f.toJson()).toList());
      return await prefs.setString(Constants.FEED_ITEMS_RECENT_KEY, feedsJson);
    } catch (e) {
      return false;
    }
  }

  Future<Feed?> readById(String feedId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedJson = prefs.getString(_byIdKey(feedId));
      if (feedJson == null || feedJson.isEmpty) {
        return null;
      }
      final decoded = json.decode(feedJson) as Map<String, dynamic>;
      return Feed.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  Future<bool> writeById(Feed feed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedJson = json.encode(feed.toJson());
      return await prefs.setString(_byIdKey(feed.id), feedJson);
    } catch (e) {
      return false;
    }
  }
}
