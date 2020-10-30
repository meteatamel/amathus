import 'package:amathus/views/contact_view.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/feeditems_recent_view.dart';
import 'package:amathus/views/feeds_view.dart';
import 'package:amathus/views/settings_view.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
              leading: Icon(Icons.dynamic_feed),
              title: Text(Constants.ALL_NEWS, style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => FeedsView()))),
          ListTile(
              leading: Icon(Icons.fiber_new),
              title:
                  Text(Constants.RECENT_NEWS, style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) =>
                          FeedItemsRecentView()))),
          ListTile(
            leading: Icon(Icons.email),
            title: Text(Constants.CONTACT, style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => ContactView()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text(Constants.SETTINGS, style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => SettingsView()));
            },
          ),
        ],
      ),
    );
  }
}
