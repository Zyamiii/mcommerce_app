import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: products/{productId}
class Product {
  final String id;
  final String productName;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final String categoryName;
  final String imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.productName,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    this.isActive = true,
    this.createdAt,
  });

  bool get inStock => stock > 0;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      // Products saved before the rename used 'name'.
      productName: d['productName'] ?? d['name'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      stock: (d['stock'] as num?)?.toInt() ?? 0,
      categoryId: d['categoryId'] ?? '',
      categoryName: d['categoryName'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'productName': productName,
        'description': description,
        'price': price,
        'stock': stock,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'imageUrl': imageUrl,
        'isActive': isActive,
      };
}
