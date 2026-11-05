import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<AppUser?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  /// Creates a default customer profile only if none exists. A transaction
  /// avoids clobbering a profile written at the same moment by register().
  Future<void> ensureProfile(User user) async {
    final ref = _users.doc(user.uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;
      tx.set(ref, {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': '',
        'address': '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateProfile(
    String uid, {
    required String name,
    required String phone,
    required String address,
  }) =>
      _users.doc(uid).update({
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
      });

  // ---- Admin ----

  Stream<List<AppUser>> watchAllUsers() => _users.snapshots().map((s) {
        final list = s.docs.map(AppUser.fromDoc).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });

  Future<void> setRole(String uid, String role) => _users.doc(uid).update({'role': role});
}
