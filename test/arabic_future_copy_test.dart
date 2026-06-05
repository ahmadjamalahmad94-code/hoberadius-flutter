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

  test('license file route opens its dedicated operational screen', () {
    final source = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(source, contains('LicenseFileScreen'));
    expect(source, contains("path: '/license-file'"));
    expect(
      source,
      isNot(
        contains(
          "path: '/license-file',\n"
          "            name: 'license-file',\n"
          "            builder: (ctx, st) => const SystemOperationsScreen(),",
        ),
      ),
    );
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

  test('status pills avoid raw backend status values in cleaned screens', () {
    final blockedByFile = {
      'lib/features/backups/presentation/backups_screen.dart': [
        'text: run.status,',
      ],
      'lib/features/card_users/presentation/card_users_screen.dart': [
        "user.isActive ? 'مفعل' : user.status",
      ],
      'lib/features/card_users/presentation/card_user_360_screen.dart': [
        "user.isActive ? 'مفعل' : user.status",
        ': purchase.status,',
      ],
      'lib/features/cards/presentation/card_batch_detail_screen.dart': [
        '_ => batch.status',
      ],
      'lib/features/payment_collection/presentation/payment_collection_screen.dart':
          [
        'text: item.status,',
      ],
      'lib/features/recycle_bin/presentation/recycle_bin_screen.dart': [
        ': item.status,',
      ],
    };

    for (final entry in blockedByFile.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final rawSnippet in entry.value) {
        expect(
          source,
          isNot(contains(rawSnippet)),
          reason: '${entry.key} still exposes raw status: $rawSnippet',
        );
      }
    }
  });
}
