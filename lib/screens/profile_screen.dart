import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/session_provider.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _editing = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _startEdit() {
    final p = context.read<Session>().profile!;
    _name.text = p.name;
    _phone.text = p.phone;
    _address.text = p.address;
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<UserService>().updateProfile(
            context.read<Session>().uid,
            name: _name.text,
            phone: _phone.text,
            address: _address.text,
          );
      if (mounted) {
        setState(() => _editing = false);
        showSnack(context, 'Profile updated');
      }
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<Session>().profile;
    if (p == null) return const SizedBox.shrink();
    final initials = p.name.trim().isEmpty
        ? '?'
        : p.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Palette.ink,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 26),
                  child: Reveal(
                    child: Row(children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(26)),
                        alignment: Alignment.center,
                        child: Text(initials,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Palette.ink)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name,
                              style: const TextStyle(color: Palette.onInk, fontSize: 22, fontWeight: FontWeight.w700)),
                          Text(p.email, style: const TextStyle(color: Palette.onInkMuted)),
                        ]),
                      ),
                      PopSwitcher(
                        child: _editing
                            ? const SizedBox(key: ValueKey('none'), width: 48)
                            : IconButton(
                                key: const ValueKey('edit'),
                                onPressed: _startEdit,
                                color: Palette.onInk,
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                              ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AnimatedSize(
                  duration: Motion.base,
                  curve: Motion.curve,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: Motion.base,
                    child: _editing ? _editForm() : _details(p.phone, p.address),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: Motion.stagger(2),
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<AuthService>().signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(foregroundColor: Palette.clay),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(String phone, String address) {
    return Reveal(
      key: const ValueKey('details'),
      delay: Motion.stagger(1),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            ListTile(
              leading: const IconTile(Icons.phone_outlined, size: 42),
              title: const Text('Mobile number', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(phone.isEmpty ? 'Not set' : phone),
            ),
            ListTile(
              leading: const IconTile(Icons.location_on_outlined, size: 42),
              title: const Text('Default address', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(address.isEmpty ? 'Not set' : address),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _editForm() {
    return Form(
      key: _form,
      child: Column(key: const ValueKey('form'), children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Full name'),
          validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Mobile number'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _address,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Default shipping address'),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => setState(() => _editing = false),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const ButtonSpinner() : const Text('Save'),
            ),
          ),
        ]),
      ]),
    );
  }
}
