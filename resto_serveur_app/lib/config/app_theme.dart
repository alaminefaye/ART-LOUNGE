import 'package:flutter/material.dart';

/// Brand colors and theme for Serveur app
class AppTheme {
  AppTheme._();

  // Brand colors (same as resto-app)
  static const Color brandGold = Color(0xFFD0A030);
  static const Color brandGoldLight = Color(0xFFE0B040);
  static const Color brandGoldDark = Color(0xFFA07010);
  static const Color scaffoldBg = Color(0xFFFFF6EC);
  static const Color cardBg = Colors.white;

  // Accent colors for waiter app (darker/professional feel)
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkAccent = Color(0xFF0F3460);

  // Status colors
  static const Color statusLibre = Color(0xFF4CAF50);
  static const Color statusOccupee = Color(0xFFF44336);
  static const Color statusReservee = Color(0xFFFF9800);
  static const Color statusEnPaiement = Color(0xFF2196F3);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandGold,
        brightness: Brightness.light,
        primary: brandGold,
        secondary: brandGoldLight,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: brandGold, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class AppBrand {
  AppBrand._();
  static const String displayName = 'Dolce Vita Palace';
  static const String appName = 'Serveur - Dolce Vita';
}
