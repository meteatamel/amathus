import 'package:amathus/main.dart';
import 'package:amathus/models/feed.dart';
import 'package:amathus/models/feeditem.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/flag_icon.dart';
import 'package:amathus/views/common/share_iconbutton.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:amathus/views/feeditem_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Amathus app renders Cyprus Bicommunal News in top banner, Latest News as first tab, Newspapers as second, and toggles Turkish/Greek/English',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.initLanguage();
    await Constants.setLanguage('tr');
    await Constants.setSourceLanguage('all');

    await tester.pumpWidget(const AmathusApp());

    // Turkish labels: Cyprus Bicommunal News • Son Haberler (header), Son Haberler (first tab), Gazeteler (second tab)
    expect(find.text('Cyprus Bicommunal News • Son Haberler'), findsOneWidget);
    expect(find.text('Son Haberler'), findsOneWidget);
    expect(find.text('Gazeteler'), findsOneWidget);
    expect(find.text('Kaynaklar:'), findsOneWidget);
    expect(find.text('Tümü'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('Ελληνικά'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byType(FlagIcon), findsNWidgets(3));

    // Switch to Greek
    await Constants.setLanguage('el');
    await tester.pump();

    expect(
      find.text('Cyprus Bicommunal News • Τελευταία Νέα'),
      findsOneWidget,
    );
    expect(find.text('Τελευταία Νέα'), findsOneWidget);
    expect(find.text('Εφημερίδες'), findsOneWidget);
    expect(find.text('Πηγές:'), findsOneWidget);
    expect(find.text('Όλα'), findsOneWidget);

    // Switch to English
    await Constants.setLanguage('en');
    await tester.pump();

    expect(find.text('Cyprus Bicommunal News • Latest News'), findsOneWidget);
    expect(find.text('Latest News'), findsOneWidget);
    expect(find.text('Newspapers'), findsOneWidget);
    expect(find.text('Sources:'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
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

    expect(find.byType(TranslateIconButton), findsWidgets);
    expect(find.byType(ShareIconButton), findsWidgets);
    expect(find.byType(SourceAndTranslationBadges), findsOneWidget);
    expect(find.byType(FlagIcon), findsOneWidget);
  });
}
