import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

/// The cart lives in Firestore (users/{uid}/cart) so it survives reinstalling
/// the app and syncs across a customer's devices.
class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cart(String uid) =>
      _db.collection('users').doc(uid).collection('cart');

  Stream<List<CartItem>> watchCart(String uid) =>
      _cart(uid).snapshots().map((s) => s.docs.map(CartItem.fromDoc).toList());

  Future<void> addToCart(String uid, Product p, {int quantity = 1}) async {
    if (p.stock <= 0) throw StateError('${p.productName} is out of stock.');
    final ref = _cart(uid).doc(p.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists ? ((snap.data()!['quantity'] as num?)?.toInt() ?? 0) : 0;
      final next = (current + quantity).clamp(1, p.stock);
      tx.set(ref, {
        'name': p.productName,
        'price': p.price,
        'imageUrl': p.imageUrl,
        'quantity': next,
        'addedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> setQuantity(String uid, String productId, int quantity) {
    if (quantity <= 0) return remove(uid, productId);
    return _cart(uid).doc(productId).update({'quantity': quantity});
  }

  Future<void> remove(String uid, String productId) => _cart(uid).doc(productId).delete();
}
