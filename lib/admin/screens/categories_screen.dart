import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/common_widgets.dart';
import '../widgets/admin_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final Stream<List<Category>> _categories;
  late final Stream<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    final svc = context.read<ProductService>();
    _categories = svc.watchCategories();
    _products = svc.watchProducts();
  }

  Future<String?> _askName({String initial = '', required String title}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) showSnack(context, done);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  Future<void> _add() async {
    final name = (await _askName(title: 'New category'))?.trim();
    if (name == null || name.isEmpty || !mounted) return;
    await _run(() => context.read<ProductService>().addCategory(name), 'Added "$name"');
  }

  Future<void> _rename(Category c) async {
    final name = (await _askName(title: 'Rename category', initial: c.name))?.trim();
    if (name == null || name.isEmpty || name == c.name || !mounted) return;
    await _run(() => context.read<ProductService>().renameCategory(c.id, name), 'Renamed to "$name"');
  }

  Future<void> _delete(Category c, int count) async {
    if (count > 0) {
      showSnack(context, 'Move or delete the $count product(s) in "${c.name}" first.', error: true);
      return;
    }
    if (!await confirm(context, 'Delete category?', 'Delete "${c.name}"?') || !mounted) return;
    await _run(() => context.read<ProductService>().deleteCategory(c.id), 'Deleted "${c.name}"');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, pSnap) => StreamBuilder<List<Category>>(
        stream: _categories,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(snap.error!);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final cats = snap.data!;
          final products = pSnap.data ?? const <Product>[];

          return ListView(children: [
            PageHeader(
              title: 'Categories',
              subtitle: 'Shown as filter chips in the mobile app',
              actions: [FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add category'))],
            ),
            if (cats.isEmpty)
              const EmptyState(icon: Icons.category_outlined, title: 'No categories yet')
            else
              TableCard(
                table: DataTable(
                  headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Products'), numeric: true),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final c in cats)
                      () {
                        final count = products.where((p) => p.categoryId == c.id).length;
                        return DataRow(cells: [
                          DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text('$count')),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(tooltip: 'Rename', icon: const Icon(Icons.edit_outlined), onPressed: () => _rename(c)),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _delete(c, count),
                            ),
                          ])),
                        ]);
                      }(),
                  ],
                ),
              ),
          ]);
        },
      ),
    );
  }
}
