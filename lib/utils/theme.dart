import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The ShopEase palette: charcoal, olive and warm cream.
class Palette {
  static const ink = Color(0xFF2A2B26);
  static const inkSoft = Color(0xFF3B3D35);
  static const olive = Color(0xFFB7BC5E);
  static const oliveDeep = Color(0xFF666C2A);
  static const oliveTint = Color(0xFFEAECCB);
  static const cream = Color(0xFFF6F5EC);
  static const card = Color(0xFFFFFEF9);
  static const line = Color(0xFFE6E4D6);
  static const muted = Color(0xFF6F7065);
  static const onInk = Color(0xFFF3F2E6);
  static const onInkMuted = Color(0xFFBDBEAE);
  static const clay = Color(0xFFB5472F);
}

/// Slides a new page up slightly while it fades in, and eases the old page back.
class GlideTransitionsBuilder extends PageTransitionsBuilder {
  const GlideTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final leave = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(enter),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1, end: 0.97).animate(leave),
          child: child,
        ),
      ),
    );
  }
}

class AppTheme {
  static const _radius = 18.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: Palette.olive).copyWith(
      primary: Palette.oliveDeep,
      onPrimary: Palette.onInk,
      primaryContainer: Palette.oliveTint,
      onPrimaryContainer: Palette.ink,
      secondary: Palette.oliveDeep,
      secondaryContainer: Palette.oliveTint,
      onSecondaryContainer: Palette.ink,
      surface: Palette.card,
      onSurface: Palette.ink,
      onSurfaceVariant: Palette.muted,
      surfaceContainerHighest: Palette.line,
      outline: Palette.muted,
      outlineVariant: Palette.line,
      error: Palette.clay,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: Palette.line),
    );

    const transitions = GlideTransitionsBuilder();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Barlow',
      scaffoldBackgroundColor: Palette.cream,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.iOS: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.macOS: transitions,
        TargetPlatform.linux: transitions,
      }),
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.ink,
        foregroundColor: Palette.onInk,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'Barlow',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Palette.onInk,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Palette.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Palette.line, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Palette.oliveDeep, width: 1.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.olive,
          foregroundColor: Palette.ink,
          disabledBackgroundColor: Palette.line,
          disabledForegroundColor: Palette.muted,
          minimumSize: const Size(64, 56),
          textStyle: const TextStyle(fontFamily: 'Barlow', fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.ink,
          minimumSize: const Size(64, 56),
          side: const BorderSide(color: Palette.line, width: 1.4),
          textStyle: const TextStyle(fontFamily: 'Barlow', fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.oliveDeep,
          textStyle: const TextStyle(fontFamily: 'Barlow', fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Palette.card,
        selectedColor: Palette.olive,
        side: const BorderSide(color: Palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(fontFamily: 'Barlow', fontWeight: FontWeight.w500, color: Palette.ink),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Palette.olive : Palette.line),
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Palette.ink : Palette.muted),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Palette.olive : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(Palette.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(Palette.cream),
        headingTextStyle: const TextStyle(fontFamily: 'Barlow', fontWeight: FontWeight.w600, color: Palette.ink),
        dividerThickness: 1,
        dataRowColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? Palette.oliveTint.withValues(alpha: 0.45) : null,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Palette.line,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Palette.ink,
        contentTextStyle: const TextStyle(fontFamily: 'Barlow', color: Palette.onInk, fontSize: 15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Palette.oliveDeep),
      popupMenuTheme: PopupMenuThemeData(
        color: Palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(Palette.muted.withValues(alpha: 0.45)),
      ),
    );
  }
}
