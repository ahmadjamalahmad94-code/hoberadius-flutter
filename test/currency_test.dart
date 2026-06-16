import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';

void main() {
  group('normalizeCurrency', () {
    test('blank/null falls back to JOD (matches default_currency())', () {
      expect(normalizeCurrency(null), 'JOD');
      expect(normalizeCurrency(''), 'JOD');
      expect(normalizeCurrency('   '), 'JOD');
      expect(kDefaultCurrency, 'JOD');
    });

    test('upper-cases and trims like the server', () {
      expect(normalizeCurrency('ils'), 'ILS');
      expect(normalizeCurrency(' usd '), 'USD');
    });
  });

  group('tenantCurrencyProvider', () {
    SettingsSnapshot snapshotWith(Map<String, String> settings) =>
        SettingsSnapshot(items: const [], settings: settings);

    test('falls back to JOD while settings are loading', () {
      final container = ProviderContainer(
        overrides: [
          // Never-completing future keeps the provider in loading state.
          settingsProvider.overrideWith((ref) => Completer<SettingsSnapshot>().future),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(tenantCurrencyProvider), 'JOD');
    });

    test('reads billing.currency from settings (normalised)', () async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            (ref) async => snapshotWith({'billing.currency': 'ils'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      expect(container.read(tenantCurrencyProvider), 'ILS');
    });

    test('changing the tenant currency propagates to the provider', () async {
      // First tenant configured to USD.
      final usd = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            (ref) async => snapshotWith({'billing.currency': 'USD'}),
          ),
        ],
      );
      addTearDown(usd.dispose);
      await usd.read(settingsProvider.future);
      expect(usd.read(tenantCurrencyProvider), 'USD');

      // A tenant with a different central currency resolves differently.
      final egp = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            (ref) async => snapshotWith({'billing.currency': 'EGP'}),
          ),
        ],
      );
      addTearDown(egp.dispose);
      await egp.read(settingsProvider.future);
      expect(egp.read(tenantCurrencyProvider), 'EGP');
    });

    test('absent billing.currency key resolves to JOD', () async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            (ref) async => snapshotWith({'site.name': 'Demo'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      expect(container.read(tenantCurrencyProvider), 'JOD');
    });
  });
}
