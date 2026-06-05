import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('نص النسخ يوضح حالة جوجل درايف بدون صياغة شكلية', () {
    final backupScreen = File(
      'lib/features/backups/presentation/backups_screen.dart',
    ).readAsStringSync();
    final moreScreen = File(
      'lib/features/more/presentation/more_screen.dart',
    ).readAsStringSync();
    final navigationSchema = File(
      'lib/features/shell/navigation_schema.dart',
    ).readAsStringSync();

    expect(backupScreen, isNot(contains('جوجل درايف لاحقًا')));
    expect(moreScreen, isNot(contains('جوجل درايف لاحقًا')));
    expect(backupScreen, contains('حالة جوجل درايف'));
    expect(navigationSchema, contains('النسخ الخارجي عند تفعيله'));
  });
}
