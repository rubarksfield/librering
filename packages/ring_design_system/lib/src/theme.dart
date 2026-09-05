import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

import 'tokens.dart';

ThemeData buildLibreRingTheme() {
  const display = TextStyle(
    fontFamily: 'Helvetica Neue',
    fontFamilyFallback: <String>['Arial', 'sans-serif'],
    fontWeight: FontWeight.w400,
    color: LibreRingTokens.foreground,
    letterSpacing: -1.0,
  );

  final scheme =
      ColorScheme.fromSeed(
        seedColor: LibreRingTokens.accent,
        brightness: Brightness.light,
        surface: LibreRingTokens.background,
      ).copyWith(
        primary: LibreRingTokens.foreground,
        onPrimary: LibreRingTokens.onForeground,
        secondary: LibreRingTokens.accent,
        onSecondary: LibreRingTokens.onForeground,
        surface: LibreRingTokens.background,
        onSurface: LibreRingTokens.foreground,
        outline: LibreRingTokens.border,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: LibreRingTokens.background,
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: const DividerThemeData(
      color: LibreRingTokens.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LibreRingTokens.surface,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LibreRingTokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LibreRingTokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: LibreRingTokens.sage, width: 2),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: const WidgetStatePropertyAll(
          LibreRingTokens.foreground,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? LibreRingTokens.sageSoft
              : Colors.transparent,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: LibreRingTokens.border),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: LibreRingTokens.foreground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LibreRingTokens.background,
      showDragHandle: true,
      modalBarrierColor: Color(0x55202822),
    ),
    fontFamily: 'Helvetica Neue',
    fontFamilyFallback: const <String>['Arial', 'sans-serif'],
    textTheme: const TextTheme(
      displayLarge: display,
      displayMedium: display,
      headlineLarge: display,
      headlineMedium: display,
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: LibreRingTokens.foreground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: LibreRingTokens.foreground,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: LibreRingTokens.foreground,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: LibreRingTokens.muted,
        height: 1.45,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
