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

  Future<List<Feed>> readAll() async {

    try {
      final response = await http.get(Constants.URL_FEEDS);
      if (response.statusCode == 200) {
        final receivedFeeds = (json.decode(response.body) as List).map((i) =>
            Feed.fromJson(i)).toList();
        var orderedFeeds = await _orderAndStoreFeeds(receivedFeeds);
        return orderedFeeds;
      }
    } on SocketException catch (e) {
      print("Cannot connect to server: ${e.message}");
    }

    return null;
  }

  Future<List<Feed>> readAllStored() async {
    _storedFeeds = await _storage.read();
    return _storedFeeds;
  }

  Future<List<Feed>> _orderAndStoreFeeds(List<Feed> receivedFeeds) async {
    if (receivedFeeds == null || receivedFeeds.isEmpty) {
      return _storedFeeds;
    }

    if (_storedFeeds == null || _storedFeeds.isEmpty) {
      await _writeToStorage(receivedFeeds);
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
    _writeToStorage(orderedFeeds);
    return orderedFeeds;
  }

  Future<void> _writeToStorage(List<Feed> feeds) async {
    await _storage.write(feeds);
    _storedFeeds= feeds;
  }
}