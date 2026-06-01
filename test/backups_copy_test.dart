import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup copy explains disabled Google Drive without prototype wording', () {
    final backupScreen = File(
      'lib/features/backups/presentation/backups_screen.dart',
    ).readAsStringSync();
    final moreScreen = File(
      'lib/features/more/presentation/more_screen.dart',
    ).readAsStringSync();

    expect(backupScreen, isNot(contains('Google Drive لاحقًا')));
    expect(moreScreen, isNot(contains('Google Drive لاحقًا')));
    expect(backupScreen, contains('Google Drive غير مفعل حاليًا'));
    expect(moreScreen, contains('ربط Google Drive عند تفعيله'));
  });
}
