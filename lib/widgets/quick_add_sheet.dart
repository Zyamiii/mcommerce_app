import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/session_provider.dart';
import '../services/cart_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import 'common_widgets.dart';
import 'motion.dart';

/// Quantity control shared by the details page and the quick-add sheet.
class QtyStepper extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const QtyStepper({super.key, required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: Palette.cream, borderRadius: BorderRadius.circular(18)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Decrease quantity',
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 26,
          child: PopSwitcher(
            child: Text('$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ),
        ),
        IconButton(
          tooltip: 'Increase quantity',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ]),
    );
  }
}

/// Slides up from the shop so a product can be added without leaving the page.
Future<void> showQuickAddSheet(BuildContext context, Product product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _QuickAddSheet(product: product),
  );
}

class _QuickAddSheet extends StatefulWidget {
  final Product product;
  const _QuickAddSheet({required this.product});

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  int _qty = 1;
  bool _busy = false;

  Future<void> _add(int quantity) async {
    final session = context.read<Session>();
    setState(() => _busy = true);
    try {
      await context.read<CartService>().addToCart(session.uid, widget.product, quantity: quantity);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final inCart = context.select<Session, int>((s) => s.quantityInCart(p.id));
    final maxAddable = (p.stock - inCart).clamp(0, p.stock);
    final qty = _qty.clamp(1, maxAddable < 1 ? 1 : maxAddable);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Reveal(
              child: Row(children: [
                ProductImage(p.imageUrl, size: 84, radius: BorderRadius.circular(20)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(money(p.price),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Palette.oliveDeep)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Reveal(
              delay: Motion.stagger(1),
              child: Row(children: [
                const Expanded(child: Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                QtyStepper(value: qty, max: maxAddable, onChanged: (v) => setState(() => _qty = v)),
              ]),
            ),
            const SizedBox(height: 20),
            Reveal(
              delay: Motion.stagger(2),
              child: FilledButton(
                onPressed: (_busy || maxAddable == 0) ? null : () => _add(qty),
                child: _busy
                    ? const ButtonSpinner()
                    : Text(maxAddable == 0 ? 'Max in cart' : 'Add to cart • ${money(p.price * qty)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
