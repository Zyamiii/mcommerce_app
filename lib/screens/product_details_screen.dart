import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../providers/session_provider.dart';
import '../widgets/common_widgets.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final Stream<Product?> _product;
  int _qty = 1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _product = context.read<ProductService>().watchProduct(widget.productId);
  }

  Future<void> _addToCart(Product p) async {
    final session = context.read<Session>();
    setState(() => _busy = true);
    try {
      await context.read<CartService>().addToCart(session.uid, p, quantity: _qty);
      if (mounted) {
        showSnack(context, 'Added $_qty × ${p.productName} to cart');
        setState(() => _qty = 1);
      }
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<Session, int>((s) => s.quantityInCart(widget.productId));

    return StreamBuilder<Product?>(
      stream: _product,
      builder: (context, snap) {
        if (snap.hasError) return Scaffold(appBar: AppBar(), body: ErrorView(snap.error!));
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        final p = snap.data;
        if (p == null || !p.isActive) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(icon: Icons.inventory_2_outlined, title: 'Product unavailable'),
          );
        }

        final maxAddable = (p.stock - inCart).clamp(0, p.stock);
        if (_qty > maxAddable && maxAddable > 0) _qty = maxAddable;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(title: Text(p.categoryName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Hero(tag: 'product-${p.id}', child: ProductImage(p.imageUrl, radius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 16),
              Text(p.productName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(money(p.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(p.inStock ? Icons.check_circle : Icons.cancel, size: 18, color: p.inStock ? Colors.green : Colors.red),
                const SizedBox(width: 6),
                Text(p.inStock ? '${p.stock} in stock' : 'Out of stock'),
                if (inCart > 0) ...[
                  const SizedBox(width: 12),
                  Text('• $inCart in your cart', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ]),
              const Divider(height: 32),
              Text('Description', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(p.description.isEmpty ? 'No description.' : p.description,
                  style: const TextStyle(height: 1.5)),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _QtyStepper(
                    value: _qty,
                    max: maxAddable,
                    onChanged: (v) => setState(() => _qty = v),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (_busy || maxAddable == 0) ? null : () => _addToCart(p),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(!p.inStock
                          ? 'Out of stock'
                          : maxAddable == 0
                              ? 'Max in cart'
                              : 'Add to cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  const _QtyStepper({required this.value, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        IconButton(onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        IconButton(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add)),
      ]),
    );
  }
}
