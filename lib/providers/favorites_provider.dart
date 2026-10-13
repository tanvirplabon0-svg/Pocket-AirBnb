import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/firestore_service.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(<String>{}) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _load(user.uid);
      } else {
        if (mounted) state = {};
      }
    });
  }

  StreamSubscription<User?>? _authSub;

  Future<void> _load(String uid) async {
    final ids = await FirestoreService.instance.getFavorites(uid);
    if (mounted) state = ids;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  bool isFavorite(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    final updated = state.contains(id)
        ? ({...state}..remove(id))
        : {...state, id};
    state = updated;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService.instance.saveFavorites(uid, updated);
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);
