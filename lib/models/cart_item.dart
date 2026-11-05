import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: users/{uid}/cart/{productId}
class CartItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory CartItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CartItem(
      productId: doc.id,
      name: d['name'] ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      imageUrl: d['imageUrl'] ?? '',
      quantity: (d['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
      };
}
