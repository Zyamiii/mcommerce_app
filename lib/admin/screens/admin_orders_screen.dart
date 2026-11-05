import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/formatters.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/common_widgets.dart';
import '../widgets/admin_widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late final Stream<List<AppOrder>> _orders;
  String? _status;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _orders = context.read<OrderService>().watchAllOrders();
  }

  Future<void> _setStatus(AppOrder o, String status) async {
    if (status == OrderStatus.cancelled &&
        !await confirm(context, 'Cancel order?', 'Order #${shortId(o.id)} will be cancelled and its items returned to stock. '
            'This cannot be undone.', action: 'Cancel order', dismiss: 'Keep order')) {
      return;
    }
    if (!mounted) return;
    try {
      await context.read<OrderService>().updateStatus(o.id, status);
      if (mounted) showSnack(context, 'Order #${shortId(o.id)} → ${OrderStatus.label(status)}');
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppOrder>>(
      stream: _orders,
      builder: (context, snap) {
        if (snap.hasError) return ErrorView(snap.error!);
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final all = snap.data!;
        final rows = all.where((o) {
          final s = _status == null || o.status == _status;
          final q = _query.isEmpty ||
              o.id.toLowerCase().contains(_query) ||
              o.customerName.toLowerCase().contains(_query) ||
              o.customerEmail.toLowerCase().contains(_query);
          return s && q;
        }).toList();

        return ListView(children: [
          PageHeader(
            title: 'Orders',
            subtitle: 'Status changes appear instantly in the customer\'s app',
            actions: [
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search ID, name or email', prefixIcon: Icon(Icons.search), isDense: true),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(label: Text('All (${all.length})'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              for (final s in OrderStatus.all)
                ChoiceChip(
                  label: Text('${OrderStatus.label(s)} (${all.where((o) => o.status == s).length})'),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ]),
          ),
          if (rows.isEmpty)
            const EmptyState(icon: Icons.receipt_long_outlined, title: 'No orders match')
          else
            TableCard(
              table: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
                showCheckboxColumn: false,
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Order')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Products Ordered')),
                  DataColumn(label: Text('Total Amount'), numeric: true),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  for (final o in rows)
                    DataRow(
                      onSelectChanged: (_) => showDialog(context: context, builder: (_) => _OrderDialog(order: o)),
                      cells: [
                        DataCell(Text('#${shortId(o.id)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(dateTime(o.timestamp))),
                        DataCell(Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(o.customerName), Text(o.customerEmail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))],
                        )),
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            o.items.map((i) => '${i.quantity} × ${i.name}').join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        DataCell(Text(money(o.total))),
                        DataCell(Text(o.paymentMethod)),
                        DataCell(o.status == OrderStatus.cancelled
                            ? const StatusChip(OrderStatus.cancelled)
                            : DropdownButton<String>(
                                value: o.status,
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (final s in OrderStatus.all)
                                    DropdownMenuItem(value: s, child: StatusChip(s)),
                                ],
                                onChanged: (s) {
                                  if (s != null && s != o.status) _setStatus(o, s);
                                },
                              )),
                      ],
                    ),
                ],
              ),
            ),
        ]);
      },
    );
  }
}

class _OrderDialog extends StatelessWidget {
  final AppOrder order;
  const _OrderDialog({required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return AlertDialog(
      title: Row(children: [Text('Order #${shortId(o.id)}'), const Spacer(), StatusChip(o.status)]),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _kv('Placed', dateTime(o.timestamp)),
            _kv('Updated', dateTime(o.updatedAt)),
            _kv('Customer', '${o.customerName} <${o.customerEmail}>'),
            _kv('Phone', o.phone),
            _kv('Ship to', o.shippingAddress),
            _kv('Payment', o.paymentMethod),
            const Divider(height: 24),
            for (final i in o.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ProductImage(i.imageUrl, size: 40),
                title: Text(i.name),
                subtitle: Text('${i.quantity} × ${money(i.price)}'),
                trailing: Text(money(i.lineTotal)),
              ),
            const Divider(),
            _kv('Subtotal', money(o.subtotal)),
            _kv('Shipping', money(o.shippingFee)),
            _kv('Total', money(o.total), bold: true),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(k, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
        ]),
      );
}
