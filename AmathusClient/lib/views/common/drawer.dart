import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

import '../feeditems_recent_view.dart';
import '../feeds_view.dart';
import '../settings_view.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
              leading: Icon(Icons.home),
              title: Text(Constants.ALL_NEWS, style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pushNamed(context, FeedsView.routeName)
          ),
          ListTile(
              leading: Icon(Icons.new_releases_sharp),
              title: Text(Constants.RECENT_NEWS, style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pushNamed(context, FeedItemsRecentView.routeName)
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text(Constants.SETTINGS, style: TextStyle(fontSize: 18)),
            onTap: () => Navigator.pushNamed(context, SettingsView.routeName),
          ),
        ],
      ),
    );
  }
}