import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/print_templates/domain/card_render_model.dart';
import 'package:hoberadius_app/features/print_templates/domain/card_render_model_builder.dart';

/// Parity test: a freshly-created print template (no custom drag
/// positions) MUST render through the unified renderer at the
/// canonical `_DEFAULT_POSITIONS` — i.e. the designer form's
/// `_ux`/`_uy`/`_px`/`_py`/`_qx`/`_qy` defaults must be `0` so the
/// `_resolvePositions` fallback in card_render_model_builder.dart
/// kicks in.
///
/// If anyone reverts the form defaults back to 10/15/10/25/60/12,
/// the renderer will treat them as real mm coords and the Flutter
/// preview will drift visibly from the web export center.
void main() {
  test('default-coord template lands on canonical _DEFAULT_POSITIONS', () {
    final template = {
      'id': 1,
      'username_x': 0,
      'username_y': 0,
      'password_x': 0,
      'password_y': 0,
      'qr_x': 0,
      'qr_y': 0,
      'layout_json': const <String, dynamic>{
        'card_orientation': 'horizontal',
        'card_width_mm': 85,
        'card_height_mm': 54,
        'brand_name': 'HobeRadius',
        'card_title': 'بطاقة إنترنت',
      },
    };
    final model = buildCardRenderModel(
      template,
      card: const {'id': 1, 'username': 'CARD1234', 'password': 'pw'},
    );

    final user = model.elements.whereType<CardPill>().firstWhere(
          (e) => e.id == 'user',
        );
    final pass = model.elements.whereType<CardPill>().firstWhere(
          (e) => e.id == 'pass',
        );
    final qr = model.elements.whereType<CardQr>().single;

    // _DEFAULT_POSITIONS values on the 1000x600 canvas:
    //   user x = 6%, y = 50%
    //   pass x = 6%, y = 66%
    //   qr   x = 66%, y = 36%, size = 27%
    expect(user.x, closeTo(60.0, 0.0001));
    expect(user.y, closeTo(300.0, 0.0001));
    expect(pass.x, closeTo(60.0, 0.0001));
    expect(pass.y, closeTo(396.0, 0.0001));
    expect(qr.x, closeTo(660.0, 0.0001));
    expect(qr.y, closeTo(216.0, 0.0001));
    expect(qr.size, closeTo(270.0, 0.0001));
  });

  test('non-zero coords map to canvas fractions (drag custom path)', () {
    // The drag handles in the designer write non-zero mm values. The
    // renderer then translates them back into canvas units via
    // `_resolvePositions`. This guards against the legacy bug where
    // drag updates and the rendered preview disagreed.
    final template = {
      'id': 1,
      'username_x': 17,
      'username_y': 27,
      'password_x': 0,
      'password_y': 0,
      'qr_x': 0,
      'qr_y': 0,
      'layout_json': const <String, dynamic>{
        'card_orientation': 'horizontal',
        'card_width_mm': 85,
        'card_height_mm': 54,
      },
    };
    final model = buildCardRenderModel(
      template,
      card: const {'id': 1, 'username': 'u', 'password': 'p'},
    );
    final user = model.elements.whereType<CardPill>().firstWhere(
          (e) => e.id == 'user',
        );
    // 17 / 85 = 0.2 → 0.2 * 1000 = 200
    // 27 / 54 = 0.5 → 0.5 * 600  = 300
    expect(user.x, closeTo(200.0, 0.0001));
    expect(user.y, closeTo(300.0, 0.0001));
  });
}
