import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';
import '../widgets/product_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenCart;
  const HomeScreen({super.key, required this.onOpenCart});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Product>> _products;
  late final Stream<List<Category>> _categories;
  String? _categoryId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final svc = context.read<ProductService>();
    _products = svc.watchProducts(activeOnly: true);
    _categories = svc.watchCategories();
  }

  void _open(Product p) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: p.id)),
      );

  @override
  Widget build(BuildContext context) {
    final name = context.select<Session, String>((s) => s.profile?.name ?? '');
    final cartCount = context.select<Session, int>((s) => s.cartCount);
    final firstName = name.split(' ').first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: StreamBuilder<List<Product>>(
          stream: _products,
          builder: (context, snap) {
            final items = (snap.data ?? const <Product>[]).where((p) {
              final catOk = _categoryId == null || p.categoryId == _categoryId;
              final qOk = _query.isEmpty ||
                  p.productName.toLowerCase().contains(_query) ||
                  p.categoryName.toLowerCase().contains(_query);
              return catOk && qOk;
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    firstName: firstName,
                    cartCount: cartCount,
                    onOpenCart: widget.onOpenCart,
                    onSearch: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                SliverToBoxAdapter(child: _categoryRow()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SectionTitle(
                      'Available products',
                      trailing: PopSwitcher(
                        child: Text('${items.length}',
                            key: ValueKey(items.length),
                            style: const TextStyle(color: Palette.muted, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                ..._productSlivers(snap, items),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _productSlivers(AsyncSnapshot<List<Product>> snap, List<Product> items) {
    if (snap.hasError) return [SliverFillRemaining(hasScrollBody: false, child: ErrorView(snap.error!))];
    if (!snap.hasData) {
      return const [SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))];
    }
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: 'No products found',
            message: 'Try another search or category.',
          ),
        ),
      ];
    }
    final filter = '$_categoryId|$_query';
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => Reveal(
            // A new filter replays the entrance.
            key: ValueKey('$filter-${items[i].id}'),
            delay: Motion.stagger(i),
            child: ProductCard(
              product: items[i],
              onTap: () => _open(items[i]),
              onQuickAdd: () => showQuickAddSheet(context, items[i]),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _categoryRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: SectionTitle('Shop by category')),
        SizedBox(
          height: 116,
          child: StreamBuilder<List<Category>>(
            stream: _categories,
            builder: (context, snap) {
              final cats = snap.data ?? const <Category>[];
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  _CategoryTile(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    selected: _categoryId == null,
                    onTap: () => setState(() => _categoryId = null),
                  ),
                  for (final c in cats)
                    _CategoryTile(
                      label: c.name,
                      icon: _iconFor(c.name),
                      selected: _categoryId == c.id,
                      onTap: () => setState(() => _categoryId = c.id),
                    ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    bool has(List<String> words) => words.any(n.contains);
    if (has(['tech', 'gadget', 'electronic', 'phone'])) return Icons.devices_outlined;
    if (has(['fashion', 'cloth', 'apparel', 'wear'])) return Icons.checkroom_outlined;
    if (has(['food', 'grocer', 'drink'])) return Icons.restaurant_outlined;
    if (has(['home', 'furniture', 'living'])) return Icons.chair_outlined;
    if (has(['beauty', 'health', 'care'])) return Icons.spa_outlined;
    if (has(['book', 'school', 'office'])) return Icons.menu_book_outlined;
    if (has(['sport', 'fitness'])) return Icons.sports_basketball_outlined;
    if (has(['toy', 'game'])) return Icons.toys_outlined;
    return Icons.category_outlined;
  }
}

/// The dark top of the shop, with the greeting, cart shortcut and search.
class _Header extends StatelessWidget {
  final String firstName;
  final int cartCount;
  final VoidCallback onOpenCart;
  final ValueChanged<String> onSearch;

  const _Header({required this.firstName, required this.cartCount, required this.onOpenCart, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Reveal(
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.shopping_bag_rounded, color: Palette.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('ShopEase',
                        style: TextStyle(color: Palette.onInk, fontSize: 24, fontWeight: FontWeight.w700, height: 1.1)),
                    if (firstName.isNotEmpty)
                      Text('Hi, $firstName!', style: const TextStyle(color: Palette.onInkMuted, fontSize: 14)),
                  ]),
                ),
                Pressable(
                  onTap: onOpenCart,
                  pressedScale: 0.9,
                  label: 'Open cart',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: Palette.inkSoft, borderRadius: BorderRadius.circular(15)),
                    alignment: Alignment.center,
                    child: PopSwitcher(
                      child: cartCount == 0
                          ? const Icon(Icons.shopping_bag_outlined, key: ValueKey(0), color: Palette.onInk)
                          : Text('$cartCount',
                              key: ValueKey(cartCount),
                              style: const TextStyle(color: Palette.olive, fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Reveal(
              delay: Motion.stagger(1),
              child: TextField(
                onChanged: onSearch,
                cursorColor: Palette.olive,
                style: const TextStyle(color: Palette.onInk),
                decoration: InputDecoration(
                  hintText: 'Search products',
                  hintStyle: const TextStyle(color: Palette.onInkMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: Palette.onInkMuted),
                  fillColor: Palette.inkSoft,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Palette.olive, width: 1.6),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.94,
        label: label,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.curve,
          width: 104,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Palette.olive : Palette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? Palette.olive : Palette.line),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 32, color: selected ? Palette.ink : Palette.oliveDeep),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Palette.ink)),
          ]),
        ),
      ),
    );
  }
}
