import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/print/data/quick_print_repository.dart';
import 'package:hoberadius_app/features/cards/print/domain/auto_sizes.dart';

void main() {
  test('automatic font size is read off the pill height, not zero', () {
    // A 7 mm pill → 7 × 0.52 × 72 / 25.4 = 10.32 pt → 10.5 (half-point step).
    expect(autoFontPt(const ElementBox(2, 30, 40, 7)), 10.5);
    expect(autoFontPt(null), isNull);
    expect(autoFontPt(const ElementBox(0, 0, 0, 0)), isNull);
    // Clamped into the slider range.
    expect(autoFontPt(const ElementBox(0, 0, 10, 100)), kMaxFontPt);
  });

  test('automatic QR size is the % of the card width it is drawn at', () {
    const els = CardElements(
      widthMm: 85.6,
      heightMm: 54,
      boxes: {'qr': ElementBox(56, 19, 23.1, 23.1)},
    );
    expect(autoQrPct(els), 27);
    expect(autoQrPct(null), isNull);
    expect(
      autoQrPct(const CardElements(widthMm: 85.6, heightMm: 54, boxes: {})),
      isNull,
    );
  });
}
