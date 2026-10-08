import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;

import 'feeds_storage.dart';

class FeedsController {
  final FeedsStorage _storage = FeedsStorage();
  static List<Feed>? _storedFeeds;

  static void clearCache() {
    _storedFeeds = null;
  }

  Future<List<Feed>?> readAll() async {
    try {
      final response = await http.get(Uri.parse(Constants.URL_FEEDS));
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        final receivedFeeds = decoded
            .map((i) => Feed.fromJson(i as Map<String, dynamic>))
            .toList();
        final orderedFeeds = await _orderAndStoreFeeds(receivedFeeds);
        return orderedFeeds;
      }
    } catch (e) {
      // Ignore network error and fall back to stored feeds
    }

    return _storedFeeds ?? await readAllStored();
  }

  Future<List<Feed>?> readAllStored() async {
    if (_storedFeeds != null && _storedFeeds!.isNotEmpty) {
      return _storedFeeds;
    }
    _storedFeeds = await _storage.read();
    return _storedFeeds;
  }

  Future<List<Feed>?> _orderAndStoreFeeds(List<Feed> receivedFeeds) async {
    if (receivedFeeds.isEmpty) {
      return _storedFeeds;
    }

    _storedFeeds ??= await _storage.read();

    if (_storedFeeds == null || _storedFeeds!.isEmpty) {
      await _writeToStorage(receivedFeeds);
      return receivedFeeds;
    }

    final remaining = List<Feed>.from(receivedFeeds);
    final orderedFeeds = <Feed>[];

    for (final storedFeed in _storedFeeds!) {
      final index = remaining.indexWhere((element) => element.id == storedFeed.id);
      if (index != -1) {
        orderedFeeds.add(remaining.removeAt(index));
      }
    }

    orderedFeeds.addAll(remaining);
    await _writeToStorage(orderedFeeds);
    return orderedFeeds;
  }

  Future<void> _writeToStorage(List<Feed> feeds) async {
    await _storage.write(feeds);
    _storedFeeds = feeds;
  }
}