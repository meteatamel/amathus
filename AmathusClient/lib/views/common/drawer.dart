import 'package:amathus/views/columnists_view.dart';
import 'package:amathus/views/common/pwa_install.dart';
import 'package:amathus/views/contact_view.dart';
import 'package:flutter/material.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/overview_view.dart';
import 'package:amathus/views/settings_view.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2942), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.5),
                    child: Transform.scale(
                      scale: 1.12,
                      child: Image.asset(
                        'assets/launcher/icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  Constants.APP_NAME,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Constants.APP_SUBTITLE,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildDrawerItem(
                  context,
                  emoji: '📰',
                  title: Constants.NEWS,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OverviewView(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  emoji: '✍️',
                  title: Constants.COLUMNISTS,
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ColumnistsView(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(
                  context,
                  emoji: '⚙️',
                  title: Constants.SETTINGS,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsView()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  emoji: '✉️',
                  title: Constants.CONTACT,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactView()),
                    );
                  },
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    PwaInstallController.instance,
                    Constants.languageNotifier,
                  ]),
                  builder: (context, _) {
                    if (!PwaInstallController.instance.canShowInstallOption) {
                      return const SizedBox.shrink();
                    }
                    return _buildDrawerItem(
                      context,
                      emoji: '📲',
                      title: Constants.INSTALL_APP_TITLE,
                      onTap: () {
                        final navContext = Navigator.of(context).context;
                        Navigator.pop(context);
                        PwaInstallController.instance.triggerInstall(navContext);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required String emoji,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Text(
        emoji,
        style: const TextStyle(fontSize: 20, height: 1.0),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
      onTap: onTap,
    );
  }
}
