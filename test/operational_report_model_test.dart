import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/operational_reports/domain/operational_report_model.dart';

void main() {
  test('OperationalReportSnapshot parses report payload', () {
    final snapshot = OperationalReportSnapshot.fromJson({
      'slug': 'sessions',
      'count': 1,
      'query': 'ahmad',
      'limit': 100,
      'offset': 0,
      'items': [
        {
          'username': 'ahmad',
          'acctsessionid': 's1',
          'payload': {'password': '[redacted]'},
        },
      ],
    });

    expect(snapshot.slug, 'sessions');
    expect(snapshot.count, 1);
    expect(snapshot.query, 'ahmad');
    expect(snapshot.items.single['username'], 'ahmad');
    expect(snapshot.items.single['payload'], isA<Map<String, dynamic>>());
  });

  test('Operational reports screen exposes all web operational report slugs', () {
    final screen = File(
      'lib/features/operational_reports/presentation/operational_reports_screen.dart',
    ).readAsStringSync();

    for (final slug in [
      'sessions',
      'failed-logins',
      'login-states',
      'login-status',
      'mac-history',
      'profile-changes',
      'api-messages',
      'coa-failures',
      'manager-events',
      'manager-login-status',
      'user-events',
      'speed-failures',
      'used-cards',
      'balance-movements',
      'cash-transactions',
    ]) {
      expect(screen, contains("'$slug'"));
    }
  });
}
