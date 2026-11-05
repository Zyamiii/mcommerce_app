import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../services/order_service.dart';
import '../providers/session_provider.dart';
import '../services/user_service.dart';
import '../widgets/common_widgets.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _paymentMethods = ['Cash on Delivery', 'GCash', 'Credit/Debit Card'];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _address;
  String _payment = _paymentMethods.first;
  bool _saveDetails = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<Session>().profile!;
    _phone = TextEditingController(text: profile.phone);
    _address = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    final session = context.read<Session>();
    final profile = session.profile!;
    setState(() => _busy = true);
    try {
      final orderId = await context.read<OrderService>().placeOrder(
            user: profile,
            cart: session.cart,
            phone: _phone.text,
            shippingAddress: _address.text,
            paymentMethod: _payment,
          );
      if (_saveDetails && mounted) {
        await context.read<UserService>().updateProfile(
              profile.uid,
              name: profile.name,
              phone: _phone.text,
              address: _address.text,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _OrderPlacedScreen(orderId: orderId)),
      );
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final total = session.cartSubtotal + OrderService.shippingFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Delivery details'),
            TextFormField(
              initialValue: session.profile?.name,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => (v == null || v.replaceAll(RegExp(r'\D'), '').length < 10)
                  ? 'Enter a valid mobile number'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Shipping address',
                prefixIcon: Icon(Icons.location_on_outlined),
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Enter your full address' : null,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _saveDetails,
              onChanged: (v) => setState(() => _saveDetails = v ?? false),
              title: const Text('Save these details to my profile'),
            ),
            _section('Payment method'),
            Wrap(
              spacing: 8,
              children: [
                for (final m in _paymentMethods)
                  ChoiceChip(label: Text(m), selected: _payment == m, onSelected: (_) => setState(() => _payment = m)),
              ],
            ),
            if (_payment != 'Cash on Delivery')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Demo only: online payment is simulated and marked as paid on delivery.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            _section('Order summary'),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  for (final c in session.cart)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text('${c.quantity} × ${c.name}', overflow: TextOverflow.ellipsis)),
                        Text(money(c.lineTotal)),
                      ]),
                    ),
                  const Divider(),
                  _line('Subtotal', money(session.cartSubtotal)),
                  _line('Shipping', money(OrderService.shippingFee)),
                  _line('Total', money(total), bold: true),
                ]),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: (_busy || session.cart.isEmpty) ? null : _placeOrder,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Place order • ${money(total)}'),
          ),
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      );

  Widget _line(String a, String b, {bool bold = false}) {
    final s = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Text(a, style: s), const Spacer(), Text(b, style: s)]),
    );
  }
}

class _OrderPlacedScreen extends StatelessWidget {
  final String orderId;
  const _OrderPlacedScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 96, color: Colors.green),
              const SizedBox(height: 16),
              Text('Order placed!', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Order #${shortId(orderId)} is now pending. You can track its status in Orders.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
                ),
                child: const Text('Track order'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
