import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

import 'feeds_storage.dart';

class FeedsController {

  FeedsStorage _storage;

  FeedsController() {
    _storage = new FeedsStorage();
  }

  Future<List<Feed>> read() async {
    final storedFeeds = await readFromStorage();

    try {
      final response = await http.get(Constants.URL_FEEDS);
      if (response.statusCode == 200) {
        final receivedFeeds = (json.decode(response.body) as List).map((i) =>
            Feed.fromJson(i)).toList();
        final orderedFeeds = await orderAndStoreFeeds(storedFeeds, receivedFeeds);
        return orderedFeeds;
      }
    } on SocketException catch (e) {
      // Just return the stored feeds
    }

    return storedFeeds;
  }

  Future<List<Feed>> readFromStorage() async {
    var feeds = await _storage.read();
    if (feeds == null) {
      throw Exception('Failed to load feeds');
    }
    return feeds;
  }

  Future<List<Feed>> orderAndStoreFeeds(List<Feed> storedFeeds, List<Feed> receivedFeeds) async {
    if (receivedFeeds == null || receivedFeeds.isEmpty) {
      return storedFeeds;
    }

    if (storedFeeds == null || storedFeeds.isEmpty) {
      await _storage.write(receivedFeeds);
      return receivedFeeds;
    }

    var orderedFeeds = new List<Feed>();

    for (var i = 0; i < storedFeeds.length; i++) {
      var storedFeed = storedFeeds[i];
      var index = receivedFeeds.indexWhere((element) => element.id == storedFeed.id);
      if (index != -1) {
        var receivedFeed = receivedFeeds.removeAt(index);
        orderedFeeds.add(receivedFeed);
      }
    }

    orderedFeeds.addAll(receivedFeeds);
    await _storage.write(orderedFeeds);

    return orderedFeeds;
  }
}