import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../screens/cart_screen.dart';
import '../screens/home_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/theme.dart';
import '../widgets/motion.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _index = 0;

  // Replays a soft fade each time the tab changes. The tabs stay alive in the
  // stack, so scroll positions and the cart are kept.
  late final AnimationController _fade = AnimationController(vsync: this, duration: Motion.base, value: 1);

  void _goTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<Session, int>((s) => s.cartCount);
    final eased = CurvedAnimation(parent: _fade, curve: Motion.curve);

    return Scaffold(
      body: FadeTransition(
        opacity: eased,
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onOpenCart: () => _goTo(1)),
            CartScreen(onBrowse: () => _goTo(0)),
            OrdersScreen(onBrowse: () => _goTo(0)),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _GlideNav(index: _index, cartCount: cartCount, onTap: _goTo),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selected;
  const _NavItem(this.label, this.icon, this.selected);
}

const _items = [
  _NavItem('Shop', Icons.storefront_outlined, Icons.storefront),
  _NavItem('Cart', Icons.shopping_bag_outlined, Icons.shopping_bag),
  _NavItem('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
  _NavItem('Profile', Icons.person_outline, Icons.person),
];

/// A floating dark bar with an olive highlight that glides between tabs.
class _GlideNav extends StatelessWidget {
  final int index;
  final int cartCount;
  final ValueChanged<int> onTap;

  const _GlideNav({required this.index, required this.cartCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Palette.ink,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: Palette.ink.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth / _items.length;
              return Stack(children: [
                AnimatedPositioned(
                  duration: Motion.base,
                  curve: Curves.easeOutBack,
                  left: width * index,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: Container(
                    decoration: BoxDecoration(color: Palette.olive, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                Row(children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: _items[i],
                        selected: i == index,
                        badge: i == 1 ? cartCount : 0,
                        onTap: () => onTap(i),
                      ),
                    ),
                ]),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Palette.ink : Palette.onInkMuted;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      label: item.label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(clipBehavior: Clip.none, children: [
            AnimatedSwitcher(
              duration: Motion.fast,
              child: Icon(selected ? item.selected : item.icon, key: ValueKey(selected), color: color, size: 24),
            ),
            Positioned(
              right: -9,
              top: -6,
              child: PopSwitcher(
                child: badge == 0
                    ? const SizedBox.shrink(key: ValueKey(0))
                    : Container(
                        key: ValueKey(badge),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(color: Palette.clay, borderRadius: BorderRadius.circular(10)),
                        child: Text('$badge',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Palette.onInk, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
              ),
            ),
          ]),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: Motion.fast,
            style: TextStyle(
              fontFamily: 'Barlow',
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
