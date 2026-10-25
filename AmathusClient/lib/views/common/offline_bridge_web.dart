// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class OfflineBridge {
  static bool _listening = false;

  static void listenConnectivityChanges(ValueChanged<bool> onOnlineChanged) {
    if (_listening) return;
    _listening = true;
    html.window.addEventListener('online', (_) {
      onOnlineChanged(true);
    });
    html.window.addEventListener('offline', (_) {
      onOnlineChanged(false);
    });
  }

  static bool isBrowserOnline() {
    try {
      return html.window.navigator.onLine != false;
    } catch (_) {
      return true;
    }
  }
}
