import 'package:flutter/material.dart';

import 'tokens.dart';

/// Dark-mode counterparts to [AppTokens]. Light tokens stay where they
/// are (so widgets coded against the light palette keep compiling); the
/// canonical context-aware accessor lives in `app_palette.dart` and
/// switches between [AppTokens] and [DarkTokens] based on
/// `Theme.of(context).brightness`.
///
/// New widgets built in J2 and screens redesigned in J4 should reach
/// for the context palette — they will then theme correctly in both
/// modes. Older code that still references `AppTokens.X` directly will
/// look light-themed under dark mode until its J3/J4 turn lands.
class DarkTokens {
  DarkTokens._();

  // ─────────────────────────────────────────────────────────────
  //  Brand — slightly lighter / desaturated to remain readable
  //  on dark surfaces (WCAG AA on the dark `bg`).
  // ─────────────────────────────────────────────────────────────
  static const Color brand        = Color(0xFF8A7CF1);
  static const Color brandInk     = Color(0xFFA399F4);
  static const Color brandDeep    = Color(0xFFB7B0F7);
  static const Color brandSoft    = Color(0xFF2A2148);
  static const Color brandLine    = Color(0xFF3A2F62);
  static const Color brandLight   = Color(0xFFC4BCFA);

  // ─────────────────────────────────────────────────────────────
  //  Surfaces — deep neutrals with subtle purple bias.
  // ─────────────────────────────────────────────────────────────
  static const Color bg            = Color(0xFF0F0B1F);
  static const Color card          = Color(0xFF1A1530);
  static const Color soft          = Color(0xFF211B40);
  static const Color surfaceMuted  = Color(0xFF181233);
  static const Color surfaceTinted = Color(0xFF221C48);

  // Borders / dividers
  static const Color border        = Color(0xFF2E2750);
  static const Color borderSoft    = Color(0xFF26204A);
  static const Color borderStrong  = Color(0xFF4A3F75);
  static const Color borderNeutral = Color(0xFF2A2350);

  // ─────────────────────────────────────────────────────────────
  //  Text — inverted contrast.
  // ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF1EEFB);
  static const Color textSecondary = Color(0xFFC4BCEB);
  static const Color textMuted     = Color(0xFF8A82B3);
  static const Color textFaint     = Color(0xFF5A547D);

  // ─────────────────────────────────────────────────────────────
  //  Semantic — keep saturated cores; soften the Bg variants
  //  so they sit on dark surface without glowing.
  // ─────────────────────────────────────────────────────────────
  static const Color green         = Color(0xFF34D399);
  static const Color greenSoft     = Color(0xFF103D2E);
  static const Color greenInk      = Color(0xFF6EE7B7);

  static const Color amber         = Color(0xFFFBBF24);
  static const Color amberSoft     = Color(0xFF402912);
  static const Color amberInk      = Color(0xFFFCD34D);

  static const Color red           = Color(0xFFF87171);
  static const Color redSoft       = Color(0xFF441818);
  static const Color redInk        = Color(0xFFFCA5A5);

  static const Color blue          = Color(0xFF60A5FA);
  static const Color blueSoft      = Color(0xFF182A4A);
  static const Color blueInk       = Color(0xFF93C5FD);

  // State triplets (Bg / Fg / Strong)
  static const Color successBg     = Color(0xFF0E2F22);
  static const Color successFg     = Color(0xFF6EE7B7);
  static const Color successStrong = Color(0xFF34D399);

  static const Color warningBg     = Color(0xFF3A2810);
  static const Color warningFg     = Color(0xFFFCD34D);
  static const Color warningStrong = Color(0xFFFBBF24);

  static const Color dangerBg      = Color(0xFF3A1414);
  static const Color dangerFg      = Color(0xFFFCA5A5);
  static const Color dangerStrong  = Color(0xFFF87171);
  static const Color dangerRose    = Color(0xFFFB7185);

  static const Color infoBg        = Color(0xFF152944);
  static const Color infoFg        = Color(0xFF93C5FD);
  static const Color infoStrong    = Color(0xFF60A5FA);

  // Medium tones
  static const Color successMed    = Color(0xFF22C997);
  static const Color warningMed    = Color(0xFFE9A714);
  static const Color dangerMed     = Color(0xFFE05A5A);
  static const Color infoMed       = Color(0xFF4A8DDA);

  // Slate
  static const Color slate100      = Color(0xFF1F2233);
  static const Color slate200      = Color(0xFF323751);
  static const Color slate500      = Color(0xFFA9AEC4);

  // Sidebar — keep dark on dark with a subtle elevation lift.
  static const Color sidebarBg       = Color(0xFF0A081A);
  static const Color sidebarBgElev1  = Color(0xFF12102A);
  static const Color sidebarBgElev2  = Color(0xFF1A1737);
  static const Color sidebarBgElev3  = Color(0xFF211D44);
  static const Color sidebarText     = Color(0xFFC8C2EA);
  static const Color sidebarActive   = Color(0xFFFFFFFF);

  // Overlays kept identical (semi-transparent white reads the same on
  // any dark surface).
  static const Color overlayLightLg = AppTokens.overlayLightLg;
  static const Color overlayLightSm = AppTokens.overlayLightSm;

  // ─────────────────────────────────────────────────────────────
  //  Brand gradients — same direction as light, retuned colors.
  // ─────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandInk],
  );
  static const LinearGradient brandSoftWash = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandSoft, Color(0x000F0B1F)],
  );

  // ─────────────────────────────────────────────────────────────
  //  Box shadows — deeper, more diffuse on dark.
  // ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> shCard = [
    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shMd = [
    BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shLg = [
    BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 12)),
  ];
}
