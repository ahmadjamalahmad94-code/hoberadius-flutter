import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/admins/domain/permission_labels.dart';

void main() {
  test('localises known permission keys and groups', () {
    expect(permissionLabel('users.view'), 'عرض المستفيدين');
    expect(permissionLabel('scope.view_passwords'), 'كشف كلمات السر');
    expect(permissionLabel('api.use'), 'استخدام الواجهة البرمجية');
    expect(permissionGroupLabel('online'), 'المتصلون الآن');
    expect(permissionGroupLabel('admin_pricing'), 'أسعار العروض');
  });

  test('unknown keys fall back safely without throwing', () {
    expect(permissionLabel('future.new_perm'), 'future.new_perm');
    expect(hasPermissionLabel('future.new_perm'), isFalse);
    // Unknown group prefers the API-provided fallback, else the prefix.
    expect(permissionGroupLabel('weird', fallback: 'مجموعة'), 'مجموعة');
    expect(permissionGroupLabel('weird'), 'weird');
  });

  test('group prefix + style resolve, unknown → general', () {
    expect(permissionGroupPrefix('cards.print'), 'cards');
    expect(permissionGroupPrefix('noDot'), 'general');
    expect(permissionGroupStyle('cards').ink, isNot(permissionGroupStyle('users').ink));
    // Unknown prefix yields the general style (same as 'general').
    expect(
      permissionGroupStyle('mystery').icon,
      permissionGroupStyle('general').icon,
    );
  });

  test('catalogue is non-trivial and covers core groups', () {
    expect(permissionLabelCount(), greaterThanOrEqualTo(50));
    for (final key in ['dashboard.view', 'users.view', 'audit.view']) {
      expect(hasPermissionLabel(key), isTrue);
    }
  });
}
