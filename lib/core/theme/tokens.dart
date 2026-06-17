import 'package:flutter/material.dart';

/// Design tokens — synced with the web `hub_v2.css` palette.
///
/// Brand is now PURPLE (#6B5AED) to match the Card Checker visual
/// language and the overnight UI rebuild. The legacy navy/cyan
/// names are kept as backwards-compatible aliases so existing
/// widgets compile without churn while we migrate.
class AppTokens {
  AppTokens._();

  // ─────────────────────────────────────────────────────────────
  //  HUB v2 — Purple brand (new canonical)
  // ─────────────────────────────────────────────────────────────
  /// Primary brand purple (web --cc-brand)
  static const Color brand = Color(0xFF6B5AED);

  /// Lighter brand ramp (web --cc-brand-2 / --cc-brand-3) — hero gradients.
  static const Color brand2 = Color(0xFF8B7BF8);
  static const Color brand3 = Color(0xFFA99BF9);

  /// Darker ink for headings / hover (web --hb-purple-deep #5B4BD8)
  static const Color brandInk = Color(0xFF5B4BD8);

  /// Even darker for pressed buttons (web --cc-brand-deep #4A36C9)
  static const Color brandDeep = Color(0xFF4A36C9);

  /// Deepest brand ink (web --cc-brand-ink) — pill-purple foreground.
  static const Color brandInkDeep = Color(0xFF2E1F8C);

  /// Soft purple tint for surfaces / hover backgrounds (web --cc-brand-softer)
  static const Color brandSoft = Color(0xFFF4F1FE);

  /// Slightly stronger soft purple (web --cc-brand-soft2)
  static const Color brandSoft2 = Color(0xFFE8E1FB);

  /// Mid-tone purple line for borders on tinted surfaces (web --cc-border-cool)
  static const Color brandLine = Color(0xFFE5E0F5);

  // ─────────────────────────────────────────────────────────────
  //  Surfaces — matched to web --hb-bg / --cc-card-bg / --cc-tint-bg
  // ─────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF5F3FB); // --hb-bg (purple-tinted page)
  static const Color card = Color(0xFFFFFFFF); // --cc-card-bg
  static const Color soft = Color(0xFFFAFAFA); // --cc-tint-bg
  static const Color border = Color(0xFFEEEDF3); // --hb-border
  static const Color borderSoft = Color(0xFFEEEDF3);
  static const Color borderStrong = Color(0xFFE3E1EC); // --hb-border-strong

  // ─────────────────────────────────────────────────────────────
  //  Text — matched to web --cc-text / -soft / -mute / -faint
  // ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2A37);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A0AE);
  static const Color textFaint = Color(0xFFB6BCC8);

  // ─────────────────────────────────────────────────────────────
  //  Semantic
  // ─────────────────────────────────────────────────────────────
  // Pill tones matched to web --cc-pill-* (bg/fg) for exact chip parity.
  static const Color green = Color(0xFF22C55E);
  static const Color greenSoft = Color(0xFFDEF3E5); // --cc-pill-green-bg
  static const Color greenInk = Color(0xFF157F4E); // --cc-pill-green-fg

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFCEFC9); // --cc-pill-amber-bg
  static const Color amberInk = Color(0xFF7A4F02); // --cc-pill-amber-fg

  static const Color red = Color(0xFFEF4444);
  static const Color redSoft = Color(0xFFFDE5E5); // --cc-pill-red-bg
  static const Color redInk = Color(0xFF9B1C1C); // --cc-pill-red-fg

  static const Color blue = Color(0xFF3D8DD6); // --hr-blue-info
  static const Color blueSoft = Color(0xFFE3EDF9); // --cc-pill-blue-bg
  static const Color blueInk = Color(0xFF1E5C9F); // --cc-pill-blue-fg

  // Extra web pill tones (cyan / teal / grey) for full StatusPill parity.
  static const Color cyan = Color(0xFF1F8FB0);
  static const Color cyanSoft = Color(0xFFDEF3F8); // --cc-pill-cyan-bg
  static const Color cyanInk = Color(0xFF0F627A); // --cc-pill-cyan-fg
  static const Color teal = Color(0xFF0B9078);
  static const Color tealSoft = Color(0xFFD2F1EC); // --cc-pill-teal-bg
  static const Color tealInk = Color(0xFF0B6E5B); // --cc-pill-teal-fg
  static const Color greySoft = Color(0xFFEDEAE1); // --cc-pill-grey-bg
  static const Color greyInk = Color(0xFF5B6470); // --cc-pill-grey-fg

  // ─────────────────────────────────────────────────────────────
  //  Sidebar / topbar (purple-tinted dark)
  // ─────────────────────────────────────────────────────────────
  static const Color sidebarBg = Color(0xFF1A1530);
  static const Color sidebarText = Color(0xFFC8C2EA);
  static const Color sidebarActive = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────────────────────
  //  Sidebar elevation shades (extra-dark navy tones used by the
  //  collapsed sidebar / picker dim layers). Standalone — not
  //  aliases — they have no semantic counterpart on the canonical
  //  palette so they keep their own names.
  // ─────────────────────────────────────────────────────────────
  static const Color sidebarBgElev1 = Color(0xFF211B40);
  static const Color sidebarBgElev2 = Color(0xFF2A2350);
  static const Color sidebarBgElev3 = Color(0xFF332B60);

  /// Lighter purple accent (50% mix of brand + white) — used by chips
  /// and pills that need a softer brand tone than `brand` itself.
  static const Color brandLight = Color(0xFF8674F1);

  // ─────────────────────────────────────────────────────────────
  //  Neutral surface tints + slate scale.
  //  Replaces the ad-hoc Color(0xFFF8FAFC) / Color(0xFFEFF2F7) etc.
  //  that used to leak through screens.
  // ─────────────────────────────────────────────────────────────
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color surfaceTinted = Color(0xFFEFF2F7);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFCBD5E1);
  static const Color slate500 = Color(0xFF64748B);

  /// Border equivalent to `border` but slightly darker — kept for the
  /// places where the legacy literal 0xFFE5E7EB was used.
  static const Color borderNeutral = Color(0xFFE5E7EB);

  // ─────────────────────────────────────────────────────────────
  //  Translucent white overlays (used on the dark sidebar).
  // ─────────────────────────────────────────────────────────────
  static const Color overlayLightLg = Color(0x33FFFFFF);
  static const Color overlayLightSm = Color(0x22FFFFFF);

  // ─────────────────────────────────────────────────────────────
  //  «Medium» state colors — sit between Bg and Strong for compact
  //  badges / pills that need higher saturation than the soft Bg
  //  but less than the solid Strong.
  // ─────────────────────────────────────────────────────────────
  static const Color successMed = Color(0xFF86EFAC);
  static const Color warningMed = Color(0xFFFCD34D);
  static const Color dangerMed = Color(0xFFFCA5A5);
  static const Color infoMed = Color(0xFFBFDBFE);

  // ─────────────────────────────────────────────────────────────
  //  Spacing scale
  // ─────────────────────────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;

  // ─────────────────────────────────────────────────────────────
  //  Radii (matches hub-v2)
  // ─────────────────────────────────────────────────────────────
  static const double r6 = 6;
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r18 = 18; // --cc-r-card
  static const double r20 = 20;
  static const double r22 = 22; // --cc-r-hero

  // ─────────────────────────────────────────────────────────────
  //  Breakpoints (responsive)
  // ─────────────────────────────────────────────────────────────
  static const double bpMobile = 600;
  static const double bpTablet = 960;
  static const double bpDesktop = 1280;

  // Sidebar layout breakpoints (web-parity navigation shell).
  //
  // The shell keys the FULL persistent web-style sidebar on available width,
  // not on a coarse platform/orientation flip — so a desktop window that is
  // shrunk somewhat (or a tablet in landscape) keeps the complete sidebar
  // instead of falling back to the phone layout.
  //
  //   width >= bpSidebarFull  → full expanded sidebar (desktop + tablet-landscape)
  //   width >= bpSidebarRail  → same sidebar, collapsed to an icon rail
  //   width <  bpSidebarRail  → phone layout (bottom nav)
  //
  // Tuned so a desktop window shrunk to ~1000px (or a tablet in landscape,
  // ≥1024) keeps the full sidebar, a narrow-desktop band collapses to the icon
  // rail, and only phone / tablet-portrait widths (≤~834px) drop to bottom nav.
  static const double bpSidebarFull = 1000;
  static const double bpSidebarRail = 840;

  // ─────────────────────────────────────────────────────────────
  //  Sidebar geometry
  // ─────────────────────────────────────────────────────────────
  static const double sidebarWidth = 260;
  static const double sidebarWidthCollapsed = 72;
  static const double topbarHeight = 64;

  // ─────────────────────────────────────────────────────────────
  //  Box shadows (matches hub-v2 sh-card / sh-md / sh-lg)
  // ─────────────────────────────────────────────────────────────
  // Matched to web --cc-sh-card / --cc-sh-card2 / --cc-sh-hero (neutral
  // slate elevation; hero keeps the brand-tinted glow).
  static const List<BoxShadow> shCard = [
    BoxShadow(color: Color(0x080F172A), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> shMd = [
    BoxShadow(color: Color(0x080F172A), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x140F172A), blurRadius: 26, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> shLg = [
    BoxShadow(color: Color(0x384A36C9), blurRadius: 30, offset: Offset(0, 14)),
    BoxShadow(color: Color(0x1A4A36C9), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> shPop = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 22, offset: Offset(0, 8)),
  ];

  // ─────────────────────────────────────────────────────────────
  //  Semantic state colors (full Bg / Fg / Strong triplets).
  //
  //  Semantics:
  //    Bg     — large surfaces, banner backgrounds
  //    Fg     — text / icon on top of the matching Bg
  //    Strong — solid fills (buttons, badges) when contrast on
  //             white surface is needed
  //  Aliases for the existing single/soft/ink names are preserved
  //  above so nothing breaks during migration.
  // ─────────────────────────────────────────────────────────────
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successFg = Color(0xFF047857);
  static const Color successStrong = Color(0xFF10B981);

  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningFg = Color(0xFF92400E);
  static const Color warningStrong = Color(0xFFF59E0B);

  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerFg = Color(0xFFB91C1C);
  static const Color dangerStrong = Color(0xFFEF4444);
  static const Color dangerRose =
      Color(0xFFF43F5E); // rose accent for delete CTAs

  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoFg = Color(0xFF1D4ED8);
  static const Color infoStrong = Color(0xFF3B82F6);

  // ─────────────────────────────────────────────────────────────
  //  Brand gradients — used for hero buttons, KPI cards, accents.
  //  Codified as constant LinearGradient pairs so widgets pull
  //  from one source instead of recomposing per call site.
  // ─────────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandInk],
  );

  /// Web --cc-hero-grad: linear-gradient(135deg,#6B5AED,#7B6BF2 45%,#A99BF9).
  /// Use for hero cards / primary KPI surfaces to match the web exactly.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
    colors: [brand, Color(0xFF7B6BF2), brand3],
  );

  /// Web --cc-chip-grad: gold chip gradient.
  static const LinearGradient chipGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD86B), Color(0xFFE3A41A)],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successStrong, successFg],
  );
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dangerRose, dangerFg],
  );
  static const LinearGradient brandSoftWash = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandSoft, Color(0x00FFFFFF)],
  );

  // ─────────────────────────────────────────────────────────────
  //  Motion tokens — durations and curves used by the canonical
  //  widgets. Mirrors web's --hub-anim-fast / --hub-ease.
  // ─────────────────────────────────────────────────────────────
  static const Duration motionInstant = Duration(milliseconds: 80);
  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionMedium = Duration(milliseconds: 240);
  static const Duration motionSlow = Duration(milliseconds: 360);

  static const Curve motionEase = Curves.easeOutCubic;
  static const Curve motionEaseInOut = Curves.easeInOutCubic;
  static const Curve motionEmphasized = Curves.fastOutSlowIn;
  static const Curve motionSpringy = Curves.easeOutBack;
}
