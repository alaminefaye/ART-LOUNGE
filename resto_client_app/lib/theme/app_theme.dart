import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandGold = Color(0xFF191F76);
  static const Color brandGoldLight = Color(0xFF2E36A3);
  static const Color accent = Color(0xFFFF6A3D);
  static const Color bgTop = Color(0xFF0B1029);
  static const Color bgBottom = Color(0xFF0F1A3C);
  static const Color surface = Color(0xFF121B3A);
  static const Color surface2 = Color(0xFF16214A);
  static const Color text = Color(0xFFF4F6FF);
  static const Color textMuted = Color(0xFF9AA3B2);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgTop,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandGold,
        brightness: Brightness.dark,
        primary: brandGold,
        secondary: brandGoldLight,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: brandGoldLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: textMuted),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w800),
      ),
    );
  }
}
