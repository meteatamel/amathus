import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class FeedItemsController {
  Future<Feed?> readById(String feedId) async {
    try {
      final response =
          await http.get(Uri.parse("${Constants.URL_FEED_ITEMS}/$feedId"));
      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return Feed.fromJson(decoded);
      }
    } catch (e) {
      // Ignore network error
    }

    return null;
  }

  Future<List<Feed>?> readRecent({int limit = 100}) async {
    try {
      final response =
          await http.get(Uri.parse("${Constants.URL_FEED_ITEMS}?limit=$limit"));
      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return decoded
            .map((i) => Feed.fromJson(i as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Ignore network error
    }

    return null;
  }
}
