import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/columnists_view.dart';
import 'package:amathus/views/overview_view.dart';
import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNavigationBar({super.key, required this.selectedIndex});

  void _navigateTo(BuildContext context, int index, int currentIndex) {
    if (index == currentIndex) return;
    final Widget destination =
        index == 0 ? const OverviewView() : const ColumnistsView();
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
    final normalizedIndex = selectedIndex <= 0 ? 0 : 1;
    return ValueListenableBuilder<String>(
      valueListenable: Constants.languageNotifier,
      builder: (context, _, __) {
        return Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
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
                          icon: Icons.newspaper_outlined,
                          activeIcon: Icons.newspaper_rounded,
                          label: Constants.NEWS,
                          selected: normalizedIndex == 0,
                          onTap: () =>
                              _navigateTo(context, 0, normalizedIndex),
                        ),
                      ),
                      Expanded(
                        child: _BottomNavTabButton(
                          icon: Icons.edit_note_outlined,
                          activeIcon: Icons.edit_note_rounded,
                          label: Constants.COLUMNISTS,
                          selected: normalizedIndex == 1,
                          onTap: () =>
                              _navigateTo(context, 1, normalizedIndex),
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
    const inactiveSlate = Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? activeNavy.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 20,
                  color: selected ? activeNavy : inactiveSlate,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? activeNavy : inactiveSlate,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
