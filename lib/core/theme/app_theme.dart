import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: AppTokens.textPrimary,
      displayColor: AppTokens.textPrimary,
    );
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppTokens.cyan500,
        onPrimary: Colors.white,
        secondary: AppTokens.navy800,
        onSecondary: Colors.white,
        surface: AppTokens.card,
        onSurface: AppTokens.textPrimary,
        error: AppTokens.red,
      ),
      scaffoldBackgroundColor: AppTokens.bg,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppTokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r14),
          side: const BorderSide(color: AppTokens.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
          borderSide: const BorderSide(color: AppTokens.cyan500, width: 1.6),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.cyan500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r10),
          ),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.navy800,
          side: const BorderSide(color: AppTokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r10),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppTokens.border,
        thickness: 1,
        space: AppTokens.s16,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.navy800,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
        ),
      ),
    );
  }

  static ThemeData dark() {
    // Placeholder — RTL admin is light by spec, leave dark minimal.
    return light();
  }
}
