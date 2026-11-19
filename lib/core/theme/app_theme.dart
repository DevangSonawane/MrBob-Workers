import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    // Poppins carries the product's personality for display/UI text, while
    // Inter keeps supporting copy compact and highly legible.
    final poppins = GoogleFonts.poppinsTextTheme();
    final inter = GoogleFonts.interTextTheme();
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
      fontFamily: GoogleFonts.poppins().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: poppins.titleLarge?.copyWith(
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
        hintStyle: inter.bodyMedium?.copyWith(
          color: AppColors.mutedText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: inter.bodyMedium?.copyWith(
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
      // Vendor-only controls, tuned to the same palette as the client app.
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandForest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandTeal
              : null,
        ),
      ),
      textTheme: poppins.copyWith(
        titleLarge: poppins.titleLarge?.copyWith(
          color: AppColors.brandForest,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.2,
        ),
        titleMedium: poppins.titleMedium?.copyWith(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        bodyLarge: inter.bodyLarge?.copyWith(
          color: AppColors.brandForest,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: inter.bodyMedium?.copyWith(
          color: AppColors.mutedText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        labelLarge: inter.labelLarge?.copyWith(
          color: AppColors.brandForest,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
