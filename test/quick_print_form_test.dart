import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/print/domain/quick_print_form.dart';

/// «طباعة الكروت» sends the web «منشئ كروت PDF» fields; the server runs the
/// web builder on them. These pin the web template's prefill/defaults so the
/// app never drifts from what the web would save/print (2026-09-28).
void main() {
  test('new design = web defaults', () {
    final f = QuickPrintForm.fromTemplate(null).toFields();
    expect(f['name'], 'قالب سريع');
    expect(f['font_size_unit'], 'pt');
    expect(f['image_fit'], 'stretch');
    expect(f['background_style'], 'image');
    expect(f['render_engine'], 'ar_vertical');
    expect(f['card_width_mm'], '54');
    expect(f['card_height_mm'], '85.6');
    expect(f['design_preset'], 'modern');
    expect(f['hotspot_address'], 'hotspot.local');
    expect(f['show_username'], '1');
    expect(f['show_password'], '1');
    expect(f['show_qr'], '0');
    expect(f['show_price'], '0');
    // «خلفية خلف الأرقام» defaults on, colour #e8f7fb on all three.
    expect(f['credential_background_enabled'], '1');
    expect(f['username_surface_color'], '#e8f7fb');
    expect(f['surface_color'], '#e8f7fb');
    // Font sizes empty = «تلقائي»; positions 0 = automatic.
    expect(f['username_font_size'], '');
    expect(f['username_x'], '0');
  });

  test('saved template prefill mirrors {{ fl.x or default }}', () {
    final tpl = {
      'id': 7,
      'name': 'المسجد',
      'username_x': 6.5,
      'qr_y': 12,
      'layout_json': {
        'render_engine': 'ar_horizontal',
        'card_width_mm': 85.6,
        'card_height_mm': 54,
        'username_font_size': 14,
        'show_qr': true,
        'hotspot_login_url': 'http://10.5.50.1',
        'credential_background_enabled': false,
        'surface_color': '#fde68a',
        'background_image_data_url': 'data:image/jpeg;base64,AAA',
        'background_image_name': 'bg.jpg',
      },
    };
    final form = QuickPrintForm.fromTemplate(tpl, fallbackLoginUrl: 'x.y');
    final f = form.toFields();
    expect(f['name'], 'المسجد');
    expect(form.vertical, isFalse);
    expect(f['card_width_mm'], '85.6');
    expect(f['username_font_size'], '14');
    expect(f['show_qr'], '1');
    // Own URL wins over the suggestion from other templates.
    expect(f['hotspot_login_url'], 'http://10.5.50.1');
    // No username_surface_enabled → credential_background_enabled decides.
    expect(f['username_surface_enabled'], '0');
    // username colour falls back to surface_color.
    expect(f['username_surface_color'], '#fde68a');
    expect(f['username_x'], '6.5');
    expect(f['qr_y'], '12');
    expect(form.hasImage, isTrue);
  });

  test('login URL falls back to another template only when own is empty', () {
    final form = QuickPrintForm.fromTemplate(
      {'id': 1, 'name': 'a', 'layout_json': <String, dynamic>{}},
      fallbackLoginUrl: 'http://10.0.0.1',
    );
    expect(form.hotspotLoginUrl, 'http://10.0.0.1');
  });

  test('orientation swaps W/H so the long side follows it', () {
    const v = QuickPrintForm();
    final h = v.withOrientation(false);
    expect(h.renderEngine, 'ar_horizontal');
    expect(h.cardWidthMm, 85.6);
    expect(h.cardHeightMm, 54);
    final back = h.withOrientation(true);
    expect(back.cardWidthMm, 54);
    expect(back.cardHeightMm, 85.6);
  });

  test('a new image forces image mode + stretch; colour sets all three', () {
    final f = const QuickPrintForm(backgroundStyle: 'preset', imageFit: 'cover')
        .withImage('data:image/png;base64,AA', 'x.png')
        .withSurfaceColor('#dcfce7');
    expect(f.backgroundStyle, 'image');
    expect(f.imageFit, 'stretch');
    expect(f.usernameSurfaceColor, '#dcfce7');
    expect(f.passwordSurfaceColor, '#dcfce7');
    expect(f.surfaceColor, '#dcfce7');
  });

  test('no-password batch hides the password in the preview only', () {
    expect(
        const QuickPrintForm().toFields(passwordShown: false)['show_password'],
        '0',);
  });

  test('sheet = web quick defaults and one gap for both directions', () {
    final s = QuickSheet.fromLastSettings(const {});
    expect(s.columns, 6);
    expect(s.rows, 9);
    expect(s.cutLines, isTrue);
    final m = s.copyWith(gapMm: 3).toSettings();
    expect(m['print_column_gap_mm'], '3');
    expect(m['print_row_gap_mm'], '3');
    expect(m['print_margin_mm'], '4');
    expect(m['print_page_size'], 'A4');
    expect(m['print_fit_mode'], 'stretch');
    expect(m['print_cut_lines'], '1');

    final saved = QuickSheet.fromLastSettings(const {
      'print_columns': '4',
      'print_rows': '20',
      'print_cut_lines': '0',
      'print_orientation': 'landscape',
    });
    expect(saved.columns, 4);
    expect(saved.rows, 12); // clamped to the slider range
    expect(saved.cutLines, isFalse);
    expect(saved.landscape, isTrue);
  });
}
