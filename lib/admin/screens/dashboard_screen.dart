import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/formatters.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';
import '../../widgets/common_widgets.dart';
import '../widgets/admin_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const lowStockThreshold = 5;

  late final Stream<List<AppOrder>> _orders;
  late final Stream<List<Product>> _products;
  late final Stream<List<AppUser>> _users;
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _orders = context.read<OrderService>().watchAllOrders();
    _products = context.read<ProductService>().watchProducts();
    _users = context.read<UserService>().watchAllUsers();
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await context.read<ProductService>().seedSampleData();
      if (mounted) showSnack(context, 'Sample categories and products added.');
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppOrder>>(
      stream: _orders,
      builder: (context, oSnap) => StreamBuilder<List<Product>>(
        stream: _products,
        builder: (context, pSnap) => StreamBuilder<List<AppUser>>(
          stream: _users,
          builder: (context, uSnap) {
            final err = oSnap.error ?? pSnap.error ?? uSnap.error;
            if (err != null) return ErrorView(err);
            if (!oSnap.hasData || !pSnap.hasData || !uSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _build(oSnap.data!, pSnap.data!, uSnap.data!);
          },
        ),
      ),
    );
  }

  Widget _build(List<AppOrder> orders, List<Product> products, List<AppUser> users) {
    final active = orders.where((o) => o.status != OrderStatus.cancelled);
    final revenue = active.fold<double>(0, (s, o) => s + o.total);
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).fold<double>(0, (s, o) => s + o.total);
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;
    final lowStock = products.where((p) => p.stock <= lowStockThreshold).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    final stats = [
      StatCard(label: 'Gross sales', value: money(revenue), icon: Icons.payments_outlined, color: Colors.green, onTap: () => widget.onNavigate(3)),
      StatCard(label: 'Delivered sales', value: money(delivered), icon: Icons.local_shipping_outlined, color: Colors.teal, onTap: () => widget.onNavigate(3)),
      StatCard(label: 'Total orders', value: '${orders.length}', icon: Icons.receipt_long_outlined, color: Colors.blue, onTap: () => widget.onNavigate(3)),
      StatCard(label: 'Pending orders', value: '$pending', icon: Icons.hourglass_top, color: Colors.orange, onTap: () => widget.onNavigate(3)),
      StatCard(label: 'Products', value: '${products.length}', icon: Icons.inventory_2_outlined, color: Colors.purple, onTap: () => widget.onNavigate(1)),
      StatCard(label: 'Users', value: '${users.length}', icon: Icons.people_outline, color: Colors.indigo, onTap: () => widget.onNavigate(4)),
    ];

    return ListView(
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: 'Live overview — updates instantly as customers shop',
          actions: [
            if (products.isEmpty)
              FilledButton.icon(
                onPressed: _seeding ? null : _seed,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_seeding ? 'Adding…' : 'Load sample data'),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 1100 ? 3 : c.maxWidth >= 640 ? 2 : 1;
            final w = (c.maxWidth - (cols - 1) * 16) / cols;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [for (final s in stats) SizedBox(width: w, child: s)],
            );
          }),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;
            final left = _RecentOrders(orders: orders.take(6).toList(), onViewAll: () => widget.onNavigate(3));
            final right = Column(children: [
              _StatusBreakdown(orders: orders),
              const SizedBox(height: 16),
              _LowStock(products: lowStock.take(6).toList(), onViewAll: () => widget.onNavigate(1)),
            ]);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: right),
                  ])
                : Column(children: [left, const SizedBox(height: 16), right]);
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onViewAll;
  const _Panel({required this.title, required this.child, this.onViewAll});

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('View all')),
            ]),
            const SizedBox(height: 8),
            child,
          ]),
        ),
      );
}

class _RecentOrders extends StatelessWidget {
  final List<AppOrder> orders;
  final VoidCallback onViewAll;
  const _RecentOrders({required this.orders, required this.onViewAll});

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Recent orders',
        onViewAll: onViewAll,
        child: orders.isEmpty
            ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No orders yet.')))
            : Column(children: [
                for (final o in orders)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('#${shortId(o.id)} • ${o.customerName}'),
                    subtitle: Text('${dateTime(o.timestamp)} • ${o.itemCount} item(s)'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(money(o.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      StatusChip(o.status),
                    ]),
                  ),
              ]),
      );
}

class _StatusBreakdown extends StatelessWidget {
  final List<AppOrder> orders;
  const _StatusBreakdown({required this.orders});

  @override
  Widget build(BuildContext context) {
    final total = orders.isEmpty ? 1 : orders.length;
    return _Panel(
      title: 'Orders by status',
      child: Column(children: [
        for (final s in OrderStatus.all)
          Builder(builder: (context) {
            final n = orders.where((o) => o.status == s).length;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 90, child: Text(OrderStatus.label(s))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: n / total,
                      minHeight: 10,
                      color: StatusChip.colorFor(s),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ),
                SizedBox(width: 36, child: Text('$n', textAlign: TextAlign.right)),
              ]),
            );
          }),
      ]),
    );
  }
}

class _LowStock extends StatelessWidget {
  final List<Product> products;
  final VoidCallback onViewAll;
  const _LowStock({required this.products, required this.onViewAll});

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'Low stock (≤ ${_DashboardScreenState.lowStockThreshold})',
        onViewAll: onViewAll,
        child: products.isEmpty
            ? const Padding(padding: EdgeInsets.all(12), child: Text('All products are well stocked.'))
            : Column(children: [
                for (final p in products)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ProductImage(p.imageUrl, size: 40),
                    title: Text(p.productName, overflow: TextOverflow.ellipsis),
                    trailing: Text(p.stock == 0 ? 'Out' : '${p.stock} left',
                        style: TextStyle(color: p.stock == 0 ? Colors.red : Colors.orange.shade800, fontWeight: FontWeight.bold)),
                  ),
              ]),
      );
}
