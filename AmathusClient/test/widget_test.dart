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
    Constants.setSelectedTopic('all');
    Constants.setOverviewTranslateLanguage(null);
    Constants.newsViewModeNotifier.value = 'top';
    Constants.columnistsViewModeNotifier.value = 'top';
  });

  testWidgets(
      'Amathus app renders News as default first tab with Top Stories selector, Columnists as second tab, and toggles Turkish/Greek/English',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.initLanguage();
    await Constants.setLanguage('tr');
    await Constants.setSourceLanguage('all');

    await tester.pumpWidget(const AmathusApp());

    // Turkish labels: Kıbrıs İki Toplumlu Haberler (AppBar header), Öne Çıkan Haberler & Son Haberler (AppBar tabs), Haberler & Köşe Yazarları (bottom tabs)
    expect(find.text('Kıbrıs İki Toplumlu Haberler'), findsOneWidget);
    expect(find.text('Haberler'), findsOneWidget);
    expect(find.text('Öne Çıkan Haberler'), findsOneWidget);
    expect(find.text('Son Haberler'), findsOneWidget);
    expect(find.text('Köşe Yazarları'), findsOneWidget);
    expect(find.text('Tümü'), findsWidgets);

    // Switch to Greek
    await Constants.setLanguage('el');
    await tester.pump();

    expect(find.text('Δικοινοτικές Ειδήσεις Κύπρου'), findsOneWidget);
    expect(find.text('Ειδήσεις'), findsOneWidget);
    expect(find.text('Κυριότερες Ειδήσεις'), findsOneWidget);
    expect(find.text('Τελευταία Νέα'), findsOneWidget);
    expect(find.text('Αρθρογράφοι'), findsOneWidget);
    expect(find.text('Όλα'), findsWidgets);

    // Switch to English
    await Constants.setLanguage('en');
    await tester.pump();

    expect(find.text('Cyprus Bicommunal News'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Top Stories'), findsOneWidget);
    expect(find.text('Latest News'), findsOneWidget);
    expect(find.text('Columnists'), findsOneWidget);
    expect(find.text('All'), findsWidgets);
  });

  testWidgets(
      'OverviewView renders top stories in English, Turkish, and Greek, keeps story card non-clickable, and opens FeedItemView when tapping a newspaper logo',
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
              feedId: 'diyalog',
              feedTitle: 'Diyalog',
              feedLanguage: 'tr',
              article: FeedItem(
                'Geçiş kapılarında ilerleme',
                DateTime(2026, 10, 22, 11, 20),
                'Diyalog özeti',
                '<p>Diyalog detay metni</p>',
                null,
                'https://www.diyaloggazetesi.com/gecis',
              ),
            ),
            OverviewStorySource(
              feedId: 'philenews',
              feedTitle: 'Philenews',
              feedLanguage: 'el',
              article: FeedItem(
                'Συζητήσεις για οδοφράγματα',
                DateTime(2026, 10, 22, 11, 15),
                'Philenews summary',
                '<p>Philenews detail</p>',
                null,
                'https://philenews.com/crossing',
              ),
            ),
          ],
        ),
        OverviewStory(
          id: 'story-2',
          titleEn: 'Omonia and APOEL Prepare for Nicosia Football Derby',
          titleTr: 'Omonia ve APOEL Lefkoşa Futbol Derbisine Hazırlanıyor',
          titleEl: 'Ομόνοια και ΑΠΟΕΛ ετοιμάζονται για το ντέρμπι',
          narrativeEn: 'Sports sections cover the upcoming football derby.',
          narrativeTr: 'Spor sayfaları yaklaşan futbol derbisini ele alıyor.',
          narrativeEl: 'Τα αθλητικά καλύπτουν το επερχόμενο ποδοσφαιρικό ντέρμπι.',
          publishDate: DateTime(2026, 10, 22, 10, 30),
          topic: 'sports',
          sources: [
            OverviewStorySource(
              feedId: 'philenews',
              feedTitle: 'Philenews',
              feedLanguage: 'el',
              article: FeedItem(
                'Ντέρμπι αιωνίων στη Λευκωσία',
                DateTime(2026, 10, 22, 10, 30),
                'Sports summary',
                '<p>Sports detail</p>',
                null,
                'https://philenews.com/sports/derby',
                topic: 'sports',
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

    // Podcast title & subtitle and Top Stories banner
    expect(
      find.textContaining('Cyprus Bicommunal News - '),
      findsOneWidget,
    );
    expect(
      find.text('5 minute top news update every morning, mid-day and evening'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Top stories across Turkish, Greek, and English newspapers in Cyprus, summarized by AI.',
      ),
      findsOneWidget,
    );

    // Default language is 'en', so story is auto-translated to English
    expect(find.text('New Crossing Point Discussions Advance'), findsOneWidget);
    expect(find.text('English'), findsWidgets);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Yenidüzen'), findsWidgets);
    expect(find.text('Diyalog'), findsWidgets);
    expect(find.text('Philenews'), findsWidgets);

    // Show Original: story has 2 TR sources and 1 EL source, so majority language is TR
    Constants.setOverviewTranslateLanguage(null);
    await tester.pump();
    expect(find.text('Yeni Geçiş Noktası Görüşmeleri İlerliyor'), findsOneWidget);

    // Switch to Greek and verify Greek title display
    Constants.setOverviewTranslateLanguage('el');
    await tester.pump();
    expect(
      find.text('Προχωρούν οι συζητήσεις για νέο σημείο διέλευσης'),
      findsOneWidget,
    );

    // Tapping the story title itself should NOT navigate anywhere
    await tester.ensureVisible(
      find.text('Προχωρούν οι συζητήσεις για νέο σημείο διέλευσης'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Προχωρούν οι συζητήσεις για νέο σημείο διέλευσης'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OverviewStoryView), findsNothing);
    expect(find.byType(FeedItemView), findsNothing);

    // Show Original and test Topic Filtering before tapping newspaper logo
    Constants.setOverviewTranslateLanguage(null);
    await tester.pump();
    expect(find.text('Yeni Geçiş Noktası Görüşmeleri İlerliyor'), findsOneWidget);

    // Filter by Sports topic
    Constants.setSelectedTopic('sports');
    await tester.pump();
    expect(find.text('Yeni Geçiş Noktası Görüşmeleri İlerliyor'), findsNothing);
    expect(find.text('Ομόνοια και ΑΠΟΕΛ ετοιμάζονται για το ντέρμπι'), findsOneWidget);

    // Reset topic to All
    Constants.setSelectedTopic('all');
    await tester.pump();
    expect(find.text('Yeni Geçiş Noktası Görüşmeleri İlerliyor'), findsOneWidget);

    await tester.ensureVisible(find.text('Yenidüzen').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yenidüzen').first);
    await tester.pumpAndSettle();

    expect(find.byType(FeedItemView), findsOneWidget);
    expect(find.text('Geçiş kapılarında yeni adım'), findsOneWidget);
  });

  testWidgets(
      'FeedItemView renders TranslateIconButton in AppBar, ShareIconButton at bottom with author before newspaper name, and hiding newspapers filters them out',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.initLanguage();
    await Constants.setLanguage('en');
    await Constants.setSourceLanguage('all');

    expect(Constants.targetTranslationLanguagesFor('tr'), ['el', 'en']);
    expect(Constants.targetTranslationLanguagesFor('el'), ['tr', 'en']);
    expect(Constants.targetTranslationLanguagesFor('en'), ['el', 'tr']);

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
      author: 'Serhat İncirli',
      isColumnist: true,
    )..feed = trFeed;

    await tester.pumpWidget(
      MaterialApp(
        home: FeedItemView(item: trItem),
      ),
    );

    expect(find.byType(TranslateIconButton), findsOneWidget);
    expect(find.byType(AppLanguageButton), findsOneWidget);
    expect(find.byType(ShareIconButton), findsOneWidget);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.textContaining('Serhat İncirli • Yenidüzen'), findsOneWidget);
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
