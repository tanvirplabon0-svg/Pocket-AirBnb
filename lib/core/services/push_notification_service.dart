import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/services/firestore_service.dart';

/// Must be a top-level function — the platform channel calls this in its
/// own isolate when a data/notification message arrives while the app is
/// fully terminated or backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Wires Firebase Cloud Messaging to the signed-in user: requests
/// permission, registers/unregisters this device's token in Firestore so
/// the `sendPushOnNewNotification` Cloud Function can reach it, and logs
/// foreground messages (the in-app Inbox already shows these via its own
/// Firestore listener, so this doesn't duplicate that UI).
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  String? _registeredToken;
  String? _registeredUid;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        await _unregisterCurrentToken();
      } else {
        await _registerToken(user.uid);
      }
    });

    // Token can rotate (e.g. app reinstall, token expiry) — keep it fresh.
    _messaging.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      if (_registeredToken != null) {
        await FirestoreService.instance.removeFcmToken(uid, _registeredToken!);
      }
      _registeredToken = newToken;
      _registeredUid = uid;
      await FirestoreService.instance.addFcmToken(uid, newToken);
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    });
  }

  Future<void> _registerToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    _registeredToken = token;
    _registeredUid = uid;
    try {
      await FirestoreService.instance.addFcmToken(uid, token);
    } catch (_) {
      // Auth token may still be propagating — will retry on next token refresh.
    }
  }

  /// Removes this device's token from the *previously* signed-in user's
  /// doc — must run before [FirebaseAuth.currentUser] goes null, so the
  /// uid is captured from the last successful [_registerToken] call.
  Future<void> _unregisterCurrentToken() async {
    final token = _registeredToken;
    final uid = _registeredUid;
    _registeredToken = null;
    _registeredUid = null;
    if (token == null || uid == null) return;
    try {
      await FirestoreService.instance.removeFcmToken(uid, token);
    } catch (_) {
      // Token removal is best-effort — ignore transient permission errors.
    }
  }
}
