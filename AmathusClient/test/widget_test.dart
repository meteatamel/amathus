import 'dart:async';
import 'package:amathus/controllers/feeditems_controller.dart';
import 'package:amathus/controllers/feeditems_storage.dart';
import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/controllers/overview_controller.dart';
import 'package:amathus/main.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/feeditems_list.dart';
import 'package:amathus/views/common/share_iconbutton.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:amathus/views/overview_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    FeedItemsController.clearCache();
    FeedsController.clearCache();
    OverviewController.clearCache();
    Constants.setSelectedFeedId(null);
  });

  testWidgets(
      'Amathus app renders Top Stories as default first tab, Latest News as second, and toggles Turkish/Greek/English',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.initLanguage();
    await Constants.setLanguage('tr');
    await Constants.setSourceLanguage('all');

    await tester.pumpWidget(const AmathusApp());

    // Turkish labels: Öne Çıkan Haberler (header + first tab), Son Haberler (second tab)
    expect(find.text('Öne Çıkan Haberler'), findsNWidgets(2));
    expect(find.text('Son Haberler'), findsOneWidget);
    expect(find.text('Tümü'), findsOneWidget);

    // Switch to Greek
    await Constants.setLanguage('el');
    await tester.pump();

    expect(find.text('Κυριότερες Ειδήσεις'), findsNWidgets(2));
    expect(find.text('Τελευταία Νέα'), findsOneWidget);
    expect(find.text('Όλα'), findsOneWidget);

    // Switch to English
    await Constants.setLanguage('en');
    await tester.pump();

    expect(find.text('Top Stories'), findsNWidgets(2));
    expect(find.text('Latest News'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets(
      'OverviewView renders top stories in English, Turkish, and Greek and opens FeedItemView when tapping a newspaper link',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.initLanguage();
    await Constants.setLanguage('en');
    await Constants.setSourceLanguage('all');

    final mockOverview = NewsOverview(
      id: 'latest',
      generatedAt: DateTime(2026, 10, 22, 12, 0),
      totalFeedsAnalyzed: 34,
      totalArticlesAnalyzed: 120,
      summaryEn: 'English daily summary across Cyprus.',
      summaryTr: 'Kıbrıs genelinde Türkçe günlük özet.',
      summaryEl: 'Ελληνική ημερήσια σύνοψη στην Κύπρο.',
      stories: [
        OverviewStory(
          id: 'story-1',
          titleEn: 'New Crossing Point Discussions Advance',
          titleTr: 'Yeni Geçiş Noktası Görüşmeleri İlerliyor',
          titleEl: 'Προχωρούν οι συζητήσεις για νέο σημείο διέλευσης',
          narrativeEn: 'Newspapers across both communities report progress on crossing points.',
          narrativeTr: 'Her iki toplumdaki gazeteler geçiş noktalarında ilerleme bildiriyor.',
          narrativeEl: 'Οι εφημερίδες και των δύο κοινοτήτων αναφέρουν πρόοδο.',
          publishDate: DateTime(2026, 10, 22, 11, 30),
          sources: [
            OverviewStorySource(
              feedId: 'yeniduzen',
              feedTitle: 'Yenidüzen',
              feedLanguage: 'tr',
              article: FeedItem(
                'Geçiş kapılarında yeni adım',
                DateTime(2026, 10, 22, 11, 30),
                'Yenidüzen özeti',
                '<p>Yenidüzen detay metni</p>',
                null,
                'https://www.yeniduzen.com/gecis',
              ),
            ),
            OverviewStorySource(
              feedId: 'cyprusmail',
              feedTitle: 'Cyprus Mail',
              feedLanguage: 'en',
              article: FeedItem(
                'Progress on crossing points discussed',
                DateTime(2026, 10, 22, 11, 15),
                'Cyprus Mail summary',
                '<p>Cyprus Mail detail</p>',
                null,
                'https://cyprus-mail.com/crossing',
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OverviewView(
          loadCachedCallback: () async => mockOverview,
          loadServerCallback: ({bool refresh = false}) async => mockOverview,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New Crossing Point Discussions Advance'), findsOneWidget);
    expect(find.text('English daily summary across Cyprus.'), findsOneWidget);
    expect(find.text('Yenidüzen'), findsWidgets);
    expect(find.text('Cyprus Mail'), findsWidgets);

    // Switch language to Turkish and verify Turkish title & narrative display
    await Constants.setLanguage('tr');
    await tester.pump();
    expect(find.text('Yeni Geçiş Noktası Görüşmeleri İlerliyor'), findsOneWidget);
    expect(find.text('Kıbrıs genelinde Türkçe günlük özet.'), findsOneWidget);

    // Switch language to Greek and verify Greek title & narrative display
    await Constants.setLanguage('el');
    await tester.pump();
    expect(
      find.text('Προχωρούν οι συζητήσεις για νέο σημείο διέλευσης'),
      findsOneWidget,
    );
    expect(find.text('Ελληνική ημερήσια σύνοψη στην Κύπρο.'), findsOneWidget);

    // Tap newspaper chip to open FeedItemView
    await tester.tap(find.text('Yenidüzen').first);
    await tester.pumpAndSettle();

    expect(find.byType(FeedItemView), findsOneWidget);
    expect(find.text('Geçiş kapılarında yeni adım'), findsOneWidget);
  });

  testWidgets(
      'FeedItemView renders TranslateIconButton, ShareIconButton, flag-only SourceAndTranslationBadges, and hiding newspapers filters them out',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.initLanguage();
    await Constants.setLanguage('en');
    await Constants.setSourceLanguage('all');

    expect(Constants.targetTranslationLanguagesFor('tr'), ['el', 'en']);
    expect(Constants.targetTranslationLanguagesFor('el'), ['tr', 'en']);
    expect(Constants.targetTranslationLanguagesFor('en'), ['tr', 'el']);

    expect(Constants.matchesSourceLanguage('yeniduzen', 'tr'), isTrue);
    await Constants.setFeedVisible('yeniduzen', false);
    expect(Constants.isFeedVisible('yeniduzen'), isFalse);
    expect(Constants.matchesSourceLanguage('yeniduzen', 'tr'), isFalse);
    await Constants.setFeedVisible('yeniduzen', true);
    expect(Constants.isFeedVisible('yeniduzen'), isTrue);
    expect(Constants.matchesSourceLanguage('yeniduzen', 'tr'), isTrue);

    final trFeed = Feed(
      'yeniduzen',
      'Yenidüzen',
      DateTime.now(),
      null,
      'https://www.yeniduzen.com',
      const [],
      'tr',
    );
    final trItem = FeedItem(
      'Lefkoşa haberi',
      DateTime.now(),
      'Özet metni',
      '<p>Detay metni</p>',
      null,
      'https://www.yeniduzen.com/haber-1',
    )..feed = trFeed;

    await tester.pumpWidget(
      MaterialApp(
        home: FeedItemView(item: trItem),
      ),
    );

    expect(find.byType(TranslateIconButton), findsOneWidget);
    expect(find.byType(ShareIconButton), findsOneWidget);
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.text('Read in'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.byType(SourceAndTranslationBadges), findsOneWidget);
  });

  testWidgets(
      'FeedItemsStorage persists feeds offline and FeedItemsList renders cached news immediately while refreshing in background',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.initLanguage();
    await Constants.setLanguage('en');
    await Constants.setSourceLanguage('all');

    final storage = FeedItemsStorage();
    final cachedItem = FeedItem(
      'Cached Offline Headline',
      DateTime(2026, 10, 8, 12, 0),
      'Cached summary',
      '<p>Cached detail</p>',
      null,
      'https://example.com/cached',
    );
    final cachedFeed = Feed(
      'cyprusmail',
      'Cyprus Mail',
      DateTime(2026, 10, 8, 12, 0),
      null,
      'https://cyprus-mail.com',
      [cachedItem],
      'en',
    );
    cachedItem.feed = cachedFeed;

    await storage.writeRecent([cachedFeed]);
    FeedItemsController.clearCache();

    final controller = FeedItemsController();
    final restoredRecent = await controller.readRecentStored();
    expect(restoredRecent, isNotNull);
    expect(restoredRecent!.single.items!.single.title, 'Cached Offline Headline');

    // Per-feed lookup also falls back to recent feeds cache when offline
    final restoredById = await controller.readByIdStored('cyprusmail');
    expect(restoredById, isNotNull);
    expect(restoredById!.items!.single.title, 'Cached Offline Headline');

    final serverCompleter = Completer<List<FeedItem>?>();
    final freshItem = FeedItem(
      'Fresh Background Headline',
      DateTime(2026, 10, 8, 13, 0),
      'Fresh summary',
      '<p>Fresh detail</p>',
      null,
      'https://example.com/fresh',
    )..feed = cachedFeed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedItemsList(
            loadDataStorageCallback: () async => [cachedItem],
            loadDataCallback: () => serverCompleter.future,
          ),
        ),
      ),
    );

    // Pump microtasks so cached items render before serverCompleter completes
    await tester.pump();

    expect(find.text('Cached Offline Headline'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Complete background server fetch
    serverCompleter.complete([freshItem]);
    await tester.pump();

    expect(find.text('Fresh Background Headline'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
