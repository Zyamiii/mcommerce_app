import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../services/order_service.dart';
import '../providers/session_provider.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _PaymentOption {
  final String name;
  final String note;
  final IconData icon;
  const _PaymentOption(this.name, this.note, this.icon);
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _paymentMethods = [
    _PaymentOption('Cash on Delivery', 'Pay when your order arrives', Icons.payments_outlined),
    _PaymentOption('GCash', 'Simulated for this demo', Icons.account_balance_wallet_outlined),
    _PaymentOption('Credit/Debit Card', 'Simulated for this demo', Icons.credit_card_outlined),
  ];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _address;
  String _payment = _paymentMethods.first.name;
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
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
          children: [
            Reveal(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionTitle('Delivery details'),
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
              ]),
            ),
            Reveal(
              delay: Motion.stagger(2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionTitle('Payment method'),
                for (final m in _paymentMethods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentTile(
                      option: m,
                      selected: _payment == m.name,
                      onTap: () => setState(() => _payment = m.name),
                    ),
                  ),
              ]),
            ),
            Reveal(
              delay: Motion.stagger(4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionTitle('Order summary'),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      for (final c in session.cart)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(child: Text('${c.quantity} × ${c.name}', overflow: TextOverflow.ellipsis)),
                            Text(money(c.lineTotal)),
                          ]),
                        ),
                      const Divider(height: 20),
                      _line('Subtotal', money(session.cartSubtotal)),
                      _line('Shipping', money(OrderService.shippingFee)),
                      _line('Total', money(total), bold: true),
                    ]),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomDock(
        child: FilledButton(
          onPressed: (_busy || session.cart.isEmpty) ? null : _placeOrder,
          child: AnimatedSwitcher(
            duration: Motion.fast,
            child: _busy
                ? const ButtonSpinner(key: ValueKey('busy'))
                : Text('Place order • ${money(total)}', key: const ValueKey('place')),
          ),
        ),
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) {
    final s = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 17 : 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [Text(a, style: s), const Spacer(), Text(b, style: s)]),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final _PaymentOption option;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      label: option.name,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.curve,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Palette.oliveTint : Palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? Palette.oliveDeep : Palette.line, width: selected ? 1.6 : 1),
        ),
        child: Row(children: [
          IconTile(option.icon, size: 46, background: selected ? Palette.olive : Palette.oliveTint,
              color: selected ? Palette.ink : Palette.oliveDeep),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Text(option.note, style: const TextStyle(color: Palette.muted, fontSize: 13)),
            ]),
          ),
          AnimatedContainer(
            duration: Motion.base,
            curve: Curves.easeOutBack,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: selected ? Palette.oliveDeep : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? Palette.oliveDeep : Palette.muted, width: 1.6),
            ),
            child: selected ? const Icon(Icons.check_rounded, size: 16, color: Palette.onInk) : null,
          ),
        ]),
      ),
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
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(color: Palette.oliveTint, borderRadius: BorderRadius.circular(44)),
                    alignment: Alignment.center,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(30)),
                      child: const Icon(Icons.check_rounded, size: 56, color: Palette.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Reveal(
                delay: const Duration(milliseconds: 250),
                child: Text('Order placed!', textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Reveal(
                delay: const Duration(milliseconds: 320),
                child: Text('Order #${shortId(orderId)} is now pending. You can track its status in Orders.',
                    textAlign: TextAlign.center, style: const TextStyle(color: Palette.muted, fontSize: 16)),
              ),
              const SizedBox(height: 32),
              Reveal(
                delay: const Duration(milliseconds: 400),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
                    ),
                    child: const Text('Track order'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continue shopping'),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
