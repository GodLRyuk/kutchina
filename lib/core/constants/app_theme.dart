import 'package:flutter/material.dart';

class AppColors {
  static const Color red = Color(0xFFC8102E);
  static const Color redDark = Color(0xFF8F0B21);
  static const Color redLight = Color(0xFFF7DEE2);
  static const Color amber = Color(0xFFF2A93B);
  static const Color amberLight = Color(0xFFFBEACB);
  static const Color amberDark = Color(0xFF8A5C0E);
  static const Color charcoal = Color(0xFF24262B);
  static const Color ink = Color(0xFF33343A);
  static const Color steel = Color(0xFF6B7280);
  static const Color steelLight = Color(0xFF9CA3AF);
  static const Color ash = Color(0xFFF4F3F0);
  static const Color paper = Color(0xFFFBFAF8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF1F9D55);
  static const Color greenLight = Color(0xFFDEF3E5);
  static const Color line = Color(0xFFE7E4DE);

  // AI-layer accent used across dashboard / leads / MIS cards
  static const Color aiBlue = Color(0xFF5B8DEF);
  static const Color aiBlueBg = Color(0xFFF3F6FD);
  static const Color aiBlueBorder = Color(0xFFDCE5FA);
  static const Color aiBlueChipBg = Color(0xFFE7EDFC);

  static const Color coldBg = Color(0xFFE7EAF0);
  static const Color coldText = Color(0xFF4A5568);
}

class AppRadius {
  static const double lg = 22;
  static const double md = 14;
  static const double sm = 9;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.red,
      scaffoldBackgroundColor: AppColors.ash,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.red,
        primary: AppColors.red,
        secondary: AppColors.amber,
        surface: AppColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
