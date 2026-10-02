import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';

void main() {
  group('normalizeCurrency', () {
    test('blank/null falls back to ILS (matches default_currency())', () {
      expect(normalizeCurrency(null), 'ILS');
      expect(normalizeCurrency(''), 'ILS');
      expect(normalizeCurrency('   '), 'ILS');
      expect(kDefaultCurrency, 'ILS');
    });

    test('upper-cases and trims like the server', () {
      expect(normalizeCurrency('ils'), 'ILS');
      expect(normalizeCurrency(' usd '), 'USD');
    });
  });

  group('tenantCurrencyProvider', () {
    SettingsSnapshot snapshotWith(Map<String, String> settings) =>
        SettingsSnapshot(items: const [], settings: settings);

    test('falls back to ILS while settings are loading', () {
      final container = ProviderContainer(
        overrides: [
          // Never-completing future keeps the provider in loading state.
          settingsProvider
              .overrideWith((ref) => Completer<SettingsSnapshot>().future),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(tenantCurrencyProvider), 'ILS');
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

    test('absent billing.currency key resolves to ILS', () async {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            (ref) async => snapshotWith({'site.name': 'Demo'}),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.future);
      expect(container.read(tenantCurrencyProvider), 'ILS');
    });
  });

  // Owner 2026-10-01: the shekel is shown as «₪» everywhere (web parity),
  // never «ILS»; every other currency keeps its ISO code. Display only.
  group('currencyDisplay / shekel symbol', () {
    test('ILS (any case/padding) → ₪, others upper-cased code', () {
      expect(currencyDisplay('ILS'), '₪');
      expect(currencyDisplay(' ils '), '₪');
      expect(currencyDisplay('jod'), 'JOD');
      expect(currencyDisplay('USD'), 'USD');
      expect(currencyDisplay(''), '');
      expect(currencyDisplay(null), '');
      expect(isShekelCode('ils'), isTrue);
      expect(isShekelCode('JOD'), isFalse);
    });

    test('the values stay codes (no symbol leaks into normalize)', () {
      expect(normalizeCurrency('ils'), 'ILS');
      expect(kSupportedCurrencies, contains('ILS'));
      expect(kSupportedCurrencies.contains('₪'), isFalse);
    });

    test('formatWithCurrency: amount then symbol, one LTR isolate', () {
      final s = formatWithCurrency(1112.8, 'ILS');
      expect(s, ltrIsolate('1,112.80 ₪'));
      expect(s.startsWith(kLtrIsolate), isTrue);
      expect(s.endsWith(kPopIsolate), isTrue);
      expect(stripBidiMarks(formatWithCurrency(20, 'ils')), '20 ₪');
      expect(stripBidiMarks(formatWithCurrency(7.5, 'JOD')), '7.50 JOD');
      expect(stripBidiMarks(formatWithCurrency(-3, 'ILS')), '-3 ₪');
      expect(formatWithCurrency(20, ''), '20');
      expect(formatWithCurrency(double.infinity, 'ILS'), '—');
      expect(
        formatWithCurrency(5, 'ILS', isolate: false),
        '5 ₪',
      );
    });

    test('amountWithCurrencyCode: strings from the API', () {
      expect(stripBidiMarks(amountWithCurrencyCode('12.50', 'ILS')), '12.50 ₪');
      expect(stripBidiMarks(amountWithCurrencyCode('3', 'USD')), '3 USD');
      expect(amountWithCurrencyCode('', 'ILS'), '₪');
      expect(amountWithCurrencyCode('9', ''), '9');
      expect(amountWithCurrencyCode('5', 'ILS', isolate: false), '5 ₪');
    });

    test('per-currency totals use the symbol for ILS only', () {
      final parts = parseByCurrency([
        {'currency': 'ils', 'total': 5905.48},
        {'currency': 'USD', 'total': 426.31},
      ]);
      // parsing keeps the CODE; only the text shows the symbol.
      expect(parts.first.currency, 'ILS');
      expect(
        stripBidiMarks(formatByCurrency(parts)),
        '5,905.48 ₪ · 426.31 USD',
      );
      expect(
        stripBidiMarks(formatCurrencyList(const [], fallback: 'ILS')),
        '0 ₪',
      );
    });

    test('ltrIsolate is idempotent on an already isolated money text', () {
      final once = formatWithCurrency(20, 'ILS');
      expect(ltrIsolate(once), once);
      // two isolates side by side are still wrapped as one unit
      final two = '${ltrIsolate('a')} ${ltrIsolate('b')}';
      expect(ltrIsolate(two), '$kLtrIsolate$two$kPopIsolate');
    });
  });
}
