import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';
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
      body: AnimatedSwitcher(
        duration: Motion.base,
        child: cart.isEmpty
            ? EmptyState(
                key: const ValueKey('empty'),
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Browse the shop and add something you like.',
                action: FilledButton(onPressed: onBrowse, child: const Text('Start shopping')),
              )
            : ListView.separated(
                key: const ValueKey('items'),
                padding: const EdgeInsets.all(18),
                itemCount: cart.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = cart[i];
                  return Reveal(
                    key: ValueKey('reveal-${item.productId}'),
                    delay: Motion.stagger(i),
                    child: Dismissible(
                      key: ValueKey(item.productId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(color: Palette.clay, borderRadius: BorderRadius.circular(24)),
                        child: const Icon(Icons.delete_outline_rounded, color: Palette.onInk),
                      ),
                      onDismissed: (_) => carts.remove(session.uid, item.productId),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Palette.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Palette.line),
                        ),
                        child: Row(children: [
                          ProductImage(item.imageUrl, size: 84, radius: BorderRadius.circular(18)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(money(item.price), style: const TextStyle(color: Palette.muted)),
                                const SizedBox(height: 2),
                                CountUp(
                                  value: item.lineTotal.toDouble(),
                                  format: money,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Palette.oliveDeep, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          _QtyColumn(
                            quantity: item.quantity,
                            onAdd: () => carts.setQuantity(session.uid, item.productId, item.quantity + 1),
                            onRemove: () => carts.setQuantity(session.uid, item.productId, item.quantity - 1),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: AnimatedSize(
        duration: Motion.base,
        curve: Motion.curve,
        child: cart.isEmpty
            ? const SizedBox(width: double.infinity)
            : BottomDock(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _row('Subtotal (${session.cartCount} ${session.cartCount == 1 ? 'item' : 'items'})', session.cartSubtotal.toDouble()),
                  _row('Shipping', OrderService.shippingFee.toDouble()),
                  const Divider(height: 18),
                  _row('Total', (session.cartSubtotal + OrderService.shippingFee).toDouble(), bold: true),
                  const SizedBox(height: 12),
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

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: bold ? 19 : 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text(label, style: style),
        const Spacer(),
        CountUp(value: value, format: money, style: style),
      ]),
    );
  }
}

class _QtyColumn extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QtyColumn({required this.quantity, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Palette.cream, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        IconButton(
          tooltip: 'Add one',
          visualDensity: VisualDensity.compact,
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
        ),
        PopSwitcher(
          child: Text('$quantity', key: ValueKey(quantity), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        IconButton(
          tooltip: quantity == 1 ? 'Remove' : 'Remove one',
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
          icon: AnimatedSwitcher(
            duration: Motion.fast,
            child: Icon(
              quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
              key: ValueKey(quantity == 1),
              color: quantity == 1 ? Palette.clay : null,
            ),
          ),
        ),
      ]),
    );
  }
}
