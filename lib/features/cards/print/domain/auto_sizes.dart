import '../data/quick_print_repository.dart';

/// Font-size slider range (points, like the web «مثل الوورد» field).
const double kMinFontPt = 4;
const double kMaxFontPt = 36;

/// QR size range in % of the card width — the renderer clamps to 8–48 %.
const double kMinQrPct = 8;
const double kMaxQrPct = 48;

const double _ptPerMm = 72 / 25.4;

double _half(double v) => (v * 2).roundToDouble() / 2;

/// The value font the renderer draws in a credentials pill when the size is
/// automatic: `value_font_size = pill height × 0.52` (card_renderer
/// `_pill_element`). The pill box comes back from `quick-elements` in mm,
/// so the size in points is `h_mm × 0.52 × 72 / 25.4`.
double? autoFontPt(ElementBox? pill) {
  if (pill == null || pill.h <= 0) return null;
  return _half(pill.h * 0.52 * _ptPerMm).clamp(kMinFontPt, kMaxFontPt);
}

/// The QR's automatic size: the renderer draws it `size × card width`.
double? autoQrPct(CardElements? els) {
  final qr = els?.boxes['qr'];
  if (qr == null || els == null || els.widthMm <= 0 || qr.w <= 0) return null;
  return _half(qr.w / els.widthMm * 100).clamp(kMinQrPct, kMaxQrPct);
}
