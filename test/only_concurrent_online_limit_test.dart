import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/provider_grants/application/provider_grants_provider.dart';
import 'package:hoberadius_app/features/provider_grants/domain/provider_grants_model.dart';

/// Owner (2026-09-28): card / device / plan / admin / template caps were
/// abolished long ago — only concurrent online sessions are limited. An old
/// license contract (e.g. client20: cards 1000, nas 3) must not show a red
/// bar or lock «حزمة جديدة» / «جهاز جديد» in the app.
void main() {
  final grants = ProviderGrants.fromJson({
    'license': {'state': 'active', 'blocks_panel': false},
    'limits': {
      'active_online': {'limit': 100, 'current': 0, 'limit_path': 'active_online.max'},
      'cards': {'limit': 1000, 'current': 3600, 'limit_path': 'cards.monthly_generated'},
      'nas': {'limit': 3, 'current': 4, 'limit_path': 'nas.max_total'},
      'profiles': {'limit': 10, 'current': 9, 'limit_path': 'profiles.max_total'},
    },
  });

  ProviderContainer container() => ProviderContainer(
        overrides: [effectiveGrantsProvider.overrideWithValue(grants)],
      );

  test('old caps in the contract are ignored', () {
    final c = container();
    addTearDown(c.dispose);
    expect(c.read(grantLimitProvider('cards')), isNull);
    expect(c.read(grantLimitProvider('nas')), isNull);
    expect(c.read(grantLimitProvider('profiles')), isNull);
    expect(c.read(grantLimitProvider('subscribers')), isNull);
  });

  test('concurrent online sessions stay the one real limit', () {
    final c = container();
    addTearDown(c.dispose);
    expect(c.read(grantLimitProvider('active_online'))?.limit, 100);
    expect(kEnforcedLimitKeys, {'active_online'});
  });
}
