import 'package:flutter/material.dart';

/// Canonical typography scale for HobeRadius.
///
/// Mirrors the web `hub_v2` scale (display / title / body / label /
/// caption) with locked font weights so screens stop reinventing
/// inline TextStyle blocks. Font family + colors come from
/// `Theme.of(context).textTheme` (Cairo, applied in `AppTheme`).
///
/// Usage:
///   Text('عنوان رئيسي', style: AppTypography.titleLarge),
///
/// New widgets (J2) and redesigned screens (J4) should reach for
/// these instead of hand-rolling sizes/weights.
class AppTypography {
  AppTypography._();

  // ── Display — hero copy ────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 34, height: 1.15, fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28, height: 1.2, fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
  );

  // ── Titles — section / card headings ───────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20, height: 1.25, fontWeight: FontWeight.w800,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16, height: 1.3, fontWeight: FontWeight.w700,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14, height: 1.35, fontWeight: FontWeight.w700,
  );

  // ── Body — paragraph copy ──────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, height: 1.55, fontWeight: FontWeight.w500,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, height: 1.55, fontWeight: FontWeight.w500,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13, height: 1.55, fontWeight: FontWeight.w500,
  );

  // ── Labels — form labels, button text ──────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, height: 1.3, fontWeight: FontWeight.w800,
    letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13, height: 1.3, fontWeight: FontWeight.w700,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12, height: 1.3, fontWeight: FontWeight.w700,
  );

  // ── Caption — helper / footnote ────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 11.5, height: 1.5, fontWeight: FontWeight.w600,
  );

  // ── Numeric variant — tabular-nums for ledger / KPI tiles ──
  static const TextStyle kpi = TextStyle(
    fontSize: 26, height: 1.1, fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
  );
  static const TextStyle mono = TextStyle(
    fontSize: 14, height: 1.4, fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
