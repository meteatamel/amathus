import 'package:amathus/views/feeditems_recent_view.dart';
import 'package:amathus/views/feeds_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:page_transition/page_transition.dart';

class AppBottomNavigationBar extends StatelessWidget {

  final int selectedIndex;

  AppBottomNavigationBar({Key key, @required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: Constants.ALL_NEWS,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.new_releases),
          label: Constants.RECENT_NEWS,
        )
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.amber[800],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: FeedsView()));
            break;
          case 1:
            Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: FeedItemsRecentView()));
            break;
        }
      },
    );
  }

}