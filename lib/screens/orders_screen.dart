import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../providers/session_provider.dart';
import '../widgets/common_widgets.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback onBrowse;
  const OrdersScreen({super.key, required this.onBrowse});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<List<AppOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = context.read<OrderService>().watchUserOrders(context.read<Session>().uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<List<AppOrder>>(
        stream: _orders,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(snap.error!);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snap.data!;
          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Orders you place will appear here.',
              action: FilledButton(onPressed: widget.onBrowse, child: const Text('Browse products')),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = orders[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Row(children: [
                    Text('#${shortId(o.id)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    StatusChip(o.status),
                  ]),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${dateTime(o.timestamp)}\n${o.itemCount} item(s) • ${money(o.total)}'),
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<AppOrder?> _order;

  @override
  void initState() {
    super.initState();
    _order = context.read<OrderService>().watchOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${shortId(widget.orderId)}')),
      body: StreamBuilder<AppOrder?>(
        stream: _order,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(snap.error!);
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final o = snap.data;
          if (o == null) return const EmptyState(icon: Icons.search_off, title: 'Order not found');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('Status', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      StatusChip(o.status),
                    ]),
                    const SizedBox(height: 16),
                    _StatusTracker(status: o.status),
                    const SizedBox(height: 8),
                    Text('Last updated ${dateTime(o.updatedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(children: [
                  for (final i in o.items)
                    ListTile(
                      leading: ProductImage(i.imageUrl, size: 48),
                      title: Text(i.name),
                      subtitle: Text('${i.quantity} × ${money(i.price)}'),
                      trailing: Text(money(i.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _line('Subtotal', money(o.subtotal)),
                      _line('Shipping', money(o.shippingFee)),
                      _line('Total', money(o.total), bold: true),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(children: [
                  ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Ship to'),
                      subtitle: Text('${o.customerName}\n${o.phone}\n${o.shippingAddress}')),
                  ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('Payment'),
                      subtitle: Text(o.paymentMethod)),
                  ListTile(leading: const Icon(Icons.schedule), title: const Text('Placed on'),
                      subtitle: Text(dateTime(o.timestamp))),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) {
    final s = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Text(a, style: s), const Spacer(), Text(b, style: s)]),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  final String status;
  const _StatusTracker({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return const Row(children: [
        Icon(Icons.cancel, color: Colors.red),
        SizedBox(width: 8),
        Expanded(child: Text('This order was cancelled. Any items were returned to stock.')),
      ]);
    }
    final current = OrderStatus.flow.indexOf(status);
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (var i = 0; i < OrderStatus.flow.length; i++) ...[
          Column(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: i <= current ? primary : Colors.grey.shade300,
              child: Icon(i < current ? Icons.check : Icons.circle, size: i < current ? 16 : 8, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(OrderStatus.label(OrderStatus.flow[i]),
                style: TextStyle(fontSize: 11, fontWeight: i == current ? FontWeight.bold : FontWeight.normal)),
          ]),
          if (i < OrderStatus.flow.length - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < current ? primary : Colors.grey.shade300,
              ),
            ),
        ],
      ],
    );
  }
}
