import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/session_provider.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/users_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';

class _Dest {
  final String label;
  final IconData icon;
  final IconData selected;
  const _Dest(this.label, this.icon, this.selected);
}

const _dests = [
  _Dest('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  _Dest('Products', Icons.inventory_2_outlined, Icons.inventory_2),
  _Dest('Categories', Icons.category_outlined, Icons.category),
  _Dest('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
  _Dest('Users', Icons.people_outline, Icons.people),
];

/// Responsive layout: side rail on wide screens, drawer on narrow ones.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  Widget _page() => switch (_index) {
        0 => DashboardScreen(onNavigate: _goTo),
        1 => const ProductsScreen(),
        2 => const CategoriesScreen(),
        3 => const AdminOrdersScreen(),
        _ => const UsersScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final profile = context.watch<Session>().profile!;
    final scheme = Theme.of(context).colorScheme;

    final account = PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (v) {
        if (v == 'logout') context.read<AuthService>().signOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text(profile.email)),
        const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out'))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Text(profile.name.isEmpty ? 'A' : profile.name[0].toUpperCase()),
          ),
          if (wide) ...[const SizedBox(width: 8), Text(profile.name.isEmpty ? 'Admin' : profile.name)],
          const Icon(Icons.arrow_drop_down),
        ]),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.shopping_bag, color: scheme.primary),
          const SizedBox(width: 8),
          const Text('ShopEase Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [account],
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      drawer: wide
          ? null
          : NavigationDrawer(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                Navigator.of(context).pop();
                _goTo(i);
              },
              children: [
                const SizedBox(height: 16),
                for (final d in _dests)
                  NavigationDrawerDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: Text(d.label)),
              ],
            ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              selectedIndex: _index,
              onDestinationSelected: _goTo,
              labelType: MediaQuery.sizeOf(context).width >= 1200 ? null : NavigationRailLabelType.all,
              destinations: [
                for (final d in _dests)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: Text(d.label)),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(child: _page()),
        ],
      ),
    );
  }
}
