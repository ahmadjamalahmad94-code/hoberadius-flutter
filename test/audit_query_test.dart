import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/audit/data/audit_repository.dart';

void main() {
  test('استعلام التدقيق يرسل كل الفلاتر المدعومة من الواجهة', () {
    final query = AuditQuery(
      actor: 'admin',
      action: 'update',
      targetType: 'nas',
      targetId: '17',
      limit: 50,
    );

    expect(query.toQueryParams(), {
      'limit': 50,
      'actor': 'admin',
      'action': 'update',
      'target_type': 'nas',
      'target_id': '17',
    });
  });
}
