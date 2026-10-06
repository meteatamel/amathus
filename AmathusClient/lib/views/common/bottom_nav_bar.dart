import 'package:amathus/views/feeditems_recent_view.dart';
import 'package:amathus/views/feeds_view.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;

class AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNavigationBar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF0F2942).withValues(alpha: 0.12),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == selectedIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => FeedItemsRecentView(),
                  transitionDuration: const Duration(milliseconds: 180),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const FeedsView(),
                  transitionDuration: const Duration(milliseconds: 180),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              );
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF0F2942),
            ),
            label: Constants.RECENT_NEWS,
          ),
          NavigationDestination(
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(
              Icons.newspaper_rounded,
              color: Color(0xFF0F2942),
            ),
            label: Constants.NEWSPAPERS,
          ),
        ],
      ),
    );
  }
}
