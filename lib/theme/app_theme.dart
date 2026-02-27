import 'package:flutter/material.dart';

class AppTheme {
  static const Color purpleAccent = Color(0xFFF2B95B);
  static const Color tealAccent = Color(0xFF14B8A6);
  static const Color primaryNavy = Color(0xFF0F1B4C);
  static const Color skyAccent = Color(0xFF4CB7D8);
  static const Color ink = Color(0xFF0F172A);
  static const Color cloud = Color(0xFFF8FAFC);
  static const Color mist = Color(0xFFEFF6FF);
  static const double radiusLg = 22;
  static const double radius = 18;
  static const double radiusSm = 14;
  static const double radiusXs = 12;
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 10,
      offset: Offset(0, 6),
    ),
  ];

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.blueGrey.shade300
          : Colors.blueGrey.shade600;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.grey.shade200;
}
