import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

Future<List<Feed>> fetchFeeds() async {
  final response = await http.get(Constants.URL_FEEDS);
  if (response.statusCode == 200) {
    final feeds = (json.decode(response.body) as List).map((i) => Feed.fromJson(i)).toList();
    return feeds;
  }
  throw Exception('Failed to load feeds');
}