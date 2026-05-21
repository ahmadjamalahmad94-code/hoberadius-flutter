import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/print_templates/data/card_renderer_svg.dart';
import 'package:hoberadius_app/features/print_templates/presentation/_dev/card_renderer_gallery.dart';

/// One sanity test per preset — guarantees the gallery never falls
/// into a broken state. If a preset's SVG drops below a sensible
/// rect-count (e.g. the gradient stops failed to emit), the diff
/// captures it immediately.
void main() {
  for (final preset in galleryPresets) {
    final key = preset['key'] as String;
    test('preset "$key" renders a valid SVG', () {
      final model = modelForPresetTest(key);
      final svg = renderCardSvg(model);
      expect(svg, startsWith('<svg '));
      expect(svg, endsWith('</svg>'));
      expect(svg, contains('viewBox="0 0 1000 600"'));
      expect(svg, contains('direction="ltr"'));
      expect(svg, contains('CARD1234'));
      expect('<rect '.allMatches(svg).length, greaterThan(10));
    });
  }
}
