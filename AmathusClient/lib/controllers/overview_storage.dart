import 'dart:convert';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:shared_preferences/shared_preferences.dart';

class OverviewStorage {
  Future<NewsOverview?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(Constants.OVERVIEW_STORAGE_KEY);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return NewsOverview.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(NewsOverview overview) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(overview.toJson());
      await prefs.setString(Constants.OVERVIEW_STORAGE_KEY, encoded);
    } catch (_) {
      // Ignore storage write errors
    }
  }
}
