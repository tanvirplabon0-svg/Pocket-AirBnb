import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/firestore_service.dart';
import 'auth_provider.dart';

class ProfileState {
  const ProfileState({
    this.name = 'Guest',
    this.email = '',
    this.phone = '',
    this.location = 'Dhaka, Bangladesh',
    this.language = 'English (Bangladesh)',
    this.currency = 'BDT (৳)',
    this.notificationsEnabled = true,
  });

  final String name;
  final String email;
  final String phone;
  final String location;
  final String language;
  final String currency;
  final bool notificationsEnabled;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'BD';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
    String? location,
    String? language,
    String? currency,
    bool? notificationsEnabled,
  }) =>
      ProfileState(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        language: language ?? this.language,
        currency: currency ?? this.currency,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(Ref ref) : super(const ProfileState()) {
    // Seed from the auth session, then overlay any saved profile edits.
    ref.listen<AuthState>(authProvider, (_, auth) => _syncFromAuth(auth),
        fireImmediately: true);
  }

  void _syncFromAuth(AuthState auth) {
    if (!auth.isLoggedIn) {
      state = const ProfileState();
      return;
    }
    state = state.copyWith(
      name: auth.name?.isNotEmpty == true ? auth.name : null,
      email: auth.email,
      phone: auth.phone,
    );
    _load();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    final data = await FirestoreService.instance.getUser(uid);
    if (data == null || !mounted) return;
    state = state.copyWith(
      name: data['name'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      location: data['location'] as String?,
      language: data['language'] as String?,
      currency: data['currency'] as String?,
      notificationsEnabled: data['notificationsEnabled'] as bool?,
    );
  }

  void update(ProfileState updated) {
    state = updated;
    _save();
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsEnabled: !state.notificationsEnabled);
    _save();
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    await FirestoreService.instance.saveUser(uid, {
      'name': state.name,
      'email': state.email,
      'phone': state.phone,
      'location': state.location,
      'language': state.language,
      'currency': state.currency,
      'notificationsEnabled': state.notificationsEnabled,
    });
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);
