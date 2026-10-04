import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Calls the `send-push` Supabase Edge Function to deliver a real push
/// notification via FCM, so it arrives even when the app is fully closed.
///
/// Configured at build/run time via `--dart-define`:
///   --dart-define=SUPABASE_FUNCTION_URL=https://xxxx.supabase.co/functions/v1/send-push
///   --dart-define=SUPABASE_ANON_KEY=your-anon-key
///   --dart-define=PUSH_SHARED_SECRET=same-value-set-as-the-function-secret
/// Never hardcoded in source. If unconfigured, calls are silently skipped —
/// the in-app Inbox (Firestore-backed) still works either way, this only
/// adds the OS-level push on top.
///
/// The function is deployed with --no-verify-jwt (this app has no
/// per-user Supabase session, only Firebase auth), so PUSH_SHARED_SECRET
/// is what keeps the endpoint from being callable by anyone who finds the
/// URL — it must match the function's PUSH_SHARED_SECRET secret exactly.
class PushApiService {
  const PushApiService._();

  static const _functionUrl = String.fromEnvironment('SUPABASE_FUNCTION_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _sharedSecret = String.fromEnvironment('PUSH_SHARED_SECRET');

  static bool get isConfigured =>
      _functionUrl.isNotEmpty && _anonKey.isNotEmpty;

  /// Fire-and-forget: failures are logged but never thrown, since a push
  /// failing shouldn't block the in-app notification that already saved.
  static Future<void> sendPush({
    required String uid,
    required String title,
    required String body,
    String? type,
    String? actionRoute,
  }) async {
    if (!isConfigured) return;

    try {
      await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Authorization': 'Bearer $_anonKey',
              'Content-Type': 'application/json',
              'X-Push-Secret': _sharedSecret,
            },
            body: jsonEncode({
              'uid': uid,
              'title': title,
              'body': body,
              if (type != null) 'type': type,
              if (actionRoute != null) 'actionRoute': actionRoute,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[Push] send-push call failed: $e');
    }
  }
}
