import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main Flutter screens avoid vague future copy', () {
    final files = [
      'lib/features/communications/presentation/communications_screen.dart',
      'lib/features/mikrotik/presentation/mikrotik_screen.dart',
      'lib/features/print_templates/presentation/widgets/template_list.dart',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('لاحقًا')));
      expect(source, isNot(contains('قريبًا')));
    }
  });

  test('production router does not expose development gallery route', () {
    final source = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(source, isNot(contains("path: '/_gallery'")));
    expect(source, isNot(contains('WidgetGalleryScreen')));
    expect(source, isNot(contains('atGallery')));
  });

  test('operator-facing copy avoids old English fallback labels', () {
    final files = [
      'lib/features/backups/presentation/backups_screen.dart',
      'lib/features/more/presentation/more_screen.dart',
      'lib/features/print_templates/presentation/widgets/template_preview_card.dart',
      'lib/features/print_templates/presentation/widgets/template_form.dart',
      'lib/features/print_templates/presentation/desktop/template_chips_column.dart',
      'lib/features/subscribers/presentation/widgets/subscriber_form_sections.dart',
    ];
    final blocked = [
      'Google Drive غير مفعل',
      'Rate Limit',
      "label: 'renderer'",
      "label: 'cards/page'",
      "label: 'export'",
      'PDF available',
      'QR X',
      'QR Y',
      'PDF عينة',
      'IP أو hostname',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      for (final term in blocked) {
        expect(source, isNot(contains(term)), reason: '$path still has $term');
      }
    }
  });
}
