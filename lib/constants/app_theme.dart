import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1A3A5C);
  static const accent = Color(0xFFE63946);
  static const success = Color(0xFF2D9E6B);
  static const warning = Color(0xFFE9A63D);
  static const background = Color(0xFFF5F5F0);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF1C1C1E);
  static const textMuted = Color(0xFF8E8E93);
  static const highSeverity = Color(0xFFE63946);
  static const medSeverity = Color(0xFFE9A63D);
  static const lowSeverity = Color(0xFF2D9E6B);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cardBg,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.cardBg,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

Color severityColor(String severity) {
  switch (severity) {
    case 'High':
      return AppColors.highSeverity;
    case 'Medium':
      return AppColors.medSeverity;
    case 'Low':
      return AppColors.lowSeverity;
    default:
      return AppColors.textMuted;
  }
}

String severityLabel(String severity) {
  switch (severity) {
    case 'High':
      return 'รุนแรงมาก';
    case 'Medium':
      return 'ปานกลาง';
    case 'Low':
      return 'น้อย';
    default:
      return severity;
  }
}
