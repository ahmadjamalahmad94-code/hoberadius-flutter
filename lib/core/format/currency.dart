/// Central currency helpers — the Flutter mirror of the web's
/// `radius/core/system_config.default_currency()`.
///
/// The tenant's currency lives in the settings catalogue under
/// `billing.currency` (default `JOD`). Money shown anywhere must use that
/// central value, never a hardcoded `ILS`/`JOD` literal or an arbitrary
/// per-form picker. Read [tenantCurrencyProvider] in the UI; use
/// [kDefaultCurrency] as the static fallback inside pure models that cannot
/// reach Riverpod.
library;

import 'package:flutter/widgets.dart';

/// Matches the web `_DEFAULTS["billing.currency"]` fallback used by
/// `default_currency()` when the setting is unreadable.
const String kDefaultCurrency = 'JOD';

/// The settings key that holds the tenant currency (web `billing.currency`).
const String kCurrencySettingKey = 'billing.currency';

/// Currencies the web settings page advertises for `billing.currency`
/// ("JOD / ILS / USD / IQD / SAR / EGP / AED"). The tenant currency is always
/// included even if the API later adds more.
const List<String> kSupportedCurrencies = [
  'JOD',
  'ILS',
  'USD',
  'IQD',
  'SAR',
  'EGP',
  'AED',
];

/// Normalises a raw currency code to the tenant default when missing/blank,
/// upper-casing exactly like `default_currency()` does on the server.
String normalizeCurrency(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return kDefaultCurrency;
  return trimmed.toUpperCase();
}

/// The tenant currency for widgets that are not Riverpod consumers (cards
/// totals, recharge cards…). The shell provides it from
/// `tenantCurrencyProvider`; outside the shell (tests) it is empty. Replaces
/// the «₪» that was hardcoded whatever the tenant's currency.
class TenantCurrencyScope extends InheritedWidget {
  const TenantCurrencyScope({
    super.key,
    required this.code,
    required super.child,
  });

  final String code;

  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TenantCurrencyScope>()?.code ??
      '';

  @override
  bool updateShouldNotify(TenantCurrencyScope oldWidget) =>
      oldWidget.code != code;
}

/// «1,234.5 JOD» — amount + the tenant currency code (none when unknown).
String formatWithCurrency(num value, String currency) {
  final v = value.toDouble();
  // Absurd legacy values (1e308 credit limits, Infinity) are not amounts.
  if (!v.isFinite || v.abs() >= 1e15) return '—';
  final fixed =
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final grouped = _group(fixed);
  return currency.isEmpty ? grouped : '$grouped $currency';
}

String _group(String fixed) {
  final neg = fixed.startsWith('-');
  final body = neg ? fixed.substring(1) : fixed;
  final parts = body.split('.');
  final intPart = parts.first;
  final b = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) b.write(',');
    b.write(intPart[i]);
  }
  final dec = parts.length > 1 ? '.${parts[1]}' : '';
  return '${neg ? '-' : ''}$b$dec';
}
