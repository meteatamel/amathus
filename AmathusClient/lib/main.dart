import 'package:admob_flutter/admob_flutter.dart';
import 'package:amathus/views/feeds_view.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  timeago.setLocaleMessages('tr', timeago.TrMessages());

  WidgetsFlutterBinding.ensureInitialized();
  Admob.initialize();
  await Admob.requestTrackingAuthorization();

  runApp(
      MaterialApp(
        home: FeedsView(),
      )
  );
}
