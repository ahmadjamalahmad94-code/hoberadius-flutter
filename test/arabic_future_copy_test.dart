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
}
