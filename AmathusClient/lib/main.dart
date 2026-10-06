import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/feeditems_recent_view.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setLocaleMessages('en', timeago.EnMessages());
  await Constants.initLanguage();

  runApp(const AmathusApp());
}

class AmathusApp extends StatelessWidget {
  const AmathusApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF0F2942);
    const surfaceBg = Color(0xFFF4F6F9);

    return ValueListenableBuilder<String>(
      valueListenable: Constants.languageNotifier,
      builder: (context, lang, _) {
        return MaterialApp(
          key: ValueKey(lang),
          title: Constants.APP_NAME,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryNavy,
              primary: primaryNavy,
              secondary: Colors.amber.shade700,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: surfaceBg,
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: FeedItemsRecentView(),
        );
      },
    );
  }
}
