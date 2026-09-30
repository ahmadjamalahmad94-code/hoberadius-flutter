import 'number_input.dart';

/// Hard ceiling for any single money amount (payment, extend price, loan,
/// top-up) typed in the app — the lead's FIX2 cap, the same on API, web and
/// app. Exactly 1,000,000 used to be accepted and pushed an expiry to 2711.
const double kMaxMoneyAmount = 100000;

/// Smallest amount the server records (a cent).
const double kMinMoneyAmount = 0.01;

/// «100,000» for messages.
const String kMaxMoneyAmountLabel = '100,000';

/// Arabic validation of a typed money amount: finite, ≥ 0.01, ≤ [max].
String? validateMoneyAmount(num? value, {double max = kMaxMoneyAmount}) {
  if (value == null || !value.isFinite || value <= 0) {
    return 'أدخل مبلغًا صحيحًا أكبر من صفر.';
  }
  if (value < kMinMoneyAmount) {
    return 'أقل مبلغ 0.01.';
  }
  if (value > max) {
    return 'المبلغ كبير جدًا — الحدّ الأعلى ${max == kMaxMoneyAmount ? kMaxMoneyAmountLabel : max.toStringAsFixed(0)}.';
  }
  return null;
}

/// A TYPED money amount (Arabic or Latin digits, «,» or «.» decimals):
/// the parsed value, or an Arabic error — empty / not a number / ≤ 0 /
/// above [kMaxMoneyAmount] (the owner's 100,000 cap).
({double? value, String? error}) readMoneyInput(String raw) {
  final v = parseDecimalInput(raw);
  if (v == null) {
    return (value: null, error: 'أدخل مبلغًا صحيحًا أكبر من صفر.');
  }
  final err = validateMoneyAmount(v);
  return (value: err == null ? v : null, error: err);
}

/// Helper text under a money field: the cap, said up front.
const String kMaxMoneyHelper = 'الحدّ الأعلى $kMaxMoneyAmountLabel';

/// Longest extension ONE operation may add: a year (owner decision
/// 2026-09-29) — a duration, a set-expiry jump, a paid amount turned into
/// time, or a loan. Repeat the extension for more.
const int kMaxExtendDays = 365;

/// The owner's wording for [kMaxExtendDays] (the server's 422 is the same).
const String kMaxExtendMessage =
    'أقصى تمديد في المرة الواحدة سنة — كرّر التمديد إن احتجت أكثر';

/// [kMaxExtendMessage] — the owner's exact text, no added «.» (f03 N5) —
/// when [minutes] (added in one go) pass a year.
String? validateExtendSpan(int minutes) =>
    minutes > kMaxActionMinutes ? kMaxExtendMessage : null;

/// [kMaxExtendDays] in minutes.
const int kMaxActionMinutes = kMaxExtendDays * 1440;

/// The server refuses any computed expiry after this year.
const int kMaxExpiryYear = 2100;

/// Arabic message when a computed expiry passes [kMaxExpiryYear].
const String kExpiryTooFarMessage = 'المدة الناتجة تتجاوز الحدّ المسموح';
