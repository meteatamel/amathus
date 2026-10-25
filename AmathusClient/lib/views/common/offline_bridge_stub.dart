import 'package:flutter/foundation.dart';

class OfflineBridge {
  static void listenConnectivityChanges(ValueChanged<bool> onOnlineChanged) {}

  static bool isBrowserOnline() => true;
}
