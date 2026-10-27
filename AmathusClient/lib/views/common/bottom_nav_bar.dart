import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/columnists_view.dart';
import 'package:amathus/views/overview_view.dart';
import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNavigationBar({super.key, required this.selectedIndex});

  void _onTapTab(BuildContext context, int targetTab, int activeTab) {
    final isOnColumnsView = selectedIndex == 2;
    if (targetTab == 0) {
      Constants.newsViewModeNotifier.value = 'top';
      if (isOnColumnsView) {
        _replaceWith(context, const OverviewView());
      }
    } else if (targetTab == 1) {
      Constants.newsViewModeNotifier.value = 'latest';
      if (isOnColumnsView) {
        _replaceWith(context, const OverviewView());
      }
    } else if (targetTab == 2) {
      if (!isOnColumnsView) {
        _replaceWith(context, const ColumnistsView());
      }
    }
  }

  void _replaceWith(BuildContext context, Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Constants.languageNotifier,
        Constants.newsViewModeNotifier,
      ]),
      builder: (context, _) {
        final int activeTab;
        if (selectedIndex == 2) {
          activeTab = 2;
        } else {
          activeTab =
              Constants.newsViewModeNotifier.value == 'latest' ? 1 : 0;
        }

        return Material(
          color: const Color(0xFFF8FAFC),
          child: SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BottomNavTabButton(
                          icon: Icons.auto_awesome_outlined,
                          activeIcon: Icons.auto_awesome_rounded,
                          label: Constants.OVERVIEW,
                          selected: activeTab == 0,
                          onTap: () => _onTapTab(context, 0, activeTab),
                        ),
                      ),
                      Expanded(
                        child: _BottomNavTabButton(
                          icon: Icons.schedule_outlined,
                          activeIcon: Icons.schedule_rounded,
                          label: Constants.RECENT_NEWS,
                          selected: activeTab == 1,
                          onTap: () => _onTapTab(context, 1, activeTab),
                        ),
                      ),
                      Expanded(
                        child: _BottomNavTabButton(
                          icon: Icons.edit_note_outlined,
                          activeIcon: Icons.edit_note_rounded,
                          label: Constants.COLUMNISTS,
                          selected: activeTab == 2,
                          onTap: () => _onTapTab(context, 2, activeTab),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomNavTabButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavTabButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeNavy = Color(0xFF0F2942);
    const inactiveSlate = Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? activeNavy.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                size: 20,
                color: selected ? activeNavy : inactiveSlate,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? activeNavy : inactiveSlate,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
