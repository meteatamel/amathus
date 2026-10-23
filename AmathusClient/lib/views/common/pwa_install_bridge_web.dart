// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class PwaInstallBridge {
  static bool _listening = false;

  static void listenChanges(VoidCallback onChanged) {
    if (_listening) return;
    _listening = true;
    html.window.addEventListener('pwa-install-change', (_) {
      onChanged();
    });
  }

  static bool isStandalone() {
    try {
      final val = html.document.documentElement?.dataset['pwaStandalone'];
      if (val != null) {
        return val == 'true';
      }
      return html.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }

  static bool hasDeferredPrompt() {
    try {
      return html.document.documentElement?.dataset['pwaHasPrompt'] == 'true';
    } catch (_) {
      return false;
    }
  }

  static String getPlatformHint() {
    try {
      return html.document.documentElement?.dataset['pwaPlatform'] ?? 'browser';
    } catch (_) {
      return 'browser';
    }
  }

  static Future<String> triggerInstallPrompt() async {
    try {
      final completer = Completer<String>();
      late html.EventListener listener;
      listener = (_) {
        html.window.removeEventListener('amathus-pwa-prompt-done', listener);
        final outcome =
            html.document.documentElement?.dataset['pwaLastOutcome'] ??
                'unavailable';
        if (!completer.isCompleted) {
          completer.complete(outcome);
        }
      };
      html.window.addEventListener('amathus-pwa-prompt-done', listener);
      html.window.dispatchEvent(html.CustomEvent('amathus-trigger-pwa-install'));
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          html.window.removeEventListener('amathus-pwa-prompt-done', listener);
          return 'dismissed';
        },
      );
    } catch (_) {
      return 'unavailable';
    }
  }
}
