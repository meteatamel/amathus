import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class FeedItemsController {

  Future<Feed> readById(String feedId) async {

    try {
      final response = await http.get(Constants.URL_FEED_ITEMS + "/$feedId");
      if (response.statusCode == 200) {
        var decoded = json.decode(response.body);
        var feed = Feed.fromJson(decoded);
        return feed;
      }
    } on SocketException catch (e) {
      print("Cannot connect to server: ${e.message}");
    }

    return null;
  }

  Future<List<Feed>> readRecent({int limit = 100}) async {

    try {
      final response = await http.get(Constants.URL_FEED_ITEMS + "?limit=$limit");
      if (response.statusCode == 200) {
        final receivedFeeds = (json.decode(response.body) as List).map((i) =>
            Feed.fromJson(i)).toList();
        return receivedFeeds;
      }
    } on SocketException catch (e) {
      print("Cannot connect to server: ${e.message}");
    }

    return null;
  }


}
