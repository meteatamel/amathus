import 'dart:convert';
import 'package:amathus/controllers/overview_storage.dart';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:http/http.dart' as http;

class OverviewController {
  final OverviewStorage _storage = OverviewStorage();
  static NewsOverview? _cachedOverview;

  static void clearCache() {
    _cachedOverview = null;
  }

  Future<NewsOverview?> readStored() async {
    if (_cachedOverview != null && _cachedOverview!.stories.isNotEmpty) {
      return _cachedOverview;
    }
    final stored = await _storage.read();
    if (stored != null && stored.stories.isNotEmpty) {
      _cachedOverview = stored;
      return stored;
    }
    return _cachedOverview;
  }

  Future<NewsOverview?> read({bool refresh = false}) async {
    try {
      final url = refresh
          ? '${Constants.URL_OVERVIEW}?refresh=true'
          : Constants.URL_OVERVIEW;
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 40));
      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final overview = NewsOverview.fromJson(decoded);
        if (overview.stories.isNotEmpty) {
          _cachedOverview = overview;
          await _storage.write(overview);
          return overview;
        }
      }
    } catch (_) {
      // Ignore network error and fall back to cached overview
    }

    return await readStored();
  }
}
