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
    var feeds;

    try {
      final response = await http.get(Constants.URL_FEEDS);
      if (response.statusCode == 200) {
        feeds = (json.decode(response.body) as List).map((i) =>
            Feed.fromJson(i)).toList();
        _storage.write(feeds);
      }
      feeds = await readFromStorage();
    } on SocketException catch (_) {
      feeds = await readFromStorage();
    }
    return feeds;
  }

  Future<List<Feed>> readFromStorage() async {
    var feeds = _storage.read();
    if (feeds == null) {
      throw Exception('Failed to load feeds');
    }
    return feeds;
  }
}