import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

Future<List<Feed>> readFromServer() async {

  try {
    final response = await http.get(Constants.URL_FEED_ITEMS + "?limit=100");
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
