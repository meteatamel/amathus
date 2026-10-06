import 'package:amathus/controllers/feeds_controller.dart';
import 'package:amathus/views/common/bottom_nav_bar.dart';
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/feeds_list.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class FeedsView extends StatefulWidget {
  const FeedsView({super.key});

  @override
  State<FeedsView> createState() => _FeedsViewState();
}

class _FeedsViewState extends State<FeedsView> {
  final FeedsController _controller = FeedsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(Constants.NEWSPAPERS),
      ),
      drawer: const AppDrawer(),
      body: FeedsList(
        loadDataStorageCallback: () => _controller.readAllStored(),
        loadDataServerCallback: () => _controller.readAll(),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(selectedIndex: 1),
    );
  }
}
