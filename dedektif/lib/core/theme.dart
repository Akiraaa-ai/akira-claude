import 'package:flutter/material.dart';

/// Noir tonlarında koyu tema.
class AppTheme {
  static const ink = Color(0xFF0E1116);
  static const paper = Color(0xFFE9E1CF);
  static const brass = Color(0xFFC9A45C);
  static const blood = Color(0xFFA33B3B);

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brass,
      brightness: Brightness.dark,
      surface: const Color(0xFF161B22),
      primary: brass,
      error: blood,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: ink,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B2129),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: paper,
        displayColor: paper,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brass,
          foregroundColor: ink,
          minimumSize: const Size(200, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
