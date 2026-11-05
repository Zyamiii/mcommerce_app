import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: users/{uid}
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role; // 'user' | 'admin'
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.role = 'user',
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      address: d['address'] ?? '',
      role: d['role'] ?? 'user',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'role': role,
      };
}
