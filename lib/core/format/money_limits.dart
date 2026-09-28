/// Hard ceiling for any single money amount typed in the app. The server
/// now rejects non-finite / absurd values too, but a 1e6 payment used to push
/// an expiry to the year 2711 and 1e9 answered HTTP 500 — the app stops it
/// before the request.
const double kMaxMoneyAmount = 1000000;

/// Arabic validation of a typed money amount: positive, finite, ≤ [max].
String? validateMoneyAmount(num? value, {double max = kMaxMoneyAmount}) {
  if (value == null || !value.isFinite || value <= 0) {
    return 'أدخل مبلغًا صحيحًا أكبر من صفر.';
  }
  if (value > max) {
    return 'المبلغ كبير جدًا — الحدّ الأعلى ${max.toStringAsFixed(0)}.';
  }
  return null;
}

/// Longest time an action may add in one go (10 years) — a typo such as
/// 99999 days produced absurd prices/expiries.
const int kMaxActionMinutes = 10 * 366 * 1440;
