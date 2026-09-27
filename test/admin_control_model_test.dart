import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';

void main() {
  test('SettingsSnapshot parses settings catalog', () {
    final snapshot = SettingsSnapshot.fromJson({
      'items': [
        {
          'key': 'billing.currency',
          'label': 'العملة',
          'value': 'JOD',
          'default': 'JOD',
        },
      ],
      'settings': {'billing.currency': 'JOD'},
    });

    expect(snapshot.items.single.key, 'billing.currency');
    expect(snapshot.items.single.value, 'JOD');
    expect(snapshot.settings['billing.currency'], 'JOD');
  });
}
