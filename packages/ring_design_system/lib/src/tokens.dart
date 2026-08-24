import 'package:flutter/material.dart';

abstract final class LibreRingTokens {
  static const background = Color(0xFFF4F1EA);
  static const surface = Color(0xFFE4E2DE);
  static const foreground = Color(0xFF171714);
  static const muted = Color(0xFF64625B);
  static const border = Color(0xFFD1CEC7);
  static const accent = Color(0xFFC9573E);
  static const onForeground = Color(0xFFFFFFFF);
  static const soft = Color(0xFFFAF8F3);

  static const double contentInset = 24;
  static const double controlRadius = 14;
  static const double cardRadius = 16;
  static const double minimumTarget = 48;

  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);
  static const curve = Cubic(0.2, 0, 0, 1);
}
