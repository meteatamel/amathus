import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pwa_install_bridge_stub.dart'
    if (dart.library.html) 'pwa_install_bridge_web.dart';

class PwaInstallController extends ChangeNotifier {
  static final PwaInstallController instance = PwaInstallController._();

  PwaInstallController._() {
    PwaInstallBridge.listenChanges(notifyListeners);
  }

  bool get canShowInstallOption {
    if (!kIsWeb) return false;
    return !PwaInstallBridge.isStandalone();
  }

  bool get hasNativePrompt => PwaInstallBridge.hasDeferredPrompt();

  String get platformHint => PwaInstallBridge.getPlatformHint();

  Future<void> triggerInstall(BuildContext context) async {
    if (PwaInstallBridge.hasDeferredPrompt()) {
      final outcome = await PwaInstallBridge.triggerInstallPrompt();
      notifyListeners();
      if (outcome == 'accepted' || outcome == 'dismissed') {
        return;
      }
    }
    if (context.mounted) {
      await showPwaInstallDialog(context);
    }
  }
}

Future<void> showPwaInstallDialog(BuildContext context) async {
  final isIosOrSafari = PwaInstallController.instance.platformHint == 'ios';
  final steps = isIosOrSafari
      ? <String>[
          Constants.INSTALL_IOS_STEP_1,
          Constants.INSTALL_IOS_STEP_2,
          Constants.INSTALL_IOS_STEP_3,
        ]
      : <String>[
          Constants.INSTALL_BROWSER_STEP_1,
          Constants.INSTALL_BROWSER_STEP_2,
        ];

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Transform.scale(
                          scale: 1.12,
                          child: Image.asset(
                            'assets/launcher/icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.INSTALL_APP_BANNER_TITLE,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2942),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            Constants.INSTALL_APP_BANNER_SUBTITLE,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 14),
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2942),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFBBF24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            steps[i],
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2942),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      Constants.GOT_IT_BUTTON,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PwaInstallBanner extends StatelessWidget {
  const PwaInstallBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PwaInstallController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        Constants.languageNotifier,
        Constants.installBannerDismissedNotifier,
      ]),
      builder: (context, _) {
        if (!controller.canShowInstallOption ||
            Constants.installBannerDismissedNotifier.value) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F9FF),
            border: Border(
              bottom: BorderSide(color: Color(0xFFBAE6FD), width: 1),
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Transform.scale(
                          scale: 1.12,
                          child: Image.asset(
                            'assets/launcher/icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Constants.INSTALL_APP_BANNER_TITLE,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2942),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            Constants.INSTALL_APP_BANNER_SUBTITLE,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2942),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      onPressed: () => controller.triggerInstall(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '📲',
                            style: TextStyle(fontSize: 13, height: 1.0),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            Constants.INSTALL_APP_BUTTON,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: Constants.dismissInstallBanner,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
