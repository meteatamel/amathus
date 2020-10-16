import 'dart:convert';
import 'dart:io';

import 'package:amathus/models/feed.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:path_provider/path_provider.dart';

class FeedsStorage {

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/' + Constants.FEEDS_FILE);
  }

  Future<List<Feed>> read() async {
    try {
      final file = await _localFile;
      final feedsJson = await file.readAsString();
      final feeds = (json.decode(feedsJson) as List).map((i) => Feed.fromJson(i)).toList();
      return feeds;
    } catch (e) {
      return null;
    }
  }

  Future<File> write(List<Feed> feeds) async {
    final file = await _localFile;
    final feedsJson = json.encode(feeds);
    return await file.writeAsString('$feedsJson', mode: FileMode.write);
  }
}
