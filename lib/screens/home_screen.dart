import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../providers/session_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final name = context.select<Session, String>((s) => s.profile?.name ?? '');
    final firstName = name.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ShopEase', style: TextStyle(fontWeight: FontWeight.bold)),
            if (firstName.isNotEmpty)
              Text('Hi, $firstName!', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          SizedBox(
            height: 44,
            child: StreamBuilder<List<Category>>(
              stream: _categories,
              builder: (context, snap) {
                final cats = snap.data ?? const [];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip('All', null),
                    for (final c in cats) _chip(c.name, c.id),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _products,
              builder: (context, snap) {
                if (snap.hasError) return ErrorView(snap.error!);
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!.where((p) {
                  final catOk = _categoryId == null || p.categoryId == _categoryId;
                  final qOk = _query.isEmpty ||
                      p.productName.toLowerCase().contains(_query) ||
                      p.categoryName.toLowerCase().contains(_query);
                  return catOk && qOk;
                }).toList();

                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    message: 'Try another search or category.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => ProductCard(
                    product: items[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: items[i].id)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? id) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: _categoryId == id,
          onSelected: (_) => setState(() => _categoryId = id),
        ),
      );
}

