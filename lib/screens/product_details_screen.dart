import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/quick_add_sheet.dart';

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
  bool _added = false;
  Timer? _addedTimer;

  @override
  void initState() {
    super.initState();
    _product = context.read<ProductService>().watchProduct(widget.productId);
  }

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }

  Future<void> _addToCart(Product p) async {
    final session = context.read<Session>();
    setState(() => _busy = true);
    try {
      await context.read<CartService>().addToCart(session.uid, p, quantity: _qty);
      if (mounted) {
        setState(() {
          _qty = 1;
          _added = true;
        });
        _addedTimer?.cancel();
        _addedTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _added = false);
        });
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
        final imageHeight = (MediaQuery.sizeOf(context).width).clamp(240.0, 420.0);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: imageHeight,
                title: Text(p.categoryName),
                shape: const RoundedRectangleBorder(),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                    Hero(
                      tag: 'product-${p.id}',
                      child: ProductImage(p.imageUrl, radius: BorderRadius.zero),
                    ),
                    // Keeps the back arrow and title readable over a bright photo.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 150,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Palette.ink.withValues(alpha: 0.85), Palette.ink.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Reveal(
                      child: Text(p.productName,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.15)),
                    ),
                    const SizedBox(height: 8),
                    Reveal(
                      delay: Motion.stagger(1),
                      child: Text(money(p.price),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Palette.oliveDeep)),
                    ),
                    const SizedBox(height: 14),
                    Reveal(
                      delay: Motion.stagger(2),
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        _Pill(
                          icon: p.inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          text: p.inStock ? '${p.stock} in stock' : 'Out of stock',
                          color: p.inStock ? Palette.oliveDeep : Palette.clay,
                        ),
                        if (inCart > 0)
                          _Pill(icon: Icons.shopping_bag_rounded, text: '$inCart in your cart', color: Palette.ink),
                      ]),
                    ),
                    Reveal(
                      delay: Motion.stagger(3),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SectionTitle('Description'),
                        Text(p.description.isEmpty ? 'No description.' : p.description,
                            style: const TextStyle(height: 1.5, fontSize: 16, color: Palette.muted)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomDock(
            child: Row(
              children: [
                QtyStepper(value: _qty, max: maxAddable, onChanged: (v) => setState(() => _qty = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_busy || maxAddable == 0) ? null : () => _addToCart(p),
                    child: AnimatedSwitcher(
                      duration: Motion.fast,
                      child: _added
                          ? const Row(
                              key: ValueKey('added'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.check_rounded), SizedBox(width: 6), Text('Added')],
                            )
                          : Text(
                              !p.inStock
                                  ? 'Out of stock'
                                  : maxAddable == 0
                                      ? 'Max in cart'
                                      : 'Add to cart',
                              key: const ValueKey('add'),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
