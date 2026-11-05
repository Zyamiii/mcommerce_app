import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/session_provider.dart';
import '../screens/login_screen.dart';
import '../widgets/common_widgets.dart';
import 'admin_shell.dart';

/// Only users whose users/{uid}.role == 'admin' get past this gate.
/// (Firestore rules enforce the same check server-side.)
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();

    if (session.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!session.signedIn) {
      return const LoginScreen(
        title: 'ShopEase Admin',
        subtitle: 'Sign in with an administrator account',
        icon: Icons.admin_panel_settings_outlined,
      );
    }
    if (!session.profileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session.profileError != null || session.profile?.isAdmin != true) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Access denied',
          message: '${session.authUser?.email} is not an administrator.\n'
              'Ask an administrator for access.',
          action: FilledButton(
            onPressed: () => context.read<AuthService>().signOut(),
            child: const Text('Sign out'),
          ),
        ),
      );
    }
    return const AdminShell();
  }
}
