import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}

class OrderService {
  static const double shippingFee = 50;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');

  /// Places an order atomically. In one transaction it:
  ///  1. re-reads every product (current price, stock, active flag),
  ///  2. fails if anything is unavailable or short on stock,
  ///  3. decrements stock, writes the order, and empties the cart.
  /// Either all of that happens, or none of it does.
  Future<String> placeOrder({
    required AppUser user,
    required List<CartItem> cart,
    required String phone,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    if (cart.isEmpty) throw OrderException('Your cart is empty.');
    final orderRef = _orders.doc();
    final cartRef = _db.collection('users').doc(user.uid).collection('cart');

    await _db.runTransaction((tx) async {
      final refs = [for (final c in cart) _products.doc(c.productId)];
      final snaps = [for (final r in refs) await tx.get(r)];

      final items = <OrderItem>[];
      for (var i = 0; i < cart.length; i++) {
        final c = cart[i];
        final d = snaps[i].data();
        if (!snaps[i].exists || d == null || d['isActive'] != true) {
          throw OrderException('"${c.name}" is no longer available.');
        }
        final stock = (d['stock'] as num).toInt();
        if (stock < c.quantity) {
          throw OrderException('Only $stock left of "${c.name}". Please update your cart.');
        }
        items.add(OrderItem(
          productId: c.productId,
          name: d['productName'] ?? c.name,
          price: (d['price'] as num).toDouble(),
          quantity: c.quantity,
          imageUrl: d['imageUrl'] ?? '',
        ));
      }

      for (var i = 0; i < cart.length; i++) {
        final stock = (snaps[i].data()!['stock'] as num).toInt();
        tx.update(refs[i], {'stock': stock - cart[i].quantity});
      }

      final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
      tx.set(orderRef, {
        'userId': user.uid,
        'customerName': user.name,
        'customerEmail': user.email,
        'phone': phone.trim(),
        'shippingAddress': shippingAddress.trim(),
        'paymentMethod': paymentMethod,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'total': subtotal + shippingFee,
        'status': OrderStatus.pending,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (final c in cart) {
        tx.delete(cartRef.doc(c.productId));
      }
    });
    return orderRef.id;
  }

  Stream<List<AppOrder>> watchUserOrders(String uid) =>
      _orders.where('userId', isEqualTo: uid).snapshots().map(_sorted);

  Stream<AppOrder?> watchOrder(String id) =>
      _orders.doc(id).snapshots().map((d) => d.exists ? AppOrder.fromDoc(d) : null);

  // ---- Admin ----

  Stream<List<AppOrder>> watchAllOrders() => _orders.snapshots().map(_sorted);

  /// Updates status. Cancelling an order returns its items to stock.
  Future<void> updateStatus(String orderId, String status) async {
    final ref = _orders.doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw OrderException('Order not found.');
      final order = AppOrder.fromDoc(snap);
      if (order.status == status) return;
      if (order.status == OrderStatus.cancelled) {
        throw OrderException('Cancelled orders cannot be reopened.');
      }

      if (status == OrderStatus.cancelled) {
        final prodRefs = [for (final i in order.items) _products.doc(i.productId)];
        final prodSnaps = [for (final r in prodRefs) await tx.get(r)];
        for (var i = 0; i < order.items.length; i++) {
          if (prodSnaps[i].exists) {
            tx.update(prodRefs[i], {'stock': FieldValue.increment(order.items[i].quantity)});
          }
        }
      }
      tx.update(ref, {'status': status, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  List<AppOrder> _sorted(QuerySnapshot<Map<String, dynamic>> s) {
    final list = s.docs.map(AppOrder.fromDoc).toList();
    list.sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));
    return list;
  }
}
