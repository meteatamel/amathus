import 'dart:async';
import 'dart:convert';
import 'package:amathus/firebase_options.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/pwa_install_bridge_stub.dart'
    if (dart.library.html) 'package:amathus/views/common/pwa_install_bridge_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsController {
  NotificationsController._();

  static final NotificationsController instance = NotificationsController._();

  static const String _enabledPrefKey = 'notifications_enabled_v1';
  static const String _editionsPrefKey = 'notifications_editions_v1';
  static const String _tokenPrefKey = 'notifications_fcm_token_v1';
  static const String _promptDismissedPrefKey =
      'notifications_prompt_dismissed_v1';

  static const List<String> allEditions = ['morning', 'midday', 'evening'];
  static const Set<String> defaultEditions = {'morning', 'evening'};

  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> promptDismissedNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<Set<String>> editionsNotifier =
      ValueNotifier<Set<String>>(Set<String>.from(defaultEditions));
  final ValueNotifier<bool> syncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> statusErrorNotifier =
      ValueNotifier<String?>(null);

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _cachedToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  bool get isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get needsIosHomeScreenInstall =>
      kIsWeb &&
      PwaInstallBridge.getPlatformHint() == 'ios' &&
      !PwaInstallBridge.isStandalone();

  bool get shouldShowOptInPrompt =>
      isSupportedPlatform &&
      !needsIosHomeScreenInstall &&
      !enabledNotifier.value &&
      !promptDismissedNotifier.value;

  Future<void> dismissPrompt() async {
    promptDismissedNotifier.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_promptDismissedPrefKey, true);
    } catch (_) {}
  }

  void attachScaffoldMessenger(GlobalKey<ScaffoldMessengerState> key) {
    _messengerKey = key;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      enabledNotifier.value = prefs.getBool(_enabledPrefKey) ?? false;
      promptDismissedNotifier.value =
          prefs.getBool(_promptDismissedPrefKey) ?? false;
      final savedEditions = prefs.getStringList(_editionsPrefKey);
      if (savedEditions != null && savedEditions.isNotEmpty) {
        final valid = savedEditions
            .map((e) => e.trim().toLowerCase())
            .where((e) => allEditions.contains(e))
            .toSet();
        if (valid.isNotEmpty) {
          editionsNotifier.value = valid;
        }
      }
      _cachedToken = prefs.getString(_tokenPrefKey);
    } catch (e) {
      debugPrint('Could not load notification preferences: $e');
    }

    if (!isSupportedPlatform) {
      return;
    }

    await _ensureFirebaseInitialized();

    Constants.languageNotifier.addListener(_onLanguageChanged);

    if (_firebaseReady) {
      _attachMessagingListeners();
      if (enabledNotifier.value) {
        // Best-effort silent re-sync on launch in case token or language changed.
        unawaited(_syncTopicsWithBackend(silent: true));
      }
    }
  }

  Future<bool> _ensureFirebaseInitialized() async {
    if (_firebaseReady) return true;
    try {
      if (Firebase.apps.isEmpty) {
        final opts = DefaultFirebaseOptions.currentPlatformOrNull;
        if (opts != null) {
          await Firebase.initializeApp(options: opts);
        } else {
          await Firebase.initializeApp();
        }
      }
      _firebaseReady = true;
      return true;
    } catch (e) {
      debugPrint('Firebase initialization skipped/unavailable: $e');
      _firebaseReady = false;
      return false;
    }
  }

  void _attachMessagingListeners() {
    try {
      // ignore: deprecated_member_use
      _tokenRefreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
          _cachedToken = newToken;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_tokenPrefKey, newToken);
          } catch (_) {}
          if (enabledNotifier.value) {
            await _syncTopicsWithBackend(tokenOverride: newToken, silent: true);
          }
        },
      );

      _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ??
            (message.data['title'] as String?) ??
            Constants.APP_NAME;
        final body = message.notification?.body ??
            (message.data['body'] as String?) ??
            '';
        final messenger = _messengerKey?.currentState;
        if (messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Could not attach FCM listeners: $e');
    }
  }

  void _onLanguageChanged() {
    if (enabledNotifier.value && _firebaseReady) {
      unawaited(_syncTopicsWithBackend(silent: true));
    }
  }

  Future<bool> setEnabled(bool enable) async {
    statusErrorNotifier.value = null;

    if (!enable) {
      syncingNotifier.value = true;
      try {
        await _unsubscribeFromBackend();
        enabledNotifier.value = false;
        await _persistPreferences();
        return true;
      } finally {
        syncingNotifier.value = false;
      }
    }

    if (needsIosHomeScreenInstall) {
      statusErrorNotifier.value = Constants.NOTIFICATIONS_IOS_PWA_HINT;
      return false;
    }

    if (!isSupportedPlatform) {
      statusErrorNotifier.value = Constants.NOTIFICATIONS_UNSUPPORTED;
      return false;
    }

    syncingNotifier.value = true;
    try {
      final ready = await _ensureFirebaseInitialized();
      if (!ready) {
        statusErrorNotifier.value = Constants.NOTIFICATIONS_UNSUPPORTED;
        return false;
      }
      _attachMessagingListeners();

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        statusErrorNotifier.value = Constants.NOTIFICATIONS_PERMISSION_DENIED;
        enabledNotifier.value = false;
        await _persistPreferences();
        return false;
      }

      if (editionsNotifier.value.isEmpty) {
        editionsNotifier.value = Set<String>.from(defaultEditions);
      }

      final ok = await _syncTopicsWithBackend(silent: false);
      if (ok) {
        enabledNotifier.value = true;
        await _persistPreferences();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to enable notifications: $e');
      statusErrorNotifier.value = Constants.NOTIFICATIONS_SYNC_ERROR;
      return false;
    } finally {
      syncingNotifier.value = false;
    }
  }

  Future<void> toggleEdition(String edition) async {
    if (!allEditions.contains(edition)) return;
    statusErrorNotifier.value = null;

    final updated = Set<String>.from(editionsNotifier.value);
    if (updated.contains(edition)) {
      updated.remove(edition);
    } else {
      updated.add(edition);
    }

    if (updated.isEmpty) {
      editionsNotifier.value = Set<String>.from(defaultEditions);
      await setEnabled(false);
      return;
    }

    editionsNotifier.value = updated;
    await _persistPreferences();

    if (enabledNotifier.value) {
      syncingNotifier.value = true;
      try {
        await _syncTopicsWithBackend(silent: false);
      } finally {
        syncingNotifier.value = false;
      }
    }
  }

  Future<String?> _fetchToken() async {
    try {
      // ignore: deprecated_member_use
      final token = kIsWeb
          // ignore: deprecated_member_use
          ? await FirebaseMessaging.instance.getToken(vapidKey: kWebPushVapidKey)
          // ignore: deprecated_member_use
          : await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenPrefKey, token);
        } catch (_) {}
      }
      return token ?? _cachedToken;
    } catch (e) {
      debugPrint('Could not fetch FCM token: $e');
      return _cachedToken;
    }
  }

  Future<bool> _syncTopicsWithBackend({
    String? tokenOverride,
    required bool silent,
  }) async {
    final token = tokenOverride ?? await _fetchToken();
    if (token == null || token.isEmpty) {
      if (!silent) {
        statusErrorNotifier.value = Constants.NOTIFICATIONS_SYNC_ERROR;
      }
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse(Constants.URL_NOTIFICATIONS_PREFERENCES),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'Token': token,
              'Language': Constants.currentLanguage,
              'Editions': editionsNotifier.value.toList(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (!silent) {
          statusErrorNotifier.value = null;
        }
        return true;
      }

      debugPrint(
        'Notifications preferences API returned HTTP ${response.statusCode}: ${response.body}',
      );
      if (!silent) {
        statusErrorNotifier.value = Constants.NOTIFICATIONS_SYNC_ERROR;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to sync notification preferences: $e');
      if (!silent) {
        statusErrorNotifier.value = Constants.NOTIFICATIONS_SYNC_ERROR;
      }
      return false;
    }
  }

  Future<void> _unsubscribeFromBackend() async {
    final token = _cachedToken ?? (_firebaseReady ? await _fetchToken() : null);
    if (token == null || token.isEmpty) return;

    try {
      await http
          .post(
            Uri.parse(Constants.URL_NOTIFICATIONS_UNSUBSCRIBE),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'Token': token}),
          )
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('Failed to unsubscribe notifications on backend: $e');
    }
  }

  Future<void> _persistPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledPrefKey, enabledNotifier.value);
      await prefs.setStringList(
        _editionsPrefKey,
        editionsNotifier.value.toList(),
      );
    } catch (e) {
      debugPrint('Could not save notification preferences: $e');
    }
  }
}
