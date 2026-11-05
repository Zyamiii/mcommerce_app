import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../providers/session_provider.dart';
import '../widgets/common_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback onBrowse;
  const CartScreen({super.key, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final cart = session.cart;
    final carts = context.read<CartService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Browse the shop and add something you like.',
              action: FilledButton(onPressed: onBrowse, child: const Text('Start shopping')),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = cart[i];
                return Dismissible(
                  key: ValueKey(item.productId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => carts.remove(session.uid, item.productId),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        ProductImage(item.imageUrl, size: 72),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(money(item.price), style: TextStyle(color: Colors.grey.shade700)),
                              Text('Subtotal: ${money(item.lineTotal)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Column(children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => carts.setQuantity(session.uid, item.productId, item.quantity + 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => carts.setQuantity(session.uid, item.productId, item.quantity - 1),
                            icon: Icon(item.quantity == 1 ? Icons.delete_outline : Icons.remove_circle_outline),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _row('Subtotal (${session.cartCount} items)', money(session.cartSubtotal)),
                  _row('Shipping', money(OrderService.shippingFee)),
                  const Divider(),
                  _row('Total', money(session.cartSubtotal + OrderService.shippingFee), bold: true),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      ),
                      child: const Text('Proceed to checkout'),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Text(label, style: style), const Spacer(), Text(value, style: style)]),
    );
  }
}
