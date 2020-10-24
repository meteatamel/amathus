import 'package:amathus/views/feeditems_recent_view.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  timeago.setLocaleMessages('tr', timeago.TrMessages());

  runApp(
      MaterialApp(
        home: FeedItemsRecentView(),
      )
  );
}
