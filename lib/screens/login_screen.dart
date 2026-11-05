import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/motion.dart';

/// Email/password sign-in used by both the mobile app and the admin dashboard.
class LoginScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRegister;

  const LoginScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.shopping_bag_rounded,
    this.onRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthService>().signIn(_email.text, _password.text);
    } catch (e) {
      if (mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      showSnack(context, 'Enter your email first.', error: true);
      return;
    }
    try {
      await context.read<AuthService>().sendPasswordReset(_email.text);
      if (mounted) showSnack(context, 'Password reset link sent to ${_email.text.trim()}.');
    } catch (e) {
      if (mounted) showSnack(context, AuthService.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.ink,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 48, 28, 34),
                      child: Reveal(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(22)),
                            child: Icon(widget.icon, size: 36, color: Palette.ink),
                          ),
                          const SizedBox(height: 20),
                          Text(widget.title,
                              style: const TextStyle(color: Palette.onInk, fontSize: 36, fontWeight: FontWeight.w700, height: 1.1)),
                          const SizedBox(height: 6),
                          Text(widget.subtitle, style: const TextStyle(color: Palette.onInkMuted, fontSize: 16)),
                        ]),
                      ),
                    ),
                    Reveal(
                      delay: Motion.stagger(1),
                      rise: 60,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                        decoration: const BoxDecoration(
                          color: Palette.cream,
                          borderRadius: BorderRadius.all(Radius.circular(32)),
                        ),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? 'Show password' : 'Hide password',
                                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(onPressed: _forgot, child: const Text('Forgot password?')),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _busy ? null : _submit,
                                child: AnimatedSwitcher(
                                  duration: Motion.fast,
                                  child: _busy
                                      ? const ButtonSpinner(key: ValueKey('busy'))
                                      : const Text('Sign in', key: ValueKey('label')),
                                ),
                              ),
                              if (widget.onRegister != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account?"),
                                    TextButton(onPressed: widget.onRegister, child: const Text('Create one')),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
