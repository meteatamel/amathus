import 'package:amathus/views/feeds_view.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;


// TODO: Import firebase_admob.dart
import 'package:firebase_admob/firebase_admob.dart';

import 'package:flutter/material.dart';

import 'ad_manager.dart';

Future<void> main() async {
  timeago.setLocaleMessages('tr', timeago.TrMessages());


  runApp(MaterialApp(home: FeedsView()));
}
