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
  static const Color pink = Color(0xFFF6A7EB);
  static const Color black = Color(0xFF000000);

  // AI-layer accent used across dashboard / leads / MIS cards
  static const Color aiBlue = Color(0xFF5B8DEF);
  static const Color aiBlueBg = Color(0xFFF3F6FD);
  static const Color aiBlueBorder = Color(0xFFDCE5FA);
  static const Color aiBlueChipBg = Color(0xFFE7EDFC);

  static const Color coldBg = Color(0xFFE7EAF0);
  static const Color coldText = Color(0xFF4A5568);

  // ---------------- Sales Command Centre / MIS dashboard ----------------
  static const Color notificationDot = Color(0xFFFF0E1F);
  static const Color commandCentreText = Color(0xFF091452);

  static const Color rupeeIconBg = Color(0xFFCEDFFD);
  static const Color dayEndIconBg = Color(0xFF01B5C4);
  static const Color achievementIconBg = Color(0xFF7D44E1);
  static const Color aiIconBg = Color(0xFF02AFC0);

  // High performers row
  static const Color highPerformersBg = Color(0xFF003988);
  static const Color topAreaBg = Color(0xFF2F7FFA);
  static const Color topProductBg = Color(0xFF01B4CA);
  static const Color topSalespersonBg = Color(0xFFFFAB06);

  // Sales by product — progress bar colors
  static const Color productChimney = Color(0xFF1569ED);
  static const Color productHobs = Color(0xFFFF447E);
  static const Color productWaterPurifiers = Color(0xFF0EACC5);
  static const Color productOvens = Color(0xFFFE8D31);

  // Sales by region chart
  static const Color regionOrange = Color(0xFFFD8427);
  static const Color regionBlue = Color(0xFF216CE9);
  static const Color regionPurple = Color(0xFF7C48DB);
  static const Color regionCyan = Color(0xFF00B1C5);

  // Sales team performance
  static const Color viewAllButton = Color(0xFF4175E2);
  static const Color avatarBg1 = Color(0xFFDCE5FF);
  static const Color avatarBg2 = Color(0xFFE9E1F9);
  static const Color avatarBg3 = Color(0xFFD9F2F9);

  static const Color salesTodayColumn = Color(0xFF00B9C8);
  static const Color salesThisMonthColumn = Color(0xFF1654CD);

  // Bottom nav
  static const Color navActive = Color(0xFF003688);
  static const Color navNormal = Color(0xFF555D70);
}

class AppRadius {
  static const double lg = 22;
  static const double md = 14;
  static const double sm = 9;
}

/// Font family names used across the app. Reference these instead of
/// hardcoding 'Sora' / 'Inter' / 'IBM Plex Mono' strings in every screen.
class AppFonts {
  AppFonts._();

  /// Headings, buttons, labels, numbers-as-titles.
  static const String display = 'Sora';

  /// Body copy, form fields, descriptions — the ThemeData default.
  static const String body = 'Inter';

  /// Currency, order IDs, timestamps, anything tabular/monospaced.
  static const String mono = 'IBM Plex Mono';
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.red,
      scaffoldBackgroundColor: AppColors.ash,
      fontFamily: AppFonts.body,
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
      textTheme: const TextTheme(
        // Screen titles ("New order", "Visit check-in", etc.)
        titleLarge: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
        // Card headers, section labels ("Today's visits", "CATEGORY")
        titleSmall: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
        // Regular body copy
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          color: AppColors.steel,
        ),
        // Prices, order IDs, timestamps
        labelLarge: TextStyle(
          fontFamily: AppFonts.mono,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
