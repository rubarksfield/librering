import 'package:flutter/material.dart';

abstract final class LibreRingTokens {
  static const background = Color(0xFFF6F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF202822);
  static const muted = Color(0xFF626A63);
  static const border = Color(0xFFE3E6DF);
  static const accent = Color(0xFFBF553D);
  static const accentSoft = Color(0xFFF8E9E3);
  static const sage = Color(0xFF62806A);
  static const sageSoft = Color(0xFFE8EEE5);
  static const onForeground = Color(0xFFFFFFFF);
  static const soft = Color(0xFFEFF0EB);

  static const double contentInset = 24;
  static const double controlRadius = 16;
  static const double cardRadius = 24;
  static const double minimumTarget = 48;

  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);
  static const curve = Cubic(0.2, 0, 0, 1);
}
