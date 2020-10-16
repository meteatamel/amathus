import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

Future<Feed> fetchFeed(String feedId) async {
  var response = await http.get(Constants.URL_FEED_ITEMS + "/$feedId");
  if (response.statusCode == 200) {
    return parseFeed(response.body);
  }
  throw Exception('Failed to load feeds');
}

Feed parseFeed(String responseBody) {
  var parsed = json.decode(responseBody);
  return Feed.fromJson(parsed);
}
