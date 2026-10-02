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

  test('displayLabel never exposes the raw setting key', () {
    SettingItem item(String key, String label) => SettingItem.fromJson(
          {'key': key, 'label': label, 'value': '', 'default': ''},
        );
    expect(item('system.name', 'اسم النظام').displayLabel, 'اسم النظام');
    // Missing / raw / key-shaped labels fall back to Arabic, never the key.
    expect(item('system.name', '').displayLabel, 'إعداد النظام');
    expect(
      item('branding.logo_url', 'branding.logo_url').displayLabel,
      'إعداد الهويّة',
    );
    expect(
      item('limits.max_x', 'limits.max_x.unlimited').displayLabel,
      'إعداد الحدود',
    );
    expect(item('zzz.unknown', '').displayLabel, 'إعداد إضافيّ');
    for (final k in ['system.name', 'branding.logo_url', 'zzz.unknown']) {
      expect(item(k, '').displayLabel, isNot(contains('.')));
    }
  });
}
