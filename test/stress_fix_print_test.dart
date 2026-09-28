import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/print/data/quick_print_repository.dart';
import 'package:hoberadius_app/features/cards/print/domain/quick_print_form.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _tpl({bool light = false}) => {
      'id': 9,
      'name': 'st07',
      'username_x': 10,
      if (light) 'has_background_image': true,
      'layout_json': {
        'design_preset': 'modern',
        'brand_name': 'st07 نت',
        'footer_text': 'Keep this card safe',
        'price_text': '5 ₪',
        'gradient_start': '#112233',
        'gradient_end': '#445566',
        'credential_label_font_size': 11,
        'surface_opacity': 0.4,
        if (!light) 'background_image_data_url': 'data:image/png;base64,AAAA',
        if (light) 'has_background_image': true,
      },
    };

void main() {
  test('13: quick-save sends the loaded brand/footer/price/colours back', () {
    final form = QuickPrintForm.fromTemplate(_tpl());
    final f = form.toFields();
    expect(f['brand_name'], 'st07 نت');
    expect(f['footer_text'], 'Keep this card safe');
    expect(f['price_text'], '5 ₪');
    expect(f['gradient_start'], '#112233');
    expect(f['gradient_end'], '#445566');
    expect(f['credential_label_font_size'], '11');
    expect(f['surface_opacity'], '0.4');
    // the fields the quick form edits still win
    final edited = form.copyWith(usernameX: 22).toFields();
    expect(edited['username_x'], '22');
  });

  test('13: switching the preset drops the old preset colours only', () {
    final form = QuickPrintForm.fromTemplate(_tpl()).copyWith(
      designPreset: 'classic',
    );
    final f = form.toFields();
    expect(f.containsKey('gradient_start'), isFalse);
    expect(f['brand_name'], 'st07 نت');
  });

  test('13: light template list → image state from the flag', () {
    final light = QuickPrintForm.fromTemplate(_tpl(light: true));
    expect(light.backgroundDataUrl, isEmpty);
    expect(light.hasImage, isTrue);
    expect(needsFullTemplate(_tpl(light: true)), isTrue);
    expect(needsFullTemplate(_tpl()), isFalse);
  });

  test('13: a light row is completed with GET /print-templates/<id>', () async {
    final adapter = RecordingAdapter(
      (r) => FakeResponse.ok({'template': _tpl()}),
    );
    final repo = QuickPrintRepository(fakeApiClient(adapter));
    final full = await repo.fullTemplate(_tpl(light: true));
    expect(adapter.requests.single.path, '/api/v1/print-templates/9');
    expect(
      (full!['layout_json'] as Map)['background_image_data_url'],
      startsWith('data:image/'),
    );
    // an old server's full row needs no extra request
    await repo.fullTemplate(_tpl());
    expect(adapter.requests, hasLength(1));
  });

  test('13: old server without the endpoint → keeps the list row', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.error(405, 'method_not_allowed', 'x'),
    );
    final repo = QuickPrintRepository(fakeApiClient(adapter));
    final row = _tpl(light: true);
    expect(await repo.fullTemplate(row), same(row));
  });
}
