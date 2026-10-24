import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feeds_list.dart';
import 'package:amathus/views/common/source_language_filter_bar.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class FeedsView extends StatefulWidget {
  const FeedsView({super.key});

  @override
  State<FeedsView> createState() => _FeedsViewState();
}

class _FeedsViewState extends State<FeedsView> {
  final FeedsController _controller = FeedsController();
  final ValueNotifier<List<Feed>> _feedsNotifier =
      ValueNotifier<List<Feed>>(const []);

  @override
  void dispose() {
    _feedsNotifier.dispose();
    super.dispose();
  }

  Map<String, int>? _computeSourceCounts() {
    final feeds = _feedsNotifier.value;
    if (feeds.isEmpty) return null;
    final counts = <String, int>{
      'all': 0,
      'el': 0,
      'tr': 0,
      'en': 0,
    };
    var total = 0;
    for (final feed in feeds) {
      if (!Constants.isFeedVisible(feed.id)) continue;
      final lang = Constants.resolveFeedLanguage(feed.id, feed.language);
      counts[lang] = (counts[lang] ?? 0) + 1;
      total++;
    }
    if (total == 0) return null;
    counts['all'] = total;
    return counts;
  }

  Future<List<Feed>?> _loadStored() async {
    final feeds = await _controller.readAllStored();
    if (feeds != null && feeds.isNotEmpty) {
      _feedsNotifier.value = feeds;
    }
    return feeds;
  }

  Future<List<Feed>?> _loadServer() async {
    final feeds = await _controller.readAll();
    if (feeds != null && feeds.isNotEmpty) {
      _feedsNotifier.value = feeds;
    }
    return feeds;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Constants.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            titleSpacing: 4,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Transform.scale(
                        scale: 1.14,
                        child: Image.asset(
                          'assets/launcher/icon.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      Constants.NEWSPAPERS,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(left: 8, right: 12),
                child: Center(
                  child: AppLanguageButton(lightOnDark: true),
                ),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([
                  Constants.hiddenFeedsNotifier,
                  _feedsNotifier,
                ]),
                builder: (context, _) => SourceLanguageFilterBar(
                  countsBySource: _computeSourceCounts(),
                ),
              ),
              Expanded(
                child: FeedsList(
                  loadDataStorageCallback: _loadStored,
                  loadDataServerCallback: _loadServer,
                ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 2),
        );
      },
    );
  }
}
