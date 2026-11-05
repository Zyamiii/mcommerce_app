import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/session_provider.dart';
import '../services/user_service.dart';
import '../widgets/common_widgets.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final initials = p.name.trim().isEmpty
        ? '?'
        : p.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing) IconButton(onPressed: _startEdit, icon: const Icon(Icons.edit_outlined), tooltip: 'Edit'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: scheme.primaryContainer,
              child: Text(initials, style: TextStyle(fontSize: 26, color: scheme.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(p.name, style: Theme.of(context).textTheme.titleLarge)),
          Center(child: Text(p.email, style: TextStyle(color: Colors.grey.shade600))),
          const SizedBox(height: 24),
          if (_editing)
            Form(
              key: _form,
              child: Column(children: [
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
                  Expanded(child: FilledButton(onPressed: _busy ? null : _save, child: const Text('Save'))),
                ]),
              ]),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Mobile number'),
                  subtitle: Text(p.phone.isEmpty ? 'Not set' : p.phone),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Default address'),
                  subtitle: Text(p.address.isEmpty ? 'Not set' : p.address),
                ),
              ]),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}
