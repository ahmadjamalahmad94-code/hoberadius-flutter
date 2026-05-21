import 'tokens.dart';

/// Public 8-pt spacing scale, re-exported from `AppTokens` so callers can
/// reach for `AppSpacing.s16` without pulling the whole token surface.
///
/// Behavior is identical to `AppTokens.s4…s40`. Older code may keep
/// referencing `AppTokens.sXX`; both styles compile to the same constant.
class AppSpacing {
  AppSpacing._();

  static const double s4  = AppTokens.s4;
  static const double s8  = AppTokens.s8;
  static const double s12 = AppTokens.s12;
  static const double s16 = AppTokens.s16;
  static const double s20 = AppTokens.s20;
  static const double s24 = AppTokens.s24;
  static const double s32 = AppTokens.s32;
  static const double s40 = AppTokens.s40;
}
