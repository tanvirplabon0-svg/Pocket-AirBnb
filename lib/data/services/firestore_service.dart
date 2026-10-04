import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/push_api_service.dart';
import '../models/property.dart';
import '../models/room_availability.dart';
import '../models/room_type.dart';
import '../models/trip_booking.dart';

/// Thrown when a room type has no availability left at booking time.
class SoldOutException implements Exception {
  SoldOutException(this.roomType);
  final RoomType roomType;
  @override
  String toString() => 'SoldOutException(${roomType.name})';
}

/// Central Firestore access layer.
/// All reads and writes go through here — providers never touch _db directly.
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── User profile & settings ──────────────────────────────────

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> saveUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

  // ── Push notification tokens ─────────────────────────────────

  /// Registers this device's FCM token against the user, so a Cloud
  /// Function can push to every device they're signed in on.
  Future<void> addFcmToken(String uid, String token) =>
      _db.collection('users').doc(uid).set(
        {'fcmTokens': FieldValue.arrayUnion([token])},
        SetOptions(merge: true),
      );

  Future<void> removeFcmToken(String uid, String token) =>
      _db.collection('users').doc(uid).set(
        {'fcmTokens': FieldValue.arrayRemove([token])},
        SetOptions(merge: true),
      );

  // ── Favorites ────────────────────────────────────────────────

  Future<Set<String>> getFavorites(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return {};
    final raw = doc.data()?['favoriteIds'];
    return List<String>.from(raw as List? ?? []).toSet();
  }

  Future<void> saveFavorites(String uid, Set<String> ids) =>
      _db.collection('users').doc(uid).set(
            {'favoriteIds': ids.toList()},
            SetOptions(merge: true),
          );

  // ── Bookings ─────────────────────────────────────────────────

  Stream<List<TripBooking>> watchBookings(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('bookings')
      .orderBy('checkIn')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => TripBooking.fromJson({...d.data(), 'id': d.id}))
          .toList())
      .handleError((Object e) {
    // Auth session can briefly lag behind the listener during
    // sign-in/out; swallow permission blips instead of crashing.
  });

  Future<void> saveBooking(String uid, TripBooking booking) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('bookings')
        .doc(booking.id)
        .set(booking.toFirestore());

    // Bookings aren't queryable by hotelId across all users (they live under
    // each guest's own subcollection), so the host dashboard's "N bookings"
    // count is kept as a denormalized counter on the property doc itself,
    // incremented here. No-ops harmlessly if hotelId isn't a host property
    // (e.g. a hotel from the bundled catalog rather than "Become a Host").
    await _db.collection('properties').doc(booking.hotelId).update({
      'bookingCount': FieldValue.increment(1),
    }).catchError((_) {});
  }

  Future<void> updateBookingStatus(
    String uid,
    String bookingId,
    String status,
  ) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});

  Future<void> saveReview(
    String uid,
    String bookingId,
    double rating,
    String review,
  ) =>
      _db.collection('users').doc(uid).collection('bookings').doc(bookingId).update({
        'rating': rating,
        'review': review,
        'status': TripStatus.completed.name,
      });

  // ── Room availability ────────────────────────────────────────
  //
  // One collection, `roomAvailability/{hotelId}`, used for both bundled
  // catalog hotels and host-created properties alike — same doc shape
  // either way, so no catalog-vs-host branching is needed here. Reads are
  // public (see firestore.rules) so the admin dashboard can show live
  // counts without signing in; writes still require a real signed-in user,
  // same as booking itself already requires.

  /// Atomically decrements [roomType]'s available count for [hotelId],
  /// lazily seeding the counter doc from [seed] if this is the first
  /// booking ever made against that hotel. Throws [SoldOutException] if
  /// the count is already 0.
  Future<void> decrementAvailability({
    required String hotelId,
    required RoomType roomType,
    required RoomAvailability seed,
  }) async {
    final ref = _db.collection('roomAvailability').doc(hotelId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final current = snap.exists
          ? roomAvailabilityFromJson(snap.data())
          : Map<RoomType, int>.from(seed);
      final available = current[roomType] ?? 0;
      if (available <= 0) throw SoldOutException(roomType);
      current[roomType] = available - 1;
      txn.set(ref, current.toJson());
    });
  }

  /// Restores one room of [roomType] to [hotelId]'s available count
  /// (e.g. after a cancellation), seeding from [seed] if no counter doc
  /// exists yet.
  Future<void> restoreAvailability({
    required String hotelId,
    required RoomType roomType,
    required RoomAvailability seed,
  }) async {
    final ref = _db.collection('roomAvailability').doc(hotelId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final current = snap.exists
          ? roomAvailabilityFromJson(snap.data())
          : Map<RoomType, int>.from(seed);
      current[roomType] = (current[roomType] ?? 0) + 1;
      txn.set(ref, current.toJson());
    });
  }

  /// One-shot read of a hotel's live room availability, or null if no
  /// counter doc exists yet (i.e. it has never been booked).
  Future<RoomAvailability?> getAvailability(String hotelId) async {
    final doc = await _db.collection('roomAvailability').doc(hotelId).get();
    return doc.exists ? roomAvailabilityFromJson(doc.data()) : null;
  }

  /// Seeds a host property's initial room counts at creation time.
  Future<void> setAvailability(String hotelId, RoomAvailability counts) =>
      _db.collection('roomAvailability').doc(hotelId).set(counts.toJson());

  // ── Notifications ─────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchNotifications(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => {'id': d.id, ...d.data()}).toList())
      .handleError((Object e) {
    // Auth session can briefly lag behind the listener during
    // sign-in/out; swallow permission blips instead of crashing.
  });

  Future<void> saveNotification(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({...data, 'timestamp': FieldValue.serverTimestamp()});

    // Also push via FCM so it reaches the user even if the app is closed —
    // fire-and-forget, never blocks or fails the in-app save above.
    unawaited(PushApiService.sendPush(
      uid: uid,
      title: data['title'] as String? ?? 'PocketAirBnB',
      body: data['body'] as String? ?? '',
      type: data['type'] as String?,
      actionRoute: data['actionRoute'] as String?,
    ));
  }

  Future<void> markNotificationRead(String uid, String msgId) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .doc(msgId)
      .update({'isRead': true});

  Future<void> deleteNotification(String uid, String msgId) => _db
      .collection('users')
      .doc(uid)
      .collection('notifications')
      .doc(msgId)
      .delete();

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Chat history ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchChatMessages(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('chatMessages')
      .orderBy('timestamp')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => {'id': d.id, ...d.data()}).toList())
      .handleError((Object e) {
    // Auth session can briefly lag behind the listener during
    // sign-in/out; swallow permission blips instead of crashing.
  });

  Future<void> saveChatMessage(String uid, Map<String, dynamic> data) => _db
      .collection('users')
      .doc(uid)
      .collection('chatMessages')
      .add({...data, 'timestamp': FieldValue.serverTimestamp()});

  /// Deletes every saved chat message for [uid] — used by the chat
  /// screen's refresh button to start a clean conversation.
  Future<void> clearChatMessages(String uid) async {
    final snap =
        await _db.collection('users').doc(uid).collection('chatMessages').get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Host Properties ─────────────────────────────────────────────

  /// Live stream of the properties listed by [hostUid], newest first.
  Stream<List<Property>> watchHostProperties(String hostUid) => _db
      .collection('properties')
      .where('hostUid', isEqualTo: hostUid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Property.fromFirestore(d.data(), d.id)).toList())
      .handleError((Object e) {
    // Auth session can briefly lag behind the listener during
    // sign-in/out; swallow permission blips instead of crashing.
  });

  Future<String> createProperty(Property property) async {
    final ref = await _db.collection('properties').add(property.toFirestore());
    return ref.id;
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) =>
      _db.collection('properties').doc(id).update(data);

  Future<void> deleteProperty(String id) =>
      _db.collection('properties').doc(id).delete();

  Future<void> updateBlockedDates(String id, List<String> blockedDates) =>
      _db.collection('properties').doc(id).update({
        'blockedDates': blockedDates,
      });

  /// One-shot fetch of every active, host-listed property — used to merge
  /// host listings into the guest-facing hotel feed.
  Future<List<Property>> getActiveProperties() async {
    final snap = await _db
        .collection('properties')
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs
        .map((d) => Property.fromFirestore(d.data(), d.id))
        .toList();
  }
}
