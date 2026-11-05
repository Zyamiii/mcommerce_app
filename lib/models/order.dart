import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatus {
  static const pending = 'pending';
  static const processing = 'processing';
  static const shipped = 'shipped';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static const all = [pending, processing, shipped, delivered, cancelled];
  static const flow = [pending, processing, shipped, delivered];

  static String label(String s) => s[0].toUpperCase() + s.substring(1);
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  double get lineTotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] ?? '',
        name: m['name'] ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        imageUrl: m['imageUrl'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };
}

/// Firestore: orders/{orderId}
class AppOrder {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String phone;
  final String shippingAddress;
  final String paymentMethod;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String status;
  final DateTime? timestamp;
  final DateTime? updatedAt;

  const AppOrder({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.phone,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    this.timestamp,
    this.updatedAt,
  });

  int get itemCount => items.fold(0, (total, i) => total + i.quantity);

  factory AppOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppOrder(
      id: doc.id,
      userId: d['userId'] ?? '',
      customerName: d['customerName'] ?? '',
      customerEmail: d['customerEmail'] ?? '',
      phone: d['phone'] ?? '',
      shippingAddress: d['shippingAddress'] ?? '',
      paymentMethod: d['paymentMethod'] ?? '',
      items: ((d['items'] as List?) ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (d['shippingFee'] as num?)?.toDouble() ?? 0,
      total: (d['total'] as num?)?.toDouble() ?? 0,
      status: d['status'] ?? OrderStatus.pending,
      // Orders placed before the rename used 'createdAt'.
      timestamp: ((d['timestamp'] ?? d['createdAt']) as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
