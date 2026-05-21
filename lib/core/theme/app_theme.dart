import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dark_tokens.dart';
import 'tokens.dart';

/// Premium-purple ThemeData matching the web `hub_v2` design system.
///
/// Single light theme — no dark mode (RTL admin is light-only by spec).
/// All component themes route their accent through [AppTokens.brand].
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
        primary: AppTokens.brand,
        onPrimary: Colors.white,
        primaryContainer: AppTokens.brandSoft,
        onPrimaryContainer: AppTokens.brandInk,
        secondary: AppTokens.brandInk,
        onSecondary: Colors.white,
        surface: AppTokens.card,
        onSurface: AppTokens.textPrimary,
        surfaceContainerHighest: AppTokens.soft,
        outline: AppTokens.border,
        outlineVariant: AppTokens.borderSoft,
        error: AppTokens.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppTokens.bg,
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: AppTokens.textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(color: AppTokens.textMuted),
      ),

      // ── Cards ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppTokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r18),
          side: const BorderSide(color: AppTokens.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Inputs ──────────────────────────────────────────────
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
          borderSide: const BorderSide(color: AppTokens.brand, width: 1.6),
        ),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: AppTokens.textFaint),
      ),

      // ── Buttons ─────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r10),
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          elevation: 0,
        ).copyWith(
          // Hover: brandDeep
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return AppTokens.brandDeep.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.brandInk,
          side: const BorderSide(color: AppTokens.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r10),
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.brandInk,
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r10),
          ),
          textStyle:
              textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),

      // ── App bar (top bar) ───────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: AppTokens.border)),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTokens.textPrimary,
        ),
      ),

      // ── Chips ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.brandSoft,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppTokens.brandInk,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: AppTokens.brandLine),
        shape: const StadiumBorder(),
      ),

      // ── Dialogs ─────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r18),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTokens.textPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppTokens.textSecondary,
        ),
      ),

      // ── Dividers ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppTokens.border,
        thickness: 1,
        space: AppTokens.s16,
      ),

      // ── Snackbar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r10),
        ),
      ),

      // ── Tabs ────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppTokens.brandInk,
        unselectedLabelColor: AppTokens.textMuted,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppTokens.brand, width: 3),
        ),
      ),

      // ── Bottom nav (mobile) ─────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppTokens.brandSoft,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(
            color: AppTokens.brandInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppTokens.brandInk);
          }
          return const IconThemeData(color: AppTokens.textMuted);
        }),
      ),

      // ── Floating action button ─────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppTokens.brand,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r14),
        ),
      ),

      // ── Switches & checkboxes ──────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppTokens.brand;
          return AppTokens.borderStrong;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppTokens.brand;
          return Colors.white;
        }),
        side: const BorderSide(color: AppTokens.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppTokens.brand;
          return AppTokens.borderStrong;
        }),
      ),

      // ── Progress indicators ────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.brand,
        linearTrackColor: AppTokens.borderSoft,
        circularTrackColor: AppTokens.borderSoft,
      ),
    );
  }

  /// Production-grade dark mode (J1.5).
  ///
  /// Mirrors [light]'s ColorScheme + typography but uses the [DarkTokens]
  /// palette so canonical widgets that read from
  /// `Theme.of(context).colorScheme` or `AppPalette.of(context)` recolor
  /// correctly.
  ///
  /// Note: existing widgets that reference `AppTokens.X` directly still
  /// render with their light values under this theme — those will get
  /// their context-aware lookups added during J3 (decomposition) and
  /// J4 (per-feature redesign). See FLUTTER_REDESIGN_PLAN.md §J1.5.
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: DarkTokens.textPrimary,
      displayColor: DarkTokens.textPrimary,
    );
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: DarkTokens.brand,
        onPrimary: Colors.white,
        primaryContainer: DarkTokens.brandSoft,
        onPrimaryContainer: DarkTokens.brandInk,
        secondary: DarkTokens.brandInk,
        onSecondary: Colors.white,
        surface: DarkTokens.card,
        onSurface: DarkTokens.textPrimary,
        surfaceContainerHighest: DarkTokens.soft,
        outline: DarkTokens.border,
        outlineVariant: DarkTokens.borderSoft,
        error: DarkTokens.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: DarkTokens.bg,
      textTheme: textTheme.copyWith(
        titleLarge:  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall:  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge:  textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge:   textTheme.bodyLarge?.copyWith(color: DarkTokens.textPrimary),
        bodyMedium:  textTheme.bodyMedium?.copyWith(color: DarkTokens.textSecondary),
        bodySmall:   textTheme.bodySmall?.copyWith(color: DarkTokens.textMuted),
      ),
      cardTheme: CardThemeData(
        color: DarkTokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r14),
          side: const BorderSide(color: DarkTokens.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DarkTokens.card,
        foregroundColor: DarkTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: DarkTokens.borderSoft, thickness: 1),
      iconTheme: const IconThemeData(color: DarkTokens.textSecondary),
    );
  }
}
