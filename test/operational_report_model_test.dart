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
}
