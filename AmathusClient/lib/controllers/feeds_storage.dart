import 'dart:convert';

import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:shared_preferences/shared_preferences.dart';

class FeedsStorage {
  Future<List<Feed>?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedsJson = prefs.getString(Constants.FEEDS_FILE);
      if (feedsJson == null || feedsJson.isEmpty) {
        return null;
      }
      final decoded = json.decode(feedsJson) as List<dynamic>;
      final feeds = decoded
          .map((i) => Feed.fromJson(i as Map<String, dynamic>))
          .toList();
      return feeds;
    } catch (e) {
      return null;
    }
  }

  Future<bool> write(List<Feed> feeds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedsJson = json.encode(feeds.map((f) => f.toJson()).toList());
      return await prefs.setString(Constants.FEEDS_FILE, feedsJson);
    } catch (e) {
      return false;
    }
  }
}
