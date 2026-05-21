/// Pixel-diff smoke between two SVGs produced by the SAME render
/// model. Catches any non-deterministic behaviour in the renderer
/// (e.g. an iteration that depended on map order).
///
/// A true pixel-diff against the web's SVG requires running the
/// backend; that's done in CI via `tools/diff_web_admin.sh` +
/// rendering both SVGs to PNG. Here we only assert the Dart side
/// is deterministic; the cross-source diff lives in CI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/print_templates/data/card_renderer_svg.dart';
import 'package:hoberadius_app/features/print_templates/presentation/_dev/card_renderer_gallery.dart';

void main() {
  for (final preset in galleryPresets) {
    final key = preset['key'] as String;
    test('preset "$key" SVG is deterministic across two builds', () {
      final a = renderCardSvg(modelForPresetTest(key));
      final b = renderCardSvg(modelForPresetTest(key));
      // Byte-identical — no map-order randomness, no embedded
      // timestamps, no random ids.
      expect(a, equals(b));
    });
  }
}
