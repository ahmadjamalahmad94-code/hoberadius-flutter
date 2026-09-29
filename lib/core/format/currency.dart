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

import 'bidi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Matches the server's `default_currency()` fallback (`ILS` when the
/// tenant never set `billing.currency`). It was `JOD`, which is what the
/// loading/blank state showed on ILS tenants. The effective code normally
/// comes from the server (`system.currency` of /api/admin/me or settings).
const String kDefaultCurrency = 'ILS';

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

/// One currency's share of a report total (`by_currency[]`, updated
/// servers). There is no FX rate: a mixed-currency tenant gets one number
/// per currency instead of a meaningless sum.
class CurrencyAmount {
  const CurrencyAmount(this.currency, this.amount);
  final String currency;
  final double amount;
}

/// Reads `by_currency` rows, taking the first present of [fields].
List<CurrencyAmount> parseByCurrency(
  Object? raw, {
  List<String> fields = const ['total', 'total_amount', 'outstanding'],
}) {
  if (raw is! List) return const [];
  final out = <CurrencyAmount>[];
  for (final row in raw.whereType<Map>()) {
    Object? v;
    for (final f in fields) {
      if (row[f] != null) {
        v = row[f];
        break;
      }
    }
    final n = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    if (n == null) continue;
    out.add(CurrencyAmount('${row['currency'] ?? ''}'.toUpperCase(), n));
  }
  return out;
}

/// «1,200 ILS · 30 USD» for a mixed-currency total. Each «amount CUR» is an
/// LTR isolate so RTL text does not scramble the order (r09 N7: «ILS ·
/// 426.31 USD · 420.10 EUR 5,905.48»).
String formatByCurrency(List<CurrencyAmount> parts) => parts
    .map((p) => ltrIsolate(formatWithCurrency(p.amount, p.currency)))
    .join(' · ');

/// One currency → «1,200 ILS»; several → [formatByCurrency]; none → «0».
String formatCurrencyList(List<CurrencyAmount> parts, {String fallback = ''}) {
  if (parts.isEmpty) return ltrIsolate(formatWithCurrency(0, fallback));
  if (parts.length == 1) {
    return ltrIsolate(formatWithCurrency(parts.single.amount, parts.single.currency));
  }
  return formatByCurrency(parts);
}

/// `system.currency` from /api/admin/me (or the login answer), written by
/// the auth controller at session restore — available before the settings
/// page loads. Empty on older servers / signed out.
final sessionCurrencyProvider = StateProvider<String>((ref) => '');
