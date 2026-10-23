import 'package:flutter/foundation.dart';

class PwaInstallBridge {
  static void listenChanges(VoidCallback onChanged) {}

  static bool isStandalone() => true;

  static bool hasDeferredPrompt() => false;

  static String getPlatformHint() => 'native';

  static Future<String> triggerInstallPrompt() async => 'unavailable';
}
