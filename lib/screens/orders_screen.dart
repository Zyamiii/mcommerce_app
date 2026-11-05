import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';

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
            padding: const EdgeInsets.all(18),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final o = orders[i];
              final color = StatusChip.colorFor(o.status);
              return Reveal(
                key: ValueKey(o.id),
                delay: Motion.stagger(i),
                child: Pressable(
                  label: 'Order ${shortId(o.id)}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Palette.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Palette.line),
                    ),
                    child: Row(children: [
                      IconTile(StatusChip.iconFor(o.status), color: color, background: color.withValues(alpha: 0.12)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text('#${shortId(o.id)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                            StatusChip(o.status),
                          ]),
                          const SizedBox(height: 4),
                          Text(dateTime(o.timestamp), style: const TextStyle(color: Palette.muted, fontSize: 13)),
                          Text('${o.itemCount} ${o.itemCount == 1 ? 'item' : 'items'} • ${money(o.total)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Palette.muted),
                    ]),
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
            padding: const EdgeInsets.all(18),
            children: [
              Reveal(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Expanded(
                          child: Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        StatusChip(o.status),
                      ]),
                      const SizedBox(height: 18),
                      AnimatedSize(
                        duration: Motion.base,
                        curve: Motion.curve,
                        child: _StatusTracker(status: o.status),
                      ),
                      const SizedBox(height: 10),
                      Text('Last updated ${dateTime(o.updatedAt)}',
                          style: const TextStyle(fontSize: 13, color: Palette.muted)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Reveal(
                delay: Motion.stagger(1),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Column(children: [
                    for (final i in o.items)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: ProductImage(i.imageUrl, size: 52, radius: BorderRadius.circular(14)),
                        title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              ),
              const SizedBox(height: 12),
              Reveal(
                delay: Motion.stagger(2),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      _info(Icons.location_on_outlined, 'Ship to', '${o.customerName}\n${o.phone}\n${o.shippingAddress}'),
                      _info(Icons.payments_outlined, 'Payment', o.paymentMethod),
                      _info(Icons.schedule_rounded, 'Placed on', dateTime(o.timestamp)),
                    ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) => ListTile(
        leading: IconTile(icon, size: 42),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
      );

  Widget _line(String a, String b, {bool bold = false}) {
    final s = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 17 : 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Text(a, style: s), const Spacer(), Text(b, style: s)]),
    );
  }
}

/// Steps fill in one after another when an order moves forward.
class _StatusTracker extends StatelessWidget {
  final String status;
  const _StatusTracker({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Row(children: [
        IconTile(Icons.cancel_outlined, size: 44, color: Palette.clay, background: Palette.clay.withValues(alpha: 0.12)),
        const SizedBox(width: 12),
        const Expanded(child: Text('This order was cancelled. Any items were returned to stock.')),
      ]);
    }
    final current = OrderStatus.flow.indexOf(status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < OrderStatus.flow.length; i++) ...[
          SizedBox(
            width: 62,
            child: Column(children: [
              AnimatedContainer(
                duration: Motion.slow,
                curve: Curves.easeOutBack,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: i <= current ? Palette.olive : Palette.line,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  child: Icon(
                    i < current ? Icons.check_rounded : StatusChip.iconFor(OrderStatus.flow[i]),
                    key: ValueKey(i < current),
                    size: 21,
                    color: i <= current ? Palette.ink : Palette.muted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: Motion.base,
                style: TextStyle(
                  fontFamily: 'Barlow',
                  color: i == current ? Palette.ink : Palette.muted,
                  fontSize: 12,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(OrderStatus.label(OrderStatus.flow[i]), textAlign: TextAlign.center),
              ),
            ]),
          ),
          if (i < OrderStatus.flow.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 19),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(children: [
                    Container(height: 4, color: Palette.line),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: i < current ? 1 : 0),
                      duration: Motion.slow,
                      curve: Motion.curve,
                      builder: (_, v, _) => FractionallySizedBox(
                        widthFactor: v,
                        child: Container(height: 4, color: Palette.oliveDeep),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
