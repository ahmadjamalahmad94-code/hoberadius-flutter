import 'package:flutter/material.dart';

import 'dark_tokens.dart';
import 'tokens.dart';

/// Theme-aware palette — single context-driven accessor that resolves
/// to either [AppTokens] (light) or [DarkTokens] (dark) automatically.
///
/// Canonical widgets (J2) and redesigned screens (J4) MUST use this
/// instead of pulling raw `AppTokens.X` so they switch correctly when
/// the operator toggles dark mode. Existing legacy widgets that still
/// reference `AppTokens.X` directly will look light-themed under dark
/// mode until they're touched by J3/J4 — see FLUTTER_REDESIGN_PLAN.md.
///
/// Usage:
///   final p = AppPalette.of(context);
///   Container(color: p.surface, ...)
class AppPalette {
  const AppPalette({
    required this.brand,
    required this.brandInk,
    required this.brandSoft,
    required this.brandLine,
    required this.brandLight,
    required this.bg,
    required this.card,
    required this.soft,
    required this.surfaceMuted,
    required this.surfaceTinted,
    required this.border,
    required this.borderSoft,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.successBg,
    required this.successFg,
    required this.successStrong,
    required this.warningBg,
    required this.warningFg,
    required this.warningStrong,
    required this.dangerBg,
    required this.dangerFg,
    required this.dangerStrong,
    required this.dangerRose,
    required this.infoBg,
    required this.infoFg,
    required this.infoStrong,
    required this.brandGradient,
    required this.shCard,
  });

  final Color brand;
  final Color brandInk;
  final Color brandSoft;
  final Color brandLine;
  final Color brandLight;

  final Color bg;
  final Color card;
  final Color soft;
  final Color surfaceMuted;
  final Color surfaceTinted;

  final Color border;
  final Color borderSoft;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color successBg;
  final Color successFg;
  final Color successStrong;
  final Color warningBg;
  final Color warningFg;
  final Color warningStrong;
  final Color dangerBg;
  final Color dangerFg;
  final Color dangerStrong;
  final Color dangerRose;
  final Color infoBg;
  final Color infoFg;
  final Color infoStrong;

  final LinearGradient brandGradient;
  final List<BoxShadow> shCard;

  /// Light palette mapped from [AppTokens].
  static const AppPalette light = AppPalette(
    brand:        AppTokens.brand,
    brandInk:     AppTokens.brandInk,
    brandSoft:    AppTokens.brandSoft,
    brandLine:    AppTokens.brandLine,
    brandLight:   AppTokens.brandLight,
    bg:           AppTokens.bg,
    card:         AppTokens.card,
    soft:         AppTokens.soft,
    surfaceMuted: AppTokens.surfaceMuted,
    surfaceTinted:AppTokens.surfaceTinted,
    border:       AppTokens.border,
    borderSoft:   AppTokens.borderSoft,
    borderStrong: AppTokens.borderStrong,
    textPrimary:  AppTokens.textPrimary,
    textSecondary:AppTokens.textSecondary,
    textMuted:    AppTokens.textMuted,
    successBg:    AppTokens.successBg,
    successFg:    AppTokens.successFg,
    successStrong:AppTokens.successStrong,
    warningBg:    AppTokens.warningBg,
    warningFg:    AppTokens.warningFg,
    warningStrong:AppTokens.warningStrong,
    dangerBg:     AppTokens.dangerBg,
    dangerFg:     AppTokens.dangerFg,
    dangerStrong: AppTokens.dangerStrong,
    dangerRose:   AppTokens.dangerRose,
    infoBg:       AppTokens.infoBg,
    infoFg:       AppTokens.infoFg,
    infoStrong:   AppTokens.infoStrong,
    brandGradient:AppTokens.brandGradient,
    shCard:       AppTokens.shCard,
  );

  /// Dark palette mapped from [DarkTokens].
  static const AppPalette dark = AppPalette(
    brand:        DarkTokens.brand,
    brandInk:     DarkTokens.brandInk,
    brandSoft:    DarkTokens.brandSoft,
    brandLine:    DarkTokens.brandLine,
    brandLight:   DarkTokens.brandLight,
    bg:           DarkTokens.bg,
    card:         DarkTokens.card,
    soft:         DarkTokens.soft,
    surfaceMuted: DarkTokens.surfaceMuted,
    surfaceTinted:DarkTokens.surfaceTinted,
    border:       DarkTokens.border,
    borderSoft:   DarkTokens.borderSoft,
    borderStrong: DarkTokens.borderStrong,
    textPrimary:  DarkTokens.textPrimary,
    textSecondary:DarkTokens.textSecondary,
    textMuted:    DarkTokens.textMuted,
    successBg:    DarkTokens.successBg,
    successFg:    DarkTokens.successFg,
    successStrong:DarkTokens.successStrong,
    warningBg:    DarkTokens.warningBg,
    warningFg:    DarkTokens.warningFg,
    warningStrong:DarkTokens.warningStrong,
    dangerBg:     DarkTokens.dangerBg,
    dangerFg:     DarkTokens.dangerFg,
    dangerStrong: DarkTokens.dangerStrong,
    dangerRose:   DarkTokens.dangerRose,
    infoBg:       DarkTokens.infoBg,
    infoFg:       DarkTokens.infoFg,
    infoStrong:   DarkTokens.infoStrong,
    brandGradient:DarkTokens.brandGradient,
    shCard:       DarkTokens.shCard,
  );

  /// Context-aware lookup. Resolves at build time based on the
  /// nearest `Theme.of(context).brightness`.
  static AppPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? AppPalette.dark : AppPalette.light;
  }
}
