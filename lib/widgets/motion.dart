import 'package:flutter/material.dart';

/// Shared timing, so every animation in the app feels like one family.
class Motion {
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;

  /// Time between items when a list appears one after another.
  static Duration stagger(int index) => Duration(milliseconds: 45 * index.clamp(0, 8));
}

/// Fades a child in while it rises into place. Plays once, after [delay].
/// It is skipped when the phone's "remove animations" setting is on.
class Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double rise;

  const Reveal({super.key, required this.child, this.delay = Duration.zero, this.rise = 18});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: Motion.slow);
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Motion.curve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: Offset(0, widget.rise * (1 - _curve.value)), child: child),
      ),
    );
  }
}

/// Shrinks slightly under the finger, then springs back.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? label;

  const Pressable({super.key, required this.child, this.onTap, this.pressedScale = 0.97, this.label});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.label,
      child: MouseRegion(
        cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          child: AnimatedScale(
            scale: _down ? widget.pressedScale : 1,
            duration: Motion.fast,
            curve: Curves.easeOutBack,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A number that counts to its new value instead of jumping there.
class CountUp extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;

  const CountUp({super.key, required this.value, required this.format, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Motion.slow,
      curve: Motion.curve,
      builder: (_, v, _) => Text(format(v), style: style),
    );
  }
}

/// Swaps a child with a quick pop, for badges and small labels.
class PopSwitcher extends StatelessWidget {
  final Widget child;
  const PopSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
      child: child,
    );
  }
}

/// Dialogs open with a soft scale instead of appearing at once.
Future<T?> showAppDialog<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Motion.base,
    pageBuilder: (c, _, _) => SafeArea(child: Builder(builder: builder)),
    transitionBuilder: (_, animation, _, child) {
      final a = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween<double>(begin: 0.93, end: 1).animate(a), child: child),
      );
    },
  );
}
