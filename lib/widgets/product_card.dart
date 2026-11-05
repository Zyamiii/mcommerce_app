import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import 'common_widgets.dart';
import 'motion.dart';

/// Reusable product tile: image, name and price (HOA03, Step 3).
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;

  const ProductCard({super.key, required this.product, required this.onTap, this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      label: product.productName,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-${product.id}',
                    child: ProductImage(product.imageUrl, radius: BorderRadius.zero),
                  ),
                  if (!product.inStock)
                    Container(
                      color: Palette.ink.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: const Text('OUT OF STOCK',
                          style: TextStyle(color: Palette.onInk, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    ),
                  if (product.inStock && onQuickAdd != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Pressable(
                        onTap: onQuickAdd,
                        pressedScale: 0.85,
                        label: 'Quick add ${product.productName}',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.add_rounded, color: Palette.ink),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(product.categoryName, style: const TextStyle(fontSize: 13, color: Palette.muted)),
                  const SizedBox(height: 6),
                  Text(money(product.price),
                      style: const TextStyle(color: Palette.oliveDeep, fontWeight: FontWeight.w700, fontSize: 17)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
