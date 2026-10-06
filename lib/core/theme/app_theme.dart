import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brandGold,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.brandGold,
          onPrimary: AppColors.brandForest,
          secondary: AppColors.brandForest,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.brandForest,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.brandForest,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brandGold, width: 1.4),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.brandForest,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        titleMedium: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: AppColors.brandForest,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: AppColors.mutedText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: AppColors.brandForest,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
