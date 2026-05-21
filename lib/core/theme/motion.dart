import 'package:flutter/widgets.dart';
import 'tokens.dart';

/// Motion vocabulary used across canonical widgets — re-exported from
/// `AppTokens` so callers reach for `AppMotion.fast` / `AppMotion.ease`
/// without pulling the full token surface.
///
/// Durations + curves match the web `--hub-anim-fast` / `--hub-ease`
/// vocabulary so light/heavy interactions feel consistent across web
/// and mobile.
class AppMotion {
  AppMotion._();

  // Durations
  static const Duration instant = AppTokens.motionInstant;
  static const Duration fast    = AppTokens.motionFast;
  static const Duration medium  = AppTokens.motionMedium;
  static const Duration slow    = AppTokens.motionSlow;

  // Curves
  static const Curve ease        = AppTokens.motionEase;
  static const Curve easeInOut   = AppTokens.motionEaseInOut;
  static const Curve emphasized  = AppTokens.motionEmphasized;
  static const Curve springy     = AppTokens.motionSpringy;
}
