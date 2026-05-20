import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/saas_modules/domain/saas_module_model.dart';

void main() {
  test('SaasModuleSnapshot parses module records and stats', () {
    final snapshot = SaasModuleSnapshot.fromJson({
      'items': [
        {'id': 7, 'name': 'API pool', 'enabled': true},
      ],
      'count': 1,
      'stats': {'active': 1},
    });

    expect(snapshot.count, 1);
    expect(snapshot.stats['active'], 1);
    expect(snapshot.items.single.id, 7);
    expect(snapshot.items.single.text('enabled'), 'نعم');
    expect(snapshot.items.single.text('missing'), 'غير محدد');
  });
}
