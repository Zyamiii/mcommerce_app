import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/formatters.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/common_widgets.dart';
import '../widgets/admin_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final Stream<List<Product>> _products;
  late final Stream<List<Category>> _categories;
  String _query = '';
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final svc = context.read<ProductService>();
    _products = svc.watchProducts();
    _categories = svc.watchCategories();
  }

  Future<void> _openForm(List<Category> cats, [Product? p]) async {
    if (cats.isEmpty) {
      showSnack(context, 'Create a category first.', error: true);
      return;
    }
    await showDialog(context: context, builder: (_) => ProductFormDialog(categories: cats, product: p));
  }

  Future<void> _delete(Product p) async {
    if (!await confirm(context, 'Delete product?', '"${p.productName}" will be removed from the store. '
        'Past orders keep their copy of the item.')) {
      return;
    }
    if (!mounted) return;
    try {
      await context.read<ProductService>().deleteProduct(p.id);
      if (mounted) showSnack(context, 'Deleted ${p.productName}');
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: _categories,
      builder: (context, cSnap) {
        final cats = cSnap.data ?? const <Category>[];
        return StreamBuilder<List<Product>>(
          stream: _products,
          builder: (context, pSnap) {
            if (pSnap.hasError) return ErrorView(pSnap.error!);
            if (!pSnap.hasData) return const Center(child: CircularProgressIndicator());
            final all = pSnap.data!;
            final rows = all.where((p) {
              final q = _query.isEmpty || p.productName.toLowerCase().contains(_query);
              final c = _categoryId == null || p.categoryId == _categoryId;
              return q && c;
            }).toList();

            return ListView(children: [
              PageHeader(
                title: 'Products',
                subtitle: '${all.length} total • ${all.where((p) => p.isActive).length} visible in the app',
                actions: [
                  SizedBox(
                    width: 240,
                    child: TextField(
                      decoration: const InputDecoration(hintText: 'Search', prefixIcon: Icon(Icons.search), isDense: true),
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _categoryId,
                      isDense: true,
                      decoration: const InputDecoration(isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All categories')),
                        for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openForm(cats),
                    icon: const Icon(Icons.add),
                    label: const Text('Add product'),
                  ),
                ],
              ),
              if (rows.isEmpty)
                const EmptyState(icon: Icons.inventory_2_outlined, title: 'No products', message: 'Add a product or load sample data from the Dashboard.')
              else
                TableCard(
                  table: DataTable(
                    headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Price'), numeric: true),
                      DataColumn(label: Text('Stock'), numeric: true),
                      DataColumn(label: Text('Visible')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final p in rows)
                        DataRow(cells: [
                          DataCell(Row(children: [
                            ProductImage(p.imageUrl, size: 44),
                            const SizedBox(width: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(p.productName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ])),
                          DataCell(Text(p.categoryName)),
                          DataCell(Text(money(p.price))),
                          DataCell(Text('${p.stock}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: p.stock == 0 ? Colors.red : p.stock <= 5 ? Colors.orange.shade800 : null,
                              ))),
                          DataCell(Switch(
                            value: p.isActive,
                            onChanged: (v) => context.read<ProductService>().setActive(p.id, v),
                          )),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: () => _openForm(cats, p)),
                            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(p)),
                          ])),
                        ]),
                    ],
                  ),
                ),
            ]);
          },
        );
      },
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  final List<Category> categories;
  final Product? product;
  const ProductFormDialog({super.key, required this.categories, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _desc, _price, _stock, _image;
  String? _categoryId;
  bool _active = true;
  bool _busy = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.productName ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toStringAsFixed(2));
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _image = TextEditingController(text: p?.imageUrl ?? '');
    _active = p?.isActive ?? true;
    final ids = widget.categories.map((c) => c.id);
    _categoryId = (p != null && ids.contains(p.categoryId)) ? p.categoryId : widget.categories.first.id;
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _stock, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final cat = widget.categories.firstWhere((c) => c.id == _categoryId);
    final product = Product(
      id: widget.product?.id ?? '',
      productName: _name.text.trim(),
      description: _desc.text.trim(),
      price: double.parse(_price.text),
      stock: int.parse(_stock.text),
      categoryId: cat.id,
      categoryName: cat.name,
      imageUrl: _image.text.trim(),
      isActive: _active,
    );
    final svc = context.read<ProductService>();
    try {
      _isEdit ? await svc.updateProduct(product) : await svc.addProduct(product);
      if (mounted) {
        Navigator.of(context).pop();
        showSnack(context, _isEdit ? 'Product updated' : 'Product added');
      }
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit product' : 'Add product'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Price (₱)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0) ? 'Enter a price > 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a whole number' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [for (final c in widget.categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _image,
                    decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://…'),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Required';
                      final uri = Uri.tryParse(s);
                      return (uri == null || !uri.hasScheme || !s.startsWith('http')) ? 'Enter a valid http(s) URL' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ProductImage(_image.text.trim(), size: 56),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible in the mobile app'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Saving…' : 'Save')),
      ],
    );
  }
}
