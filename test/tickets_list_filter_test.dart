import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ticket list exposes every web ticket status filter', () {
    final screen =
        File('lib/features/tickets/presentation/tickets_list_screen.dart')
            .readAsStringSync();

    for (final status in [
      'open',
      'pending',
      'in_progress',
      'resolved',
      'closed',
    ]) {
      expect(screen, contains("value: '$status'"));
    }

    expect(screen, contains('مفتوحة'));
    expect(screen, contains('معلّقة'));
    expect(screen, contains('قيد المعالجة'));
    expect(screen, contains('محلولة'));
    expect(screen, contains('مغلقة'));
  });
}
