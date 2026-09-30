import 'number_input.dart';

export 'number_input.dart' show formatNumberBound;

/// The server's configurable caps (owner decision, fix3): `system.limits`
/// of `/api/admin/me` and `/api/v1/settings`. Every cap the app checks
/// before sending — money amounts, one extension, the expiry year, cards
/// per batch — comes from here. An OLDER server without `system.limits`
/// (or a missing / invalid field) keeps the fixed defaults below, which are
/// the server's own defaults.
class AppLimits {
  AppLimits._();

  static const int defaultMaxExtendDays = 365;
  static const double defaultMaxAmount = 100000;
  static const int defaultMaxExpiryYear = 2100;
  static const int defaultMaxCardsPerBatch = 10000;

  static int maxExtendDays = defaultMaxExtendDays;
  static double maxSubscriberPayment = defaultMaxAmount;
  static double maxSubscriberBalanceAdd = defaultMaxAmount;
  static double maxDistributorBalanceAdd = defaultMaxAmount;
  static double maxLoanAmount = defaultMaxAmount;
  static double maxAmountGeneric = defaultMaxAmount;
  static int maxExpiryYear = defaultMaxExpiryYear;
  static int maxCardsPerBatch = defaultMaxCardsPerBatch;

  /// Bumped on every change (widgets/tests can compare).
  static int revision = 0;

  /// Reads `system.limits` of a /me or settings payload (or a bare
  /// `limits` map). Returns false when the payload has none (older server):
  /// the current values are then left as they are.
  static bool configureFrom(Map<String, dynamic> data) {
    Object? limits = data['limits'];
    final system = data['system'];
    if (system is Map && system['limits'] is Map) limits = system['limits'];
    if (limits is! Map) return false;
    num? read(String key) {
      final v = limits as Map;
      final raw = v[key];
      final n = raw is num ? raw : num.tryParse('${raw ?? ''}');
      return n != null && n.isFinite && n > 0 ? n : null;
    }

    maxExtendDays = read('max_extend_days')?.toInt() ?? defaultMaxExtendDays;
    maxAmountGeneric =
        read('max_amount_generic')?.toDouble() ?? defaultMaxAmount;
    maxSubscriberPayment =
        read('max_subscriber_payment')?.toDouble() ?? maxAmountGeneric;
    maxSubscriberBalanceAdd =
        read('max_subscriber_balance_add')?.toDouble() ?? maxAmountGeneric;
    maxDistributorBalanceAdd =
        read('max_distributor_balance_add')?.toDouble() ?? maxAmountGeneric;
    maxLoanAmount = read('max_loan_amount')?.toDouble() ?? maxAmountGeneric;
    maxExpiryYear = read('max_expiry_year')?.toInt() ?? defaultMaxExpiryYear;
    maxCardsPerBatch =
        read('max_cards_per_batch')?.toInt() ?? defaultMaxCardsPerBatch;
    revision++;
    return true;
  }

  /// Back to the defaults (sign-out, tests).
  static void reset() {
    maxExtendDays = defaultMaxExtendDays;
    maxSubscriberPayment = defaultMaxAmount;
    maxSubscriberBalanceAdd = defaultMaxAmount;
    maxDistributorBalanceAdd = defaultMaxAmount;
    maxLoanAmount = defaultMaxAmount;
    maxAmountGeneric = defaultMaxAmount;
    maxExpiryYear = defaultMaxExpiryYear;
    maxCardsPerBatch = defaultMaxCardsPerBatch;
    revision++;
  }
}

/// Which configured money cap applies to an amount.
enum MoneyCap {
  /// Any other single amount (`max_amount_generic`).
  generic,

  /// A subscriber payment (`max_subscriber_payment`).
  subscriberPayment,

  /// Balance added to a subscriber (`max_subscriber_balance_add`).
  subscriberBalanceAdd,

  /// A distributor balance / settlement movement
  /// (`max_distributor_balance_add`).
  distributorBalanceAdd,

  /// A loan amount (`max_loan_amount`).
  loanAmount,
}

/// The configured ceiling for [cap].
double moneyCapOf(MoneyCap cap) => switch (cap) {
      MoneyCap.generic => AppLimits.maxAmountGeneric,
      MoneyCap.subscriberPayment => AppLimits.maxSubscriberPayment,
      MoneyCap.subscriberBalanceAdd => AppLimits.maxSubscriberBalanceAdd,
      MoneyCap.distributorBalanceAdd => AppLimits.maxDistributorBalanceAdd,
      MoneyCap.loanAmount => AppLimits.maxLoanAmount,
    };

/// Hard ceiling for any single money amount typed in the app — the
/// server's `max_amount_generic` (100,000 by default).
double get kMaxMoneyAmount => AppLimits.maxAmountGeneric;

/// Smallest amount the server records (a cent).
const double kMinMoneyAmount = 0.01;

/// The generic cap for messages («100,000»).
String get kMaxMoneyAmountLabel => formatNumberBound(kMaxMoneyAmount);

/// «المبلغ كبير جدًا — الحدّ الأعلى N.» quoting the configured cap.
String moneyTooLargeMessage(num max) =>
    'المبلغ كبير جدًا — الحدّ الأعلى ${formatNumberBound(max)}.';

/// Arabic validation of a typed money amount: finite, ≥ 0.01, ≤ the
/// configured cap of [cap] (or an explicit [max]).
String? validateMoneyAmount(
  num? value, {
  double? max,
  MoneyCap cap = MoneyCap.generic,
}) {
  final ceiling = max ?? moneyCapOf(cap);
  if (value == null || !value.isFinite || value <= 0) {
    return 'أدخل مبلغًا صحيحًا أكبر من صفر.';
  }
  if (value < kMinMoneyAmount) {
    return 'أقل مبلغ 0.01.';
  }
  if (value > ceiling) return moneyTooLargeMessage(ceiling);
  return null;
}

/// A TYPED money amount (Arabic or Latin digits, «,» or «.» decimals):
/// the parsed value, or an Arabic error — empty / not a number / ≤ 0 /
/// above the configured cap of [cap].
({double? value, String? error}) readMoneyInput(
  String raw, {
  MoneyCap cap = MoneyCap.generic,
}) {
  final v = parseDecimalInput(raw);
  if (v == null) {
    return (value: null, error: 'أدخل مبلغًا صحيحًا أكبر من صفر.');
  }
  final err = validateMoneyAmount(v, cap: cap);
  return (value: err == null ? v : null, error: err);
}

/// Helper text under a money field: the cap, said up front.
String get kMaxMoneyHelper => moneyCapHelper(MoneyCap.generic);

/// «الحدّ الأعلى N» for [cap].
String moneyCapHelper(MoneyCap cap) =>
    'الحدّ الأعلى ${formatNumberBound(moneyCapOf(cap))}';

/// Longest extension ONE operation may add — `max_extend_days` (a year by
/// default, owner decision 2026-09-29): a duration, a set-expiry jump, a
/// paid amount turned into time, a loan, or a new subscriber's expiry.
int get kMaxExtendDays => AppLimits.maxExtendDays;

/// The owner's wording for the default year (the server's 422 is the same).
const String kOneYearExtendMessage =
    'أقصى تمديد في المرة الواحدة سنة — كرّر التمديد إن احتجت أكثر';

/// The extension-cap message quoting the configured value: the owner's
/// exact text for 365 days, else «أقصى تمديد في المرة الواحدة N يومًا — …».
String get kMaxExtendMessage => extendCapMessage(AppLimits.maxExtendDays);

String extendCapMessage(int days) => days == 365
    ? kOneYearExtendMessage
    : 'أقصى تمديد في المرة الواحدة $days يومًا — كرّر التمديد إن احتجت أكثر';

/// [kMaxExtendMessage] — no added «.» (f03 N5) — when [minutes] (added in
/// one go) pass the configured cap.
String? validateExtendSpan(int minutes) =>
    minutes > kMaxActionMinutes ? kMaxExtendMessage : null;

/// [kMaxExtendDays] in minutes.
int get kMaxActionMinutes => kMaxExtendDays * 1440;

/// The server refuses any computed expiry after this year
/// (`max_expiry_year`).
int get kMaxExpiryYear => AppLimits.maxExpiryYear;

/// The last day a date picker offers.
DateTime get kLastPickableDate => DateTime(kMaxExpiryYear, 12, 31);

/// Arabic message when a computed expiry passes [kMaxExpiryYear].
const String kExpiryTooFarMessage = 'المدة الناتجة تتجاوز الحدّ المسموح';

/// The configured cap for a NEW subscriber's expiry (the 1-year rule now
/// applies on create too): at most [kMaxExtendDays] from [now] (+1 minute
/// of grace, as the server). Null when fine or no date.
String? validateNewSubscriberExpiry(DateTime? expiry, DateTime now) {
  if (expiry == null) return null;
  if (expiry.year > kMaxExpiryYear) return '$kExpiryTooFarMessage.';
  final minutes = expiry.difference(now).inMinutes;
  return minutes > kMaxActionMinutes + 1 ? kMaxExtendMessage : null;
}
