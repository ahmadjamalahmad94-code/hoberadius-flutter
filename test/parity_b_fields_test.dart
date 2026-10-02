import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';
import 'package:hoberadius_app/features/admins/domain/admin_model.dart';

/// Parity-b (2026-10-02): app form fields wired like the web.
void main() {
  group('admin edit body', () {
    final original = Admin(id: 7, username: 'm', roleId: 3);

    test('an unchanged role is not re-sent (web sends none)', () {
      final body = Admin(id: 7, username: 'm', roleId: 3, phone: '0599')
          .toBody(original: original, ownerFlags: false);
      expect(body.containsKey('role_id'), isFalse);
      expect(body['phone'], '0599');
    });

    test('a changed role is sent', () {
      final body = Admin(id: 7, username: 'm', roleId: 4)
          .toBody(original: original, ownerFlags: false);
      expect(body['role_id'], 4);
    });

    test('create always sends the role', () {
      expect(Admin(username: 'n', roleId: 3).toBody()['role_id'], 3);
    });
  });

  test('role editor hides the deprecated keys (like the web)', () {
    final c = PermissionCatalog.fromJson({
      'items': ['users.view', 'dashboard.view', 'routers.view'],
      'groups': [
        {
          'key': 'users',
          'label': 'المشتركون',
          'permissions': ['users.view'],
        },
        {
          'key': 'dashboard',
          'label': 'لوحة',
          'permissions': ['dashboard.view'],
        },
        {
          'key': 'routers',
          'label': 'راوترات',
          'permissions': ['routers.view'],
        },
      ],
      'deprecated': ['dashboard.view', 'routers.view'],
    });
    expect(c.items, ['users.view']);
    expect(c.groups.map((g) => g.key), ['users']);
    expect(c.deprecated, {'dashboard.view', 'routers.view'});
  });

  group('settings dialog choices (the web select/toggle)', () {
    test('toggles are 1/0', () {
      expect(settingChoices('portal.show_usage')!.map((c) => c.$1), ['1', '0']);
      expect(
        settingChoices('limits.max_loan_amount.unlimited')!.map((c) => c.$1),
        ['1', '0'],
      );
    });

    test('currency is the web list (no free text)', () {
      final codes = settingChoices('billing.currency')!.map((c) => c.$1);
      expect(codes, contains('ILS'));
      expect(codes, contains('EUR'));
      expect(codes.length, 9);
    });

    test('enums', () {
      expect(
        settingChoices('device_limit.cards.mode')!.map((c) => c.$1),
        ['reject', 'replace'],
      );
      expect(
        settingChoices('subscribers.create_without_expiry')!.map((c) => c.$1),
        ['expired', 'unlimited'],
      );
    });

    test('free text stays free text', () {
      expect(settingChoices('system.name'), isNull);
    });
  });
}
