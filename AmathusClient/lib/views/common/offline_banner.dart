import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/material.dart';

import 'offline_bridge_stub.dart'
    if (dart.library.html) 'offline_bridge_web.dart';

class ConnectivityController extends ChangeNotifier {
  static final ConnectivityController instance = ConnectivityController._();

  bool _isOffline = !OfflineBridge.isBrowserOnline();
  final Set<VoidCallback> _reconnectListeners = <VoidCallback>{};

  ConnectivityController._() {
    OfflineBridge.listenConnectivityChanges((isOnline) {
      if (isOnline) {
        reportOnline();
      } else {
        reportOffline();
      }
    });
  }

  bool get isOffline => _isOffline;

  void addReconnectListener(VoidCallback callback) {
    _reconnectListeners.add(callback);
  }

  void removeReconnectListener(VoidCallback callback) {
    _reconnectListeners.remove(callback);
  }

  void reportOnline() {
    if (!_isOffline) return;
    _isOffline = false;
    notifyListeners();
    for (final cb in List<VoidCallback>.from(_reconnectListeners)) {
      cb();
    }
  }

  void reportOffline() {
    if (_isOffline) return;
    _isOffline = true;
    notifyListeners();
  }

  @visibleForTesting
  void setOfflineForTesting(bool offline) {
    if (offline) {
      reportOffline();
    } else {
      reportOnline();
    }
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ConnectivityController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        Constants.languageNotifier,
      ]),
      builder: (context, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: !controller.isOffline
              ? const SizedBox.shrink()
              : Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFFCA5A5), width: 1),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 16,
                              color: Color(0xFF991B1B),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                Constants.OFFLINE_BANNER_TEXT,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF991B1B),
                                ),
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
