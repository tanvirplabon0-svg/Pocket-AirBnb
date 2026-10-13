import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/firestore_service.dart';

enum MessageType { bookingConfirmed, bookingCancelled, reminder, promotion, system }

class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.hotelName,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final MessageType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? hotelName;
  final String? actionLabel;
  final String? actionRoute;

  factory InboxMessage.fromFirestore(Map<String, dynamic> data) {
    final ts = data['timestamp'];
    return InboxMessage(
      id: data['id'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.system,
      ),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: ts is Timestamp
          ? ts.toDate()
          : ts is String
              ? DateTime.tryParse(ts) ?? DateTime.now()
              : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      hotelName: data['hotelName'] as String?,
      actionLabel: data['actionLabel'] as String?,
      actionRoute: data['actionRoute'] as String?,
    );
  }

  InboxMessage copyWith({bool? isRead}) => InboxMessage(
        id: id,
        type: type,
        title: title,
        body: body,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        hotelName: hotelName,
        actionLabel: actionLabel,
        actionRoute: actionRoute,
      );
}

class InboxNotifier extends StateNotifier<List<InboxMessage>> {
  InboxNotifier() : super(const []) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _notifSub?.cancel();
      if (user == null) {
        state = const [];
      } else {
        _uid = user.uid;
        _notifSub = FirestoreService.instance
            .watchNotifications(user.uid)
            .listen((raw) {
          state = raw.map(InboxMessage.fromFirestore).toList();
        });
      }
    });
  }

  String? _uid;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Map<String, dynamic>>>? _notifSub;

  @override
  void dispose() {
    _authSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  void add({
    required MessageType type,
    required String title,
    required String body,
    String? hotelName,
    String? actionLabel,
    String? actionRoute,
  }) {
    if (_uid == null) return;
    FirestoreService.instance.saveNotification(_uid!, {
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': false,
      if (hotelName != null) 'hotelName': hotelName,
      if (actionLabel != null) 'actionLabel': actionLabel,
      if (actionRoute != null) 'actionRoute': actionRoute,
    });
  }

  void markRead(String id) {
    state = state.map((m) => m.id == id ? m.copyWith(isRead: true) : m).toList();
    if (_uid != null) FirestoreService.instance.markNotificationRead(_uid!, id);
  }

  void markAllRead() {
    state = state.map((m) => m.copyWith(isRead: true)).toList();
    if (_uid != null) FirestoreService.instance.markAllNotificationsRead(_uid!);
  }

  void deleteMessage(String id) {
    state = state.where((m) => m.id != id).toList();
    if (_uid != null) FirestoreService.instance.deleteNotification(_uid!, id);
  }
}

final inboxProvider =
    StateNotifierProvider<InboxNotifier, List<InboxMessage>>(
  (ref) => InboxNotifier(),
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).where((m) => !m.isRead).length;
});
