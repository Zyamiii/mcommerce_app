import 'package:flutter/material.dart';

import '../../utils/theme.dart';
import '../../widgets/motion.dart';

/// Page heading with optional actions on the right.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Reveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 12,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15)),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Palette.muted, fontSize: 15)),
            ]),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

/// A figure on the dashboard. It lifts on hover, and [count] makes the number
/// count up to its value.
class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final double? count;
  final String Function(double)? format;
  final IconData icon;
  final bool featured;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.count,
    this.format,
    required this.icon,
    this.featured = false,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final featured = widget.featured;
    final valueStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: featured ? Palette.onInk : Palette.ink,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Pressable(
        onTap: widget.onTap,
        label: widget.label,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.curve,
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: featured ? Palette.ink : Palette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: featured ? Palette.ink : (_hover ? Palette.olive : Palette.line)),
            boxShadow: _hover
                ? [BoxShadow(color: Palette.ink.withValues(alpha: 0.1), blurRadius: 18, offset: const Offset(0, 8))]
                : const [],
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: featured ? Palette.olive : Palette.oliveTint,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(widget.icon, color: featured ? Palette.ink : Palette.oliveDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.label,
                    style: TextStyle(color: featured ? Palette.onInkMuted : Palette.muted, fontSize: 14)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: widget.count != null && widget.format != null
                      ? CountUp(value: widget.count!, format: widget.format!, style: valueStyle)
                      : Text(widget.value, style: valueStyle),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A Card holding a horizontally scrollable DataTable that fills the width.
///
/// The scrollbar stays visible because a mouse wheel only scrolls vertically
/// on web, so it is how a mouse user reaches columns past the right edge.
class TableCard extends StatefulWidget {
  final DataTable table;
  const TableCard({super.key, required this.table});

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Reveal(
      delay: Motion.stagger(1),
      child: Card(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) => Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              // Keeps the scrollbar from covering the last row.
              padding: const EdgeInsets.only(bottom: 12),
              child: ConstrainedBox(constraints: BoxConstraints(minWidth: c.maxWidth), child: widget.table),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirm(BuildContext context, String title, String message, {String action = 'Delete', String dismiss = 'Cancel'}) async {
  final ok = await showAppDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(dismiss)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Palette.clay, foregroundColor: Palette.onInk),
          onPressed: () => Navigator.pop(c, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
