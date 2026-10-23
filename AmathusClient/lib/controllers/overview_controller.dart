import 'dart:convert';
import 'package:amathus/controllers/overview_storage.dart';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:http/http.dart' as http;

class OverviewController {
  final bool columnistsOnly;
  late final OverviewStorage _storage;
  static NewsOverview? _cachedOverview;
  static NewsOverview? _cachedColumnistsOverview;

  OverviewController({this.columnistsOnly = false}) {
    _storage = OverviewStorage(
      storageKey: columnistsOnly
          ? Constants.COLUMNISTS_OVERVIEW_STORAGE_KEY
          : Constants.OVERVIEW_STORAGE_KEY,
    );
  }

  static void clearCache() {
    _cachedOverview = null;
    _cachedColumnistsOverview = null;
  }

  Future<NewsOverview?> readStored() async {
    final memCached =
        columnistsOnly ? _cachedColumnistsOverview : _cachedOverview;
    if (memCached != null && memCached.stories.isNotEmpty) {
      return memCached;
    }
    final stored = await _storage.read();
    if (stored != null && stored.stories.isNotEmpty) {
      if (columnistsOnly) {
        _cachedColumnistsOverview = stored;
      } else {
        _cachedOverview = stored;
      }
      return stored;
    }
    return memCached;
  }

  Future<NewsOverview?> read({bool refresh = false}) async {
    try {
      final queryParams = <String>[
        if (columnistsOnly) 'columnists=true',
        if (refresh) 'refresh=true',
      ];
      final url = queryParams.isEmpty
          ? Constants.URL_OVERVIEW
          : '${Constants.URL_OVERVIEW}?${queryParams.join('&')}';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 40));
      if (response.statusCode == 200) {
        final decoded =
            json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final overview = NewsOverview.fromJson(decoded);
        if (overview.stories.isNotEmpty) {
          if (columnistsOnly) {
            _cachedColumnistsOverview = overview;
          } else {
            _cachedOverview = overview;
          }
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
