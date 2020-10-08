import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed_model.dart';
import 'package:flutter/services.dart';

// For testing
Future loadLocalFeed() async {
  String jsonString = await rootBundle.loadString('assets/feeds.json');
  final jsonResponse = json.decode(jsonString);
  var feed = new Feed.fromJson(jsonResponse);
  print(feed.title);
}

Future<List<Feed>> fetchFeeds() async {
  // TODO: Externalize URLs
  var response =
      await http.get('https://amathus-web-y5l3hnrsla-ew.a.run.app/api/v1/feeds');
  if (response.statusCode == 200) {
    return parseFeeds(response.body);
  } else {
    throw Exception('Failed to load feeds');
  }
}

List<Feed> parseFeeds(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Feed>((json) => Feed.fromJson(json)).toList();
}
