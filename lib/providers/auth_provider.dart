import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/services/firestore_service.dart';

/// Thrown by [AuthNotifier] on login/signup failures; screens show [message].
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.name,
    this.email,
    this.phone,
  });

  final bool isLoggedIn;
  final String? name;
  final String? email;
  final String? phone;

  AuthState copyWith({
    bool? isLoggedIn,
    String? name,
    String? email,
    String? phone,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    // Restores a persisted Firebase session on cold start, and keeps state
    // in sync with sign-in/sign-out from anywhere in the app.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        state = const AuthState();
      } else {
        state = AuthState(
          isLoggedIn: true,
          name: user.displayName,
          email: user.email,
          phone: user.phoneNumber,
        );
      }
    });
  }

  StreamSubscription<User?>? _authSub;

  /// Sign in with email & password.
  /// Throws [AuthException] with a user-friendly message on failure.
  Future<void> login({required String email, required String password}) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      state = AuthState(
        isLoggedIn: true,
        name: user.displayName,
        email: user.email,
        phone: user.phoneNumber,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Create an account, set the display name, then sign in.
  /// Throws [AuthException] with a user-friendly message on failure.
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      final uid = credential.user!.uid;

      await FirestoreService.instance.saveUser(uid, {
        'name': name,
        'email': email,
        'phone': phone,
        'language': 'English (Bangladesh)',
        'currency': 'BDT (৳)',
        'notificationsEnabled': true,
        'favoriteIds': <String>[],
      });
      await FirestoreService.instance.saveNotification(uid, {
        'type': 'system',
        'title': 'Welcome to PocketAirBnB! 🎉',
        'body':
            'Discover the best hotels and stays across Bangladesh. Start exploring now.',
        'isRead': false,
        'actionLabel': 'Explore',
        'actionRoute': '/listings',
      });

      state = AuthState(
        isLoggedIn: true,
        name: name,
        email: email,
        phone: phone,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Sign in with Google. Throws [AuthException] on failure,
  /// returns silently if the user cancels the picker.
  Future<void> signInWithGoogle() async {
    try {
      dev.log('[GoogleSignIn] Starting sign-in flow...', name: 'AuthNotifier');
      // serverClientId (web client ID) is required to get an idToken on
      // Android; google_sign_in_web instead reads the client ID from the
      // <meta name="google-signin-client_id"> tag, so it must stay null there.
      final googleUser = await GoogleSignIn(
        serverClientId: kIsWeb
            ? null
            : '157323104731-0qmnpqk8e4t0hf5j1j3cb1ij3kpsf374.apps.googleusercontent.com',
      ).signIn();

      if (googleUser == null) {
        dev.log('[GoogleSignIn] User cancelled or picker returned null. '
            'This usually means the SHA-1 fingerprint is not registered in '
            'Firebase Console for this build.', name: 'AuthNotifier');
        return;
      }
      dev.log('[GoogleSignIn] Got user: ${googleUser.email}', name: 'AuthNotifier');

      final googleAuth = await googleUser.authentication;
      dev.log('[GoogleSignIn] idToken null? ${googleAuth.idToken == null}', name: 'AuthNotifier');
      dev.log('[GoogleSignIn] accessToken null? ${googleAuth.accessToken == null}', name: 'AuthNotifier');

      if (googleAuth.idToken == null) {
        throw const AuthException(
          'Google Sign-In did not return an ID token. Check that Google '
          'sign-in is enabled in Firebase Console and the SHA-1 fingerprint '
          'is registered.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = result.user!;
      dev.log('[GoogleSignIn] Firebase sign-in success: ${user.email}', name: 'AuthNotifier');

      if (result.additionalUserInfo?.isNewUser == true) {
        await FirestoreService.instance.saveUser(user.uid, {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': '',
          'language': 'English (Bangladesh)',
          'currency': 'BDT (৳)',
          'notificationsEnabled': true,
          'favoriteIds': <String>[],
        });
        await FirestoreService.instance.saveNotification(user.uid, {
          'type': 'system',
          'title': 'Welcome to PocketAirBnB! 🎉',
          'body':
              'Discover the best hotels and stays across Bangladesh. Start exploring now.',
          'isRead': false,
          'actionLabel': 'Explore',
          'actionRoute': '/listings',
        });
      }

      state = AuthState(
        isLoggedIn: true,
        name: user.displayName,
        email: user.email,
        phone: user.phoneNumber,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    final google = GoogleSignIn();
    if (await google.isSignedIn()) await google.signOut();
    state = const AuthState();
  }

  String _messageFor(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' => 'No account found for this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-credential' => 'Invalid email or password.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'email-already-in-use' => 'An account already exists for this email.',
        'weak-password' => 'Password is too weak (min 6 characters).',
        'invalid-email' => 'Please enter a valid email address.',
        _ => e.message ?? 'Authentication failed.',
      };

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
