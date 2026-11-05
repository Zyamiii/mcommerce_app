import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/theme.dart';
import 'motion.dart';

class ProductImage extends StatelessWidget {
  final String url;
  final double? size;
  final BorderRadius radius;

  const ProductImage(this.url, {super.key, this.size, this.radius = const BorderRadius.all(Radius.circular(14))});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Palette.oliveTint.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Palette.muted),
    );
    return ClipRRect(
      borderRadius: radius,
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Many image hosts block direct web requests (CORS). This falls
              // back to a browser <img> element so those images still show.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => placeholder,
              // The picture fades in over its placeholder once it has loaded.
              frameBuilder: (_, child, frame, loadedAtOnce) {
                if (loadedAtOnce) return child;
                return AnimatedSwitcher(
                  duration: Motion.base,
                  layoutBuilder: (current, previous) => Stack(
                    fit: size == null ? StackFit.expand : StackFit.loose,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(key: ValueKey(frame != null), child: frame == null ? placeholder : child),
                );
              },
            ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  static Color colorFor(String status) => switch (status) {
        OrderStatus.pending => const Color(0xFF9A6410),
        OrderStatus.processing => const Color(0xFF2F6F9F),
        OrderStatus.shipped => const Color(0xFF5B5AA8),
        OrderStatus.delivered => Palette.oliveDeep,
        OrderStatus.cancelled => Palette.clay,
        _ => Palette.muted,
      };

  static IconData iconFor(String status) => switch (status) {
        OrderStatus.pending => Icons.hourglass_top_rounded,
        OrderStatus.processing => Icons.inventory_2_outlined,
        OrderStatus.shipped => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.check_circle_outline,
        OrderStatus.cancelled => Icons.cancel_outlined,
        _ => Icons.receipt_long_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final c = colorFor(status);
    return AnimatedContainer(
      duration: Motion.base,
      curve: Motion.curve,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedSwitcher(
        duration: Motion.base,
        child: Text(
          OrderStatus.label(status),
          key: ValueKey(status),
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Reveal(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(color: Palette.oliveTint, borderRadius: BorderRadius.circular(32)),
                child: Icon(icon, size: 48, color: Palette.oliveDeep),
              ),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Palette.muted, fontSize: 15)),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final Object error;
  const ErrorView(this.error, {super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: error.toString(),
      );
}

/// The rounded panel that holds a page's main action at the bottom.
class BottomDock extends StatelessWidget {
  final Widget child;
  const BottomDock({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Palette.ink.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 16), child: child),
      ),
    );
  }
}

/// A heading above a block of content.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(children: [
        Expanded(child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        ?trailing,
      ]),
    );
  }
}

/// A rounded icon square, used at the start of list rows.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const IconTile(this.icon, {super.key, this.color = Palette.oliveDeep, this.background = Palette.oliveTint, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.base,
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Shows while a button's action is running.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Palette.ink),
      );
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Palette.clay : null,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Shown when lib/firebase_options.dart is still the placeholder.
class FirebaseSetupError extends StatelessWidget {
  final Object error;
  const FirebaseSetupError(this.error, {super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: EmptyState(
            icon: Icons.cloud_off,
            title: 'Firebase is not configured',
            message: '$error',
          ),
        ),
      );
}
