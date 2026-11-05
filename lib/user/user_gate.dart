import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../screens/login_screen.dart';
import '../widgets/common_widgets.dart';
import 'main_shell.dart';
import '../screens/register_screen.dart';

/// Decides what the user sees: splash → login → main app.
class UserGate extends StatelessWidget {
  const UserGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();

    if (session.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.signedIn) {
      return LoginScreen(
        title: 'ShopEase',
        subtitle: 'Sign in to start shopping',
        onRegister: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
      );
    }
    if (session.profileError != null) {
      return Scaffold(body: ErrorView(session.profileError!));
    }
    if (session.profile == null) {
      return const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Setting up your account…'),
          ]),
        ),
      );
    }
    return const MainShell();
  }
}
