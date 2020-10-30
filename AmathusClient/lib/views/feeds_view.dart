import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feeds_list.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/extensions.dart';

class FeedsView extends StatefulWidget {
  @override
  _FeedsViewState createState() => _FeedsViewState();
}

class _FeedsViewState extends State<FeedsView> {
  FeedsController _controller;

  _FeedsViewState() {
    _controller = FeedsController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(Constants.ALL_NEWS))
            .withBottomAdmobBanner(context),
        drawer: AppDrawer(),
        body: FeedsList(
            loadDataStorageCallback: () => _controller.readAllStored(),
            loadDataServerCallback: () => _controller.readAll()),
        bottomNavigationBar: AppBottomNavigationBar(selectedIndex: 0));
  }
}
