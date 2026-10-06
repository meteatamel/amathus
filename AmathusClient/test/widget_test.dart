import 'package:amathus/main.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'Amathus app renders Latest News as first tab, Newspapers as second, and toggles Turkish/English',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Constants.setLanguage('tr');

    await tester.pumpWidget(const AmathusApp());

    // Turkish labels: Son Haberler (header + first tab), Gazeteler (second tab)
    expect(find.text('Son Haberler'), findsWidgets);
    expect(find.text('Gazeteler'), findsOneWidget);

    // Switch to English
    await Constants.setLanguage('en');
    await tester.pump();

    expect(find.text('Latest News'), findsWidgets);
    expect(find.text('Newspapers'), findsOneWidget);
  });
}
