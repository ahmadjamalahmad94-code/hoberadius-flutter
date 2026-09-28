import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Item 4b: money is never written or labelled with a hardcoded currency —
/// the tenant/system currency comes from the server (actions-context,
/// settings) or the row itself. Only the central currency module may name
/// currency codes.
void main() {
  test('no hardcoded JOD/ILS/USD/₪ outside the currency module', () {
    const allowed = {
      'lib/core/format/currency.dart',
      'lib/core/l10n/arabic_labels.dart',
      'lib/shared/widgets/currency_field.dart', // doc comment only
    };
    final offenders = <String>[];
    final literal = RegExp(r"""['"](JOD|ILS|USD)['"]|₪""");
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (literal.hasMatch(line)) offenders.add('$path:${i + 1}: $line');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
