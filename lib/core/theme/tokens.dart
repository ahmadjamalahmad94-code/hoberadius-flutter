import 'package:flutter/material.dart';

/// Design tokens copied from radius-module/static/css.
/// Source of truth: navy/cyan palette + Cairo font + RTL.
class AppTokens {
  AppTokens._();

  // ── Brand ────────────────────────────────────────────────────────────
  static const Color navy900 = Color(0xFF0E1B2F);
  static const Color navy800 = Color(0xFF132340);
  static const Color navy700 = Color(0xFF1A2D52);
  static const Color navy600 = Color(0xFF223863);

  static const Color cyan500 = Color(0xFF2BAACC);
  static const Color cyan400 = Color(0xFF49BFDE);
  static const Color cyan100 = Color(0xFFE6F6FB);

  // ── Surfaces ─────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFF4F6FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3E7EE);
  static const Color sidebarBg = navy900;
  static const Color sidebarText = Color(0xFFB8C7E0);
  static const Color sidebarActive = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B2434);
  static const Color textSecondary = Color(0xFF55617A);
  static const Color textMuted = Color(0xFF8A95AB);

  // ── Status ───────────────────────────────────────────────────────────
  static const Color green = Color(0xFF26A65B);
  static const Color orange = Color(0xFFE48B1B);
  static const Color purple = Color(0xFF7E55D6);
  static const Color red = Color(0xFFD04949);

  // ── Spacing ──────────────────────────────────────────────────────────
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;

  // ── Radii ────────────────────────────────────────────────────────────
  static const double r6 = 6;
  static const double r10 = 10;
  static const double r14 = 14;
  static const double r20 = 20;

  // ── Breakpoints (responsive) ─────────────────────────────────────────
  static const double bpMobile = 600;
  static const double bpTablet = 960;
  static const double bpDesktop = 1280;

  // ── Sidebar ──────────────────────────────────────────────────────────
  static const double sidebarWidth = 248;
  static const double sidebarWidthCollapsed = 72;
  static const double topbarHeight = 64;
}
