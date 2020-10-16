import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

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
              title: Text(Constants.HOME_PAGE, style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pushNamed(context, FeedsView.routeName)
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