import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: categories/{categoryId}
class Category {
  final String id;
  final String name;

  const Category({required this.id, required this.name});

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Category(id: doc.id, name: d['name'] ?? '');
  }

  Map<String, dynamic> toMap() => {'name': name};
}
