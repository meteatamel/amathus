import 'package:amathus/controllers/notifications_controller.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/views/common/translate_iconbutton.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Constants.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            titleSpacing: 4,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(Constants.NOTIFICATIONS_PAGE_TITLE),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(left: 8, right: 12),
                child: Center(
                  child: AppLanguageButton(lightOnDark: true),
                ),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: const _NotificationsSettingsCard(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationsOptInBanner extends StatelessWidget {
  const NotificationsOptInBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationsController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.enabledNotifier,
        controller.promptDismissedNotifier,
        controller.syncingNotifier,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        if (!controller.shouldShowOptInPrompt) {
          return const SizedBox.shrink();
        }
        final isSyncing = controller.syncingNotifier.value;

        return Material(
          color: const Color(0xFFF0F5FA),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFD8E3EE), width: 1),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: Color(0xFF0F2942),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          Constants.NOTIFICATIONS_PROMPT_TEXT,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F2942),
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2942),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: isSyncing
                            ? null
                            : () async {
                                final ok = await controller.setEnabled(true);
                                if (!ok && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsView(),
                                    ),
                                  );
                                }
                              },
                        child: isSyncing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(Constants.NOTIFICATIONS_ENABLE_BUTTON),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: Constants.NOTIFICATIONS_NOT_NOW,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: isSyncing
                            ? null
                            : () => controller.dismissPrompt(),
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

class _NotificationsSettingsCard extends StatelessWidget {
  const _NotificationsSettingsCard();

  @override
  Widget build(BuildContext context) {
    final controller = NotificationsController.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.enabledNotifier,
        controller.editionsNotifier,
        controller.syncingNotifier,
        controller.statusErrorNotifier,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        final isEnabled = controller.enabledNotifier.value;
        final editions = controller.editionsNotifier.value;
        final isSyncing = controller.syncingNotifier.value;
        final errorMsg = controller.statusErrorNotifier.value;
        final needsIosPwa = controller.needsIosHomeScreenInstall;

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2942).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        isEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_outlined,
                        size: 19,
                        color: const Color(0xFF0F2942),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Constants.NOTIFICATIONS_TITLE,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isSyncing)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                      ),
                    Switch.adaptive(
                      value: isEnabled,
                      activeTrackColor: const Color(0xFF0F2942),
                      onChanged: isSyncing
                          ? null
                          : (value) {
                              controller.setEnabled(value);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  Constants.NOTIFICATIONS_SUBTITLE,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.blueGrey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _EditionChip(
                      label: Constants.NOTIFICATIONS_MORNING,
                      icon: Icons.wb_sunny_outlined,
                      selected: editions.contains('morning'),
                      enabled: !isSyncing,
                      onSelected: () => controller.toggleEdition('morning'),
                    ),
                    _EditionChip(
                      label: Constants.NOTIFICATIONS_MIDDAY,
                      icon: Icons.light_mode_outlined,
                      selected: editions.contains('midday'),
                      enabled: !isSyncing,
                      onSelected: () => controller.toggleEdition('midday'),
                    ),
                    _EditionChip(
                      label: Constants.NOTIFICATIONS_EVENING,
                      icon: Icons.nights_stay_outlined,
                      selected: editions.contains('evening'),
                      enabled: !isSyncing,
                      onSelected: () => controller.toggleEdition('evening'),
                    ),
                  ],
                ),
                if (needsIosPwa) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.ios_share_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            Constants.NOTIFICATIONS_IOS_PWA_HINT,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (errorMsg != null && errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  const _EditionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : const Color(0xFF0F2942),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFF0F2942),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide(
        color: selected ? const Color(0xFF0F2942) : const Color(0xFFCBD5E1),
      ),
      onSelected: enabled ? (_) => onSelected() : null,
    );
  }
}
