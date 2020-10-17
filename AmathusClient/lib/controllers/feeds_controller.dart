import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

import 'feeds_storage.dart';

class FeedsController {

  FeedsStorage _storage;
  List<Feed> _storedFeeds;

  FeedsController() {
    _storage = new FeedsStorage();
  }

  Future<List<Feed>> readFromServer() async {

    try {
      final response = await http.get(Constants.URL_FEEDS);
      if (response.statusCode == 200) {
        final receivedFeeds = (json.decode(response.body) as List).map((i) =>
            Feed.fromJson(i)).toList();
        return receivedFeeds;
      }
    } on SocketException catch (e) {
      // Just return the stored feeds
      print("Cannot connect to server: ${e.message}");
    }

    return null;
  }

  Future<List<Feed>> readFromStorage() async {
    _storedFeeds = await _storage.read();
    return _storedFeeds;
  }

  Future<void> writeToStorage(List<Feed> feeds) async {
    await _storage.write(feeds);
    _storedFeeds= feeds;
  }

  Future<List<Feed>> orderAndStoreFeeds(List<Feed> receivedFeeds) async {
    if (receivedFeeds == null || receivedFeeds.isEmpty) {
      return _storedFeeds;
    }

    if (_storedFeeds == null || _storedFeeds.isEmpty) {
      await writeToStorage(receivedFeeds);
      return receivedFeeds;
    }

    var orderedFeeds = new List<Feed>();

    for (var i = 0; i < _storedFeeds.length; i++) {
      var storedFeed = _storedFeeds[i];
      var index = receivedFeeds.indexWhere((element) => element.id == storedFeed.id);
      if (index != -1) {
        var receivedFeed = receivedFeeds.removeAt(index);
        orderedFeeds.add(receivedFeed);
      }
    }

    orderedFeeds.addAll(receivedFeeds);
    writeToStorage(orderedFeeds);
    return orderedFeeds;
  }
}