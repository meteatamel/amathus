import 'package:amathus/views/feeditems_recent_view.dart';
import 'package:amathus/views/feeds_view.dart';
import 'package:amathus/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  timeago.setLocaleMessages('tr', timeago.TrMessages());

  runApp(
      MaterialApp(
        home: FeedsView(),
        routes:  {
          FeedsView.routeName: (context) => FeedsView(),
          FeedItemsRecentView.routeName: (context) => FeedItemsRecentView(),
          SettingsView.routeName: (context) => SettingsView()
        },
      )
  );
}
