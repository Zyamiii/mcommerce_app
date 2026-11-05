import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _categories => _db.collection('categories');

  /// Live product list. Customers pass [activeOnly] = true; the admin sees all.
  /// Sorting and category/search filtering are done client-side so no
  /// composite indexes are required.
  Stream<List<Product>> watchProducts({bool activeOnly = false}) {
    Query<Map<String, dynamic>> q = _products;
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    return q.snapshots().map((s) {
      final list = s.docs.map(Product.fromDoc).toList();
      list.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
      return list;
    });
  }

  Stream<Product?> watchProduct(String id) =>
      _products.doc(id).snapshots().map((d) => d.exists ? Product.fromDoc(d) : null);

  Stream<List<Category>> watchCategories() => _categories.snapshots().map((s) {
        final list = s.docs.map(Category.fromDoc).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  // ---- Admin: products ----

  Future<void> addProduct(Product p) => _products.add({
        ...p.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateProduct(Product p) => _products.doc(p.id).update({
        ...p.toMap(),
        'name': FieldValue.delete(), // old field, replaced by productName
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setActive(String id, bool active) =>
      _products.doc(id).update({'isActive': active, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  // ---- Admin: categories ----

  Future<void> addCategory(String name) => _categories.add({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Renames a category and keeps the denormalized name on its products in sync.
  Future<void> renameCategory(String id, String name) async {
    final batch = _db.batch();
    batch.update(_categories.doc(id), {'name': name.trim()});
    final prods = await _products.where('categoryId', isEqualTo: id).get();
    for (final d in prods.docs) {
      batch.update(d.reference, {'categoryName': name.trim()});
    }
    await batch.commit();
  }

  Future<int> productCountInCategory(String id) async {
    final agg = await _products.where('categoryId', isEqualTo: id).count().get();
    return agg.count ?? 0;
  }

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  // ---- Sample data (used once from the admin dashboard) ----

  Future<void> seedSampleData() async {
    final batch = _db.batch();
    final catIds = <String, String>{};
    for (final name in ['Electronics', 'Fashion', 'Home & Living', 'Groceries']) {
      final ref = _categories.doc();
      catIds[name] = ref.id;
      batch.set(ref, {'name': name, 'createdAt': FieldValue.serverTimestamp()});
    }

    final samples = [
      ('Wireless Earbuds', 'Electronics', 1499.0, 40, 'Bluetooth 5.3 earbuds with 24-hour battery life and charging case.'),
      ('Smart Watch', 'Electronics', 2999.0, 25, 'Fitness tracking, heart-rate monitor and smartphone notifications.'),
      ('Power Bank 20,000mAh', 'Electronics', 899.0, 60, 'Fast-charging power bank with dual USB-C ports.'),
      ('Cotton T-Shirt', 'Fashion', 349.0, 100, 'Soft 100% cotton crew-neck shirt, available in classic fit.'),
      ('Denim Jacket', 'Fashion', 1299.0, 20, 'Washed denim jacket with button front and chest pockets.'),
      ('Canvas Sneakers', 'Fashion', 999.0, 35, 'Lightweight everyday sneakers with cushioned insole.'),
      ('Ceramic Mug Set', 'Home & Living', 499.0, 50, 'Set of four 350ml ceramic mugs, dishwasher safe.'),
      ('LED Desk Lamp', 'Home & Living', 749.0, 30, 'Adjustable LED lamp with three brightness levels.'),
      ('Arabica Coffee Beans 500g', 'Groceries', 420.0, 80, 'Medium-roast whole beans from Benguet highlands.'),
      ('Organic Honey 350g', 'Groceries', 280.0, 45, 'Raw wildflower honey, no added sugar.'),
    ];

    for (final (name, cat, price, stock, desc) in samples) {
      final ref = _products.doc();
      final seed = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      batch.set(ref, {
        'productName': name,
        'description': desc,
        'price': price,
        'stock': stock,
        'categoryId': catIds[cat],
        'categoryName': cat,
        'imageUrl': 'https://picsum.photos/seed/$seed/600/600',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
