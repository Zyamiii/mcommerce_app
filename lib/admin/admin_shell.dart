import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';
import '../widgets/motion.dart';
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

/// Responsive layout: a dark sidebar on wide screens, a drawer on narrow ones.
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
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final extended = width >= 1200;
    final profile = context.watch<Session>().profile!;

    final page = AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.curve,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_index), child: _page()),
    );

    if (wide) {
      return Scaffold(
        body: Row(children: [
          _Sidebar(index: _index, extended: extended, profileName: profile.name, email: profile.email, onTap: _goTo),
          Expanded(child: page),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ShopEase Admin')),
      drawer: Drawer(
        backgroundColor: Palette.ink,
        child: _Sidebar(
          index: _index,
          extended: true,
          profileName: profile.name,
          email: profile.email,
          onTap: (i) {
            Navigator.of(context).pop();
            _goTo(i);
          },
        ),
      ),
      body: page,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int index;
  final bool extended;
  final String profileName;
  final String email;
  final ValueChanged<int> onTap;

  const _Sidebar({required this.index, required this.extended, required this.profileName, required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = profileName.isEmpty ? 'Admin' : profileName;
    return AnimatedContainer(
      duration: Motion.base,
      curve: Motion.curve,
      width: extended ? 256 : 92,
      color: Palette.ink,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.shopping_bag_rounded, color: Palette.ink),
              ),
              if (extended) ...[
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('ShopEase Admin',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Palette.onInk, fontSize: 19, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 28),
            Expanded(
              child: Stack(children: [
                AnimatedPositioned(
                  duration: Motion.base,
                  curve: Curves.easeOutBack,
                  top: index * _NavTile.height,
                  left: 0,
                  right: 0,
                  height: _NavTile.height - 6,
                  child: Container(
                    decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                Column(children: [
                  for (var i = 0; i < _dests.length; i++)
                    _NavTile(dest: _dests[i], selected: i == index, extended: extended, onTap: () => onTap(i)),
                ]),
              ]),
            ),
            PopupMenuButton<String>(
              tooltip: 'Account',
              position: PopupMenuPosition.over,
              onSelected: (v) {
                if (v == 'logout') context.read<AuthService>().signOut();
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(email)),
                const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout_rounded), title: Text('Sign out'))),
              ],
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Palette.inkSoft, borderRadius: BorderRadius.circular(18)),
                child: Row(mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(name[0].toUpperCase(),
                        style: const TextStyle(color: Palette.ink, fontWeight: FontWeight.w700)),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(name, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Palette.onInk, fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.unfold_more_rounded, color: Palette.onInkMuted, size: 20),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  static const height = 60.0;

  final _Dest dest;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _NavTile({required this.dest, required this.selected, required this.extended, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Palette.ink : Palette.onInkMuted;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Tooltip(
          message: extended ? '' : dest.label,
          child: Pressable(
            onTap: onTap,
            pressedScale: 0.96,
            label: dest.label,
            child: Row(
              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (extended) const SizedBox(width: 16),
                AnimatedSwitcher(
                  duration: Motion.fast,
                  child: Icon(selected ? dest.selected : dest.icon, key: ValueKey(selected), color: color),
                ),
                if (extended) ...[
                  const SizedBox(width: 14),
                  AnimatedDefaultTextStyle(
                    duration: Motion.fast,
                    style: TextStyle(
                      fontFamily: 'Barlow',
                      color: color,
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(dest.label),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
