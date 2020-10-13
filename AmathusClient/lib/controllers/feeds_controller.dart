import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed_model.dart';
import 'package:flutter/services.dart';
import 'package:amathus/utils/constants.dart' as Constants;

Future<List<Feed>> fetchFeeds() async {
  var response =  await http.get(Constants.URL_FEEDS);
  if (response.statusCode == 200) {
    return parseFeeds(response.body);
  }
  throw Exception('Failed to load feeds');
}

List<Feed> parseFeeds(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Feed>((json) => Feed.fromJson(json)).toList();
}

// TODO - For testing, remove when done.
Future loadLocalFeed() async {
  String jsonString = await rootBundle.loadString('assets/feeds.json');
  final jsonResponse = json.decode(jsonString);
  var feed = new Feed.fromJson(jsonResponse);
  print(feed.title);
}