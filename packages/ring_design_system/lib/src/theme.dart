import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildLibreRingTheme() {
  const display = TextStyle(
    fontFamily: 'Helvetica Neue',
    fontFamilyFallback: <String>['Arial', 'sans-serif'],
    fontWeight: FontWeight.w300,
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
    splashFactory: NoSplash.splashFactory,
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
      bodyLarge: TextStyle(color: LibreRingTokens.foreground, height: 1.5),
      bodyMedium: TextStyle(color: LibreRingTokens.foreground, height: 1.45),
      bodySmall: TextStyle(color: LibreRingTokens.muted, height: 1.4),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
