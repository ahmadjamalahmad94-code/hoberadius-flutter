import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/print_templates/data/card_renderer_svg.dart';
import 'package:hoberadius_app/features/print_templates/domain/card_render_model.dart';
import 'package:hoberadius_app/features/print_templates/domain/card_render_model_builder.dart';

/// Mirror of the web's
/// `radius-module/tests/test_card_renderer.py` invariants — the
/// Dart SVG adapter must satisfy exactly the same contract.
void main() {
  Map<String, dynamic> template({Map<String, dynamic>? layoutOverrides}) {
    return {
      'id': 1,
      'username_x': 0,
      'username_y': 0,
      'password_x': 0,
      'password_y': 0,
      'qr_x': 0,
      'qr_y': 0,
      'layout_json': <String, dynamic>{
        'card_orientation': 'horizontal',
        'card_width_mm': 85,
        'card_height_mm': 54,
        'brand_name': 'HobeRadius',
        'card_title': 'Internet Card',
        'footer_text': 'Keep login data until expiry',
        'hotspot_address': 'hotspot.local',
        'pattern_style': 'signal',
        'show_brand': true,
        'show_username': true,
        'show_password': true,
        'show_qr': true,
        'show_hotspot': true,
        'show_serial': true,
        ...?layoutOverrides,
      },
    };
  }

  CardRenderModel modelOf({Map<String, dynamic>? layoutOverrides}) {
    return buildCardRenderModel(
      template(layoutOverrides: layoutOverrides),
      card: {'id': 915, 'username': 'd2-85104', 'password': 'Secret_9'},
    );
  }

  group('SVG envelope', () {
    test('viewBox + preserveAspectRatio + width:100% + height:auto', () {
      final svg = renderCardSvg(modelOf());
      expect(svg, contains('viewBox="0 0 1000 600"'));
      expect(svg, contains('preserveAspectRatio="xMidYMid meet"'));
      expect(svg, contains('width:100%'));
      expect(svg, contains('height:auto'));
    });

    test('orientation flip switches viewBox to 600x1000', () {
      final svg = renderCardSvg(
        modelOf(layoutOverrides: {'card_orientation': 'vertical'}),
      );
      expect(svg, contains('viewBox="0 0 600 1000"'));
    });

    test('root + every <text> are pinned LTR (RTL safety)', () {
      final svg = renderCardSvg(modelOf());
      // root SVG
      expect(svg.substring(0, 400), contains('direction="ltr"'));
      // every text element carries its own direction="ltr" too
      final textCount = 'svg <text x='.allMatches(svg).length +
          '<text x='.allMatches(svg).length;
      expect(textCount, greaterThan(0));
      final perTextLtr = '<text x='.allMatches(svg).length;
      final ltrAttrCount = 'direction="ltr"'.allMatches(svg).length;
      // root + every <text> ⇒ ltrAttrCount >= perTextLtr + 1
      expect(ltrAttrCount, greaterThanOrEqualTo(perTextLtr + 1));
    });
  });

  group('content + masking', () {
    test('SVG masks the password by default', () {
      final svg = renderCardSvg(modelOf());
      expect(svg, isNot(contains('Secret_9')));
      expect(svg, contains('•'));
    });

    test('SVG reveals the password when mask=false', () {
      final svg = renderCardSvg(modelOf(), maskPassword: false);
      expect(svg, contains('Secret_9'));
    });

    test('SVG carries username + brand + title + meta + footer', () {
      final svg = renderCardSvg(modelOf());
      expect(svg, contains('d2-85104'));
      expect(svg, contains('HobeRadius'));
      expect(svg, contains('Internet Card'));
      expect(svg, contains('hotspot.local'));
      expect(svg, contains('Keep login data until expiry'));
      expect(svg, contains('#915'));
    });

    test('XML escapes user-supplied text (XSS defence)', () {
      final svg = renderCardSvg(
        buildCardRenderModel(
          template(layoutOverrides: {'brand_name': '<script>alert(1)</script>'}),
          card: {'id': 1, 'username': 'u', 'password': 'p'},
        ),
      );
      expect(svg, isNot(contains('<script>alert(1)</script>')));
      expect(svg, contains('&lt;script&gt;'));
    });
  });

  group('renderer invariants', () {
    test('internal element ratios identical regardless of cards_per_row', () {
      // cards_per_row is a sheet-layout property — must not change
      // anything in the model the renderer emits.
      final t2x5 = template();
      t2x5['cards_per_row'] = 2;
      t2x5['cards_per_column'] = 5;
      final t4x6 = template();
      t4x6['cards_per_row'] = 4;
      t4x6['cards_per_column'] = 6;
      final m1 = buildCardRenderModel(
        t2x5,
        card: {'id': 1, 'username': 'u', 'password': 'p'},
      );
      final m2 = buildCardRenderModel(
        t4x6,
        card: {'id': 1, 'username': 'u', 'password': 'p'},
      );
      expect(m1.canvas, equals(m2.canvas));
      expect(m1.elements.length, equals(m2.elements.length));
      for (var i = 0; i < m1.elements.length; i++) {
        expect(m1.elements[i].runtimeType, equals(m2.elements[i].runtimeType));
        expect(m1.elements[i].id, equals(m2.elements[i].id));
      }
    });

    test('QR coordinates come from canvas units (not sheet cell)', () {
      final m = modelOf();
      final qr = m.elements.whereType<CardQr>().single;
      expect(qr.x, greaterThan(0));
      expect(qr.x, lessThan(1000));
      expect(qr.y, greaterThan(0));
      expect(qr.y, lessThan(600));
      expect(qr.size, greaterThan(100));
      expect(qr.size, lessThan(400));
    });

    test('background image data URL surfaces in both model + SVG', () {
      const oneByOnePng = 'data:image/png;base64,'
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgAAIAAAUAAen63NgAAAAASUVORK5CYII=';
      final m = buildCardRenderModel(
        template(layoutOverrides: {
          'background_image_data_url': oneByOnePng,
          'image_opacity': 0.6,
        }),
        card: {'id': 1, 'username': 'u', 'password': 'p'},
      );
      expect(m.background.imageDataUrl, startsWith('data:image/png;base64,'));
      expect(m.background.imageOpacity, closeTo(0.6, 0.0001));
      final svg = renderCardSvg(m);
      expect(svg, contains('data:image/png;base64,'));
    });

    test('portrait swaps canvas dimensions', () {
      final m = buildCardRenderModel(
        template(layoutOverrides: {'card_orientation': 'vertical'}),
        card: {'id': 1, 'username': 'u', 'password': 'p'},
      );
      expect(m.canvas, equals(const CardCanvasSize(600, 1000)));
    });
  });

  group('QR symbol', () {
    test('emits one <rect> per dark module + a white background', () {
      final svg = renderCardSvg(modelOf());
      // there's exactly one card-qr group
      expect('class="card-qr"'.allMatches(svg).length, equals(1));
      // the QR group contains many <rect> tags (one per dark module)
      final qrSection = svg.substring(svg.indexOf('class="card-qr"'));
      final rectCount = '<rect '.allMatches(qrSection).length;
      expect(rectCount, greaterThan(20)); // typical QR has 200+ modules
    });
  });
}
