import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/print_templates/domain/card_render_model.dart';
import 'package:hoberadius_app/features/print_templates/domain/card_render_model_builder.dart';

/// Sanity tests for the Dart card render model builder.
///
/// These mirror the same invariants the Python suite checks in
/// `radius-module/tests/test_card_renderer.py`:
///   * model carries the right canvas;
///   * element ids appear in the expected order;
///   * credential pills carry the username and password;
///     password (both real, NOT yet masked at this layer);
///   * QR payload follows the username → cardId → SAMPLE fallback;
///   * legacy (0, 0) mm coords trigger the canonical defaults;
///   * non-zero mm coords get normalised to canvas fractions.
void main() {
  Map<String, dynamic> template({
    String orientation = 'horizontal',
    Map<String, dynamic>? layoutOverrides,
    num? usernameX,
    num? usernameY,
  }) {
    final layout = <String, dynamic>{
      'card_orientation': orientation,
      'card_width_mm': 85,
      'card_height_mm': 54,
      'brand_name': 'HobeRadius',
      'card_title': 'بطاقة إنترنت',
      'footer_text': 'احتفظ ببيانات الدخول',
      'hotspot_address': 'hotspot.local',
      'pattern_style': 'signal',
      ...?layoutOverrides,
    };
    return {
      'id': 1,
      'username_x': usernameX ?? 0,
      'username_y': usernameY ?? 0,
      'password_x': 0,
      'password_y': 0,
      'qr_x': 0,
      'qr_y': 0,
      'layout_json': layout,
    };
  }

  Map<String, dynamic> sampleCard({
    String username = 'CARD1234',
    String password = 'pw1234',
    Object id = 99,
  }) =>
      {'id': id, 'username': username, 'password': password};

  test('landscape canvas is 1000x600', () {
    final model = buildCardRenderModel(template(), card: sampleCard());
    expect(model.canvas, equals(const CardCanvasSize(1000, 600)));
    expect(model.orientation, equals(CardOrientation.horizontal));
  });

  test('vertical orientation flips canvas to 600x1000', () {
    final model = buildCardRenderModel(
      template(orientation: 'vertical'),
      card: sampleCard(),
    );
    expect(model.canvas, equals(const CardCanvasSize(600, 1000)));
    expect(model.orientation, equals(CardOrientation.vertical));
  });

  test('default element order matches the web', () {
    final model = buildCardRenderModel(template(), card: sampleCard());
    final ids = model.elements.map((e) => e.id).toList();
    expect(
      ids,
      ['accent', 'brand', 'title', 'user', 'pass', 'qr', 'meta', 'footer'],
    );
  });

  test('credential pills carry username and real password',
      () {
    final model = buildCardRenderModel(
      template(),
      card: sampleCard(username: 'd2-85104', password: 'Secret_9'),
    );
    final user =
        model.elements.whereType<CardPill>().firstWhere((e) => e.id == 'user');
    final pass =
        model.elements.whereType<CardPill>().firstWhere((e) => e.id == 'pass');
    expect(user.value, equals('d2-85104'));
    expect(user.isPassword, isFalse);
    expect(pass.value, equals('Secret_9'));
    expect(pass.isPassword, isTrue);
    // Top-level model carries the real password — adapters decide.
    expect(model.password, equals('Secret_9'));
  });

  test('QR payload uses username, and falls back to SAMPLE when blank', () {
    // Matches `_extractCardFields` in card_renderer.py — when the
    // raw username is empty it's already replaced with 'SAMPLE'
    // BEFORE the QR fallback chain runs. So a card with id=99 but
    // username='' still produces payload='SAMPLE', not '99'.
    final withUser = buildCardRenderModel(
      template(),
      card: sampleCard(username: 'pickme', id: 42),
    );
    final qrWithUser = withUser.elements.whereType<CardQr>().single;
    expect(qrWithUser.payload, equals('pickme'));

    final blank = buildCardRenderModel(template());
    final qrBlank = blank.elements.whereType<CardQr>().single;
    expect(qrBlank.payload, equals('SAMPLE'));
  });

  test('(0,0) legacy mm coords resolve to canonical default positions', () {
    final model = buildCardRenderModel(template(), card: sampleCard());
    final user =
        model.elements.whereType<CardPill>().firstWhere((e) => e.id == 'user');
    // _DEFAULT_POSITIONS['user'] = {x: 0.06, y: 0.50} on a 1000x600 canvas.
    expect(user.x, closeTo(60.0, 0.0001));
    expect(user.y, closeTo(300.0, 0.0001));
  });

  test('non-zero mm coords get normalised to canvas fractions', () {
    final model = buildCardRenderModel(
      template(usernameX: 17, usernameY: 27),
      card: sampleCard(),
    );
    final user =
        model.elements.whereType<CardPill>().firstWhere((e) => e.id == 'user');
    // 17 / 85 = 0.2 → 0.2 * 1000 = 200
    expect(user.x, closeTo(200.0, 0.0001));
    // 27 / 54 = 0.5 → 0.5 * 600 = 300
    expect(user.y, closeTo(300.0, 0.0001));
  });

  test('overrides win over template text', () {
    final model = buildCardRenderModel(
      template(),
      card: sampleCard(),
      overrides: {
        'brand_name': 'Custom Brand',
        'card_title': 'Custom Title',
        'footer_text': 'مرحبا',
      },
    );
    final brand =
        model.elements.whereType<CardText>().firstWhere((e) => e.id == 'brand');
    final title =
        model.elements.whereType<CardText>().firstWhere((e) => e.id == 'title');
    final footer = model.elements
        .whereType<CardText>()
        .firstWhere((e) => e.id == 'footer');
    expect(brand.text, equals('Custom Brand'));
    expect(title.text, equals('Custom Title'));
    expect(footer.text, equals('مرحبا'));
  });

  test('show flags hide elements when false', () {
    final model = buildCardRenderModel(
      template(
        layoutOverrides: {
          'show_brand': false,
          'show_password': false,
          'show_qr': false,
          'show_hotspot': false,
          'show_serial': false,
        },
      ),
      card: sampleCard(),
    );
    final ids = model.elements.map((e) => e.id).toSet();
    expect(ids.contains('brand'), isFalse);
    expect(ids.contains('pass'), isFalse);
    expect(ids.contains('qr'), isFalse);
    // Meta line skips hotspot+serial → empty → element not emitted
    expect(ids.contains('meta'), isFalse);
    // user, title, footer, accent still present
    expect(ids.containsAll({'accent', 'title', 'user', 'footer'}), isTrue);
  });

  test('background flows through (gradient + image + opacity)', () {
    final model = buildCardRenderModel(
      template(
        layoutOverrides: {
          'gradient_start': '#000000',
          'gradient_end': '#ffffff',
          'background_image_data_url': 'data:image/png;base64,abc',
          'image_opacity': 0.5,
        },
      ),
      card: sampleCard(),
    );
    expect(model.background.gradientStart, equals('#000000'));
    expect(model.background.gradientEnd, equals('#ffffff'));
    expect(model.background.hasImage, isTrue);
    expect(model.background.imageOpacity, closeTo(0.5, 0.0001));
  });

  test('builder is deterministic — same input → same model', () {
    final t = template();
    final c = sampleCard();
    final a = buildCardRenderModel(t, card: c);
    final b = buildCardRenderModel(t, card: c);
    expect(a.canvas, equals(b.canvas));
    expect(a.elements.length, equals(b.elements.length));
    for (var i = 0; i < a.elements.length; i++) {
      expect(a.elements[i].id, equals(b.elements[i].id));
    }
  });

  test('honours designer QR + per-credential styling keys', () {
    final model = buildCardRenderModel(
      template(layoutOverrides: {
        'qr_color': '#112233',
        'qr_background_color': '#fafafa',
        'qr_size_pct': 0.30,
        'credential_text_color': '#222222',
        'credential_label_color': '#888888',
        'username_surface_color': '#abcdef',
      },),
      card: sampleCard(),
    );
    final qr = model.elements.whereType<CardQr>().single;
    expect(qr.foreground, '#112233');
    expect(qr.background, '#fafafa');
    expect(qr.size, closeTo(0.30 * 1000, 0.01));
    final user =
        model.elements.whereType<CardPill>().firstWhere((e) => e.id == 'user');
    expect(user.ink, '#222222');
    expect(user.labelColor, '#888888');
    expect(user.surface, '#abcdef');
  });

  test('credential label language: default is english, arabic engine flips', () {
    // Web rule: default (no keys) resolves to the en engine -> USER/PASS.
    final latin = buildCardRenderModel(template(), card: sampleCard());
    final latinUser =
        latin.elements.whereType<CardPill>().firstWhere((e) => e.id == 'user');
    expect(latinUser.label, 'USER');

    final arabic = buildCardRenderModel(
      template(layoutOverrides: {'credential_label_language': 'arabic'}),
      card: sampleCard(),
    );
    final arUser =
        arabic.elements.whereType<CardPill>().firstWhere((e) => e.id == 'user');
    expect(arUser.label, 'اسم المستخدم');
  });

  test('portrait engine uses portrait default positions (not top-left stack)', () {
    final model = buildCardRenderModel(
      template(layoutOverrides: {'render_engine': 'en_vertical'}),
      card: sampleCard(),
    );
    expect(model.canvas, equals(const CardCanvasSize(600, 1000)));
    final user =
        model.elements.whereType<CardPill>().firstWhere((e) => e.id == 'user');
    // Portrait user pill sits at y=0.50*1000=500 (web portrait table),
    // never stacked in the top-left corner.
    expect(user.y, closeTo(0.50 * 1000, 0.01));
    expect(user.x, closeTo(0.07 * 600, 0.01));
  });

  test('logo element emitted only when a data-url logo is present', () {
    final without = buildCardRenderModel(template(), card: sampleCard());
    expect(without.elements.whereType<CardImage>(), isEmpty);

    final withLogo = buildCardRenderModel(
      template(layoutOverrides: {
        'logo_image_data_url': 'data:image/png;base64,AAAA',
        'logo_size_pct': 20,
      },),
      card: sampleCard(),
    );
    final logo = withLogo.elements.whereType<CardImage>().single;
    expect(logo.id, 'logo');
    expect(logo.width, closeTo(0.20 * 1000, 0.01));
  });

  test('arabic engine flips composition to the right (RTL)', () {
    final ltr = buildCardRenderModel(
      template(layoutOverrides: {'render_engine': 'en_horizontal'}),
      card: sampleCard(),
    );
    final rtl = buildCardRenderModel(
      template(layoutOverrides: {'render_engine': 'ar_horizontal'}),
      card: sampleCard(),
    );
    final ltrBrand =
        ltr.elements.whereType<CardText>().firstWhere((e) => e.id == 'brand');
    final rtlBrand =
        rtl.elements.whereType<CardText>().firstWhere((e) => e.id == 'brand');
    // RTL brand x is mirrored: 1 - 0.06 - 0.55 = 0.39 -> *1000.
    expect(rtlBrand.x, greaterThan(ltrBrand.x));
    expect(rtlBrand.x, closeTo((1.0 - 0.06 - 0.55) * 1000, 0.5));
  });
}
