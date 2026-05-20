import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/print_templates/domain/print_template_model.dart';

void main() {
  test('CardPrintTemplate parses saved layout fields', () {
    final template = CardPrintTemplate.fromJson({
      'id': '4',
      'name': 'Landscape cards',
      'orientation': 'landscape',
      'cards_per_row': '3',
      'cards_per_column': 4,
      'page_size': 'A4',
      'show_qr': 1,
      'username_x': '10.5',
      'username_y': 15,
      'password_x': 10,
      'password_y': '25',
      'qr_x': '60',
      'qr_y': 12,
      'font_size': '11',
      'color': '#1f2937',
      'layout_json': {'card_width_mm': 85, 'card_height_mm': 54},
      'created_at': '2026-05-20T12:00:00Z',
    });

    expect(template.id, 4);
    expect(template.cardsPerPage, 12);
    expect(template.showQr, isTrue);
    expect(template.usernameX, 10.5);
    expect(template.layout['card_width_mm'], 85);
  });

  test('PrintTemplatePreview makes export status explicit', () {
    final preview = PrintTemplatePreview.fromJson({
      'template': {
        'id': 5,
        'name': 'small',
        'cards_per_row': 2,
        'cards_per_column': 5,
        'show_qr': true,
      },
      'preview': {
        'renderer': 'visual_card_preview',
        'cards_per_page': '12',
        'qr_supported': true,
        'card': {
          'width_mm': 85,
          'height_mm': 54,
          'font_size': 12,
          'color': '#1f2937',
        },
        'placements': {
          'username': {'x_percent': 12, 'y_percent': 28},
        },
        'sample': {'username': 'QA123'},
      },
      'export_generated': false,
    });

    expect(preview.template.name, 'small');
    expect(preview.renderer, 'visual_card_preview');
    expect(preview.cardsPerPage, 12);
    expect(preview.card['width_mm'], 85);
    expect((preview.placements['username'] as Map)['x_percent'], 12);
    expect(preview.exportGenerated, isFalse);
    expect(preview.sample['username'], 'QA123');
  });
}
