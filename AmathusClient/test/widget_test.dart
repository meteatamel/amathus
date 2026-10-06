import 'package:amathus/main.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/flag_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Amathus app renders Latest News as first tab, Newspapers as second, source language filter chips with flags, and toggles Turkish/Greek/English',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.setLanguage('tr');
    await Constants.setSourceLanguage('all');

    await tester.pumpWidget(const AmathusApp());

    // Turkish labels: Son Haberler (header + first tab), Gazeteler (second tab)
    expect(find.text('Son Haberler'), findsWidgets);
    expect(find.text('Gazeteler'), findsOneWidget);
    expect(find.text('Tümü'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('Ελληνικά'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.byType(FlagIcon), findsNWidgets(3));

    // Switch to Greek
    await Constants.setLanguage('el');
    await tester.pump();

    expect(find.text('Τελευταία Νέα'), findsWidgets);
    expect(find.text('Εφημερίδες'), findsOneWidget);
    expect(find.text('Όλα'), findsOneWidget);

    // Switch to English
    await Constants.setLanguage('en');
    await tester.pump();

    expect(find.text('Latest News'), findsWidgets);
    expect(find.text('Newspapers'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });
}
