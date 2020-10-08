import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed_model.dart';

Future<Feed> fetchFeed(String feedId) async {
  // TODO: Externalize URLs
  var response =
      await http.get('https://amathus-web-y5l3hnrsla-ew.a.run.app/api/v1/feeditems/$feedId');
  if (response.statusCode == 200) {
    return parseFeed(response.body);
  } else {
    throw Exception('Failed to load feeds');
  }
}

Feed parseFeed(String responseBody) {
  var parsed = json.decode(responseBody);
  return Feed.fromJson(parsed);
}
