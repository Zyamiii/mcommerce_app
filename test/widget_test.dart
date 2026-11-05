import 'package:flutter_test/flutter_test.dart';

import 'package:mcommerce_app/models/app_user.dart';
import 'package:mcommerce_app/models/cart_item.dart';
import 'package:mcommerce_app/models/order.dart';
import 'package:mcommerce_app/utils/formatters.dart';

void main() {
  test('cart line total multiplies price by quantity', () {
    const item = CartItem(productId: 'p1', name: 'Mug', price: 125.5, imageUrl: '', quantity: 4);
    expect(item.lineTotal, 502.0);
  });

  test('order item round-trips through a Firestore map', () {
    const item = OrderItem(productId: 'p1', name: 'Mug', price: 99, quantity: 2, imageUrl: 'x');
    final copy = OrderItem.fromMap(item.toMap());
    expect(copy.productId, 'p1');
    expect(copy.lineTotal, 198);
  });

  test('order status flow and labels', () {
    expect(OrderStatus.flow.first, OrderStatus.pending);
    expect(OrderStatus.flow.last, OrderStatus.delivered);
    expect(OrderStatus.flow.contains(OrderStatus.cancelled), isFalse);
    expect(OrderStatus.label('shipped'), 'Shipped');
  });

  test('new accounts default to the user role, not admin', () {
    const user = AppUser(uid: 'u1', name: 'Ana', email: 'ana@email.com');
    expect(user.role, 'user');
    expect(user.isAdmin, isFalse);
  });

  test('formatters', () {
    expect(money(1499), contains('1,499.00'));
    expect(shortId('abcdefghijkl'), 'ABCDEFGH');
    expect(dateTime(null), '—');
  });
}
