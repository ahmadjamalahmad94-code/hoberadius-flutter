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
