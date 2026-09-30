import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/core/format/server_time.dart';

import 'subscriber_model.dart';

/// What the signed-in admin may do to one subscriber — the same rules as the
/// web panel's route guards (RBAC key + manager action grant). A key the
/// server omits counts as allowed: the server stays the final authority and
/// answers 403 on its own.
class ActionPermissions {
  const ActionPermissions(this._flags);

  /// Every action allowed — old servers (no actions-context) had no
  /// per-action checks on the API.
  static const all = ActionPermissions({});

  final Map<String, bool> _flags;

  factory ActionPermissions.fromJson(Object? raw) {
    if (raw is! Map) return all;
    return ActionPermissions({
      for (final e in raw.entries)
        if (e.value is bool) e.key.toString(): e.value as bool,
    });
  }

  bool allows(String key) => _flags[key] ?? true;
}

class ActionPlan {
  const ActionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.minutes,
    this.ratePerMinute,
  });

  final int? id;
  final String name;
  final double price;

  /// Plan period in minutes (30 days = 43200).
  final int minutes;

  /// `rate_per_minute` of updated servers: the change-plan direction is
  /// decided per minute, never by the total price.
  final double? ratePerMinute;

  static ActionPlan? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return ActionPlan(
      id: _intOrNull(raw['id']),
      name: (raw['name'] ?? '').toString(),
      price: _double(raw['price']),
      minutes: _intOrNull(raw['minutes']) ?? 0,
      ratePerMinute: _doubleOrNull(raw['rate_per_minute']),
    );
  }
}

/// Price per minute of a plan (price ÷ period) — null when unknown.
double? planRatePerMinute(double price, int minutes) =>
    price > 0 && minutes > 0 ? price / minutes : null;

class OpenLoan {
  const OpenLoan({
    required this.id,
    required this.amount,
    this.days = 0,
    this.minutes = 0,
    this.currency = '',
    this.reason = '',
    this.createdAt,
  });

  final int id;
  final double amount;
  final int days;
  final int minutes;
  final String currency;
  final String reason;
  final DateTime? createdAt;

  factory OpenLoan.fromJson(Map<String, dynamic> j) {
    final minutes = _intOrNull(j['minutes']) ?? 0;
    return OpenLoan(
      id: _intOrNull(j['id']) ?? 0,
      amount: _double(j['amount']),
      days: _intOrNull(j['days']) ?? (minutes / 1440).round(),
      minutes: minutes,
      currency: (j['currency'] ?? '').toString(),
      reason: (j['reason'] ?? '').toString(),
      createdAt: parseServerUtc(j['created_at']),
    );
  }

  /// «٣ أيام» / «٥ ساعات» — the loan's length as the web chip shows it.
  String get durationLabel {
    if (days > 0) return arDays(days);
    if (minutes > 0) return arDuration(minutes);
    return '—';
  }
}

class MessageTemplate {
  const MessageTemplate({
    required this.key,
    required this.label,
    required this.text,
  });

  final String key;
  final String label;
  final String text;

  static MessageTemplate? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final text = (raw['text'] ?? '').toString();
    if (text.isEmpty) return null;
    return MessageTemplate(
      key: (raw['key'] ?? '').toString(),
      label: (raw['label'] ?? '').toString(),
      text: text,
    );
  }
}

/// The web's five ready templates (users_list.html «قوالب جاهزة») — used when
/// the server does not send its own list.
const kDefaultMessageTemplates = <MessageTemplate>[
  MessageTemplate(
    key: 'welcome',
    label: 'ترحيب',
    text: 'أهلاً {username} 👋 تم تفعيل اشتراكك بنجاح. '
        'نشكر ثقتك بنا، وأي استفسار نحن بخدمتك.',
  ),
  MessageTemplate(
    key: 'expiry',
    label: 'تذكير انتهاء',
    text: 'عزيزنا {username}، اشتراكك ({plan}) ينتهي بتاريخ {expire}. '
        'يُرجى التجديد لتفادي انقطاع الخدمة.',
  ),
  MessageTemplate(
    key: 'payment',
    label: 'تأكيد دفعة',
    text: 'تم استلام دفعتك وتجديد اشتراكك بنجاح ✅ شكرًا لك.',
  ),
  MessageTemplate(
    key: 'dues',
    label: 'تذكير سداد',
    text: 'عزيزنا {username}، لديكم مستحقات على الاشتراك. '
        'يُرجى المراجعة لتسوية الحساب. شكرًا.',
  ),
  MessageTemplate(
    key: 'maintenance',
    label: 'صيانة',
    text: 'إشعار صيانة: سنعمل على تحسين الشبكة وقد تنقطع الخدمة مؤقتًا. '
        'نعتذر عن الإزعاج.',
  ),
];

/// Everything the action dialogs need (GET /accounts/<u>/actions-context).
class SubscriberActionsContext {
  const SubscriberActionsContext({
    required this.username,
    this.fullName = '',
    this.status = 'enabled',
    this.expireAt,
    this.currency = '',
    this.plan,
    this.effectivePrice = 0,
    this.balance = 0,
    this.debt = 0,
    this.openLoans = const [],
    this.hasQuota = false,
    this.dailyQuotaMb,
    this.usedTodayMb,
    this.quotaWindows = const [],
    this.quotaUsage = const [],
    this.onlineSessions = 0,
    this.smsEnabled = true,
    this.whatsappEnabled = false,
    this.templates = kDefaultMessageTemplates,
    this.maxFreeLoanHours = 72,
    this.maxDebtLoanDays = 366,
    this.permissions = ActionPermissions.all,
    this.legacy = false,
  });

  final String username;
  final String fullName;
  final String status;

  /// Local time (parsed from the server's UTC).
  final DateTime? expireAt;
  final String currency;
  final ActionPlan? plan;

  /// Custom price or plan price — what the web prices time with.
  final double effectivePrice;
  final double balance;
  final double debt;
  final List<OpenLoan> openLoans;
  final bool hasQuota;
  final double? dailyQuotaMb;
  final double? usedTodayMb;

  /// Where a top-up can go on this subscriber (updated servers:
  /// `quota.quota_mb`, `quota.monthly`, `quota.daily`): `total`, `monthly`,
  /// `daily`. Empty on older servers (the server decides).
  final List<String> quotaWindows;

  /// Caps and usage per window, ready to show («اليوم: 150 / 200 MB»).
  final List<String> quotaUsage;
  final int onlineSessions;
  final bool smsEnabled;
  final bool whatsappEnabled;
  final List<MessageTemplate> templates;
  final int maxFreeLoanHours;
  final int maxDebtLoanDays;
  final ActionPermissions permissions;

  /// `true` when the server has no actions-context endpoint (not updated
  /// yet): only the actions the old API supports can run.
  final bool legacy;

  String get displayName => fullName.isEmpty ? username : fullName;
  String get planName => plan?.name ?? '';
  int get planMinutes => plan?.minutes ?? 0;
  bool get isDisabled => status == 'disabled';

  factory SubscriberActionsContext.fromJson(Map<String, dynamic> j) {
    final quota = j['quota'] is Map ? j['quota'] as Map : const {};
    final channels = j['channels'] is Map ? j['channels'] as Map : const {};
    final loans = j['open_loans'] is List ? j['open_loans'] as List : const [];
    final tpls = j['message_templates'] is List
        ? (j['message_templates'] as List)
            .map(MessageTemplate.fromJson)
            .whereType<MessageTemplate>()
            .toList()
        : const <MessageTemplate>[];
    final plan = ActionPlan.fromJson(j['plan']);
    return SubscriberActionsContext(
      username: (j['username'] ?? '').toString(),
      fullName: (j['full_name'] ?? '').toString(),
      status: (j['status'] ?? 'enabled').toString(),
      expireAt: parseServerUtc(j['expire_at']),
      currency: (j['currency'] ?? '').toString(),
      plan: plan,
      effectivePrice: j.containsKey('effective_price')
          ? _double(j['effective_price'])
          : (plan?.price ?? 0),
      balance: _double(j['balance']),
      debt: _double(j['debt']),
      openLoans: loans
          .whereType<Map>()
          .map((m) => OpenLoan.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      hasQuota: quota['has_quota'] == true,
      dailyQuotaMb: _doubleOrNull(quota['daily_quota_mb']),
      usedTodayMb: _doubleOrNull(quota['used_today_mb']),
      quotaWindows: quotaWindowsOf(quota),
      quotaUsage: quotaUsageLines(quota),
      onlineSessions: _intOrNull(j['online_sessions']) ?? 0,
      smsEnabled: channels['sms'] != false,
      whatsappEnabled: channels['whatsapp'] == true,
      templates: tpls.isEmpty ? kDefaultMessageTemplates : tpls,
      maxFreeLoanHours: _intOrNull(j['max_free_loan_hours']) ?? 72,
      maxDebtLoanDays: _intOrNull(j['max_debt_loan_days']) ?? 366,
      permissions: ActionPermissions.fromJson(j['permissions']),
    );
  }

  /// Built from the list/360 row when the server has no actions-context yet.
  factory SubscriberActionsContext.legacy(
    Subscriber s, {
    String planName = '',
    double planPrice = 0,
  }) {
    final hasQuota = s.quotaLimitEnabled ||
        s.combinedQuotaMb > 0 ||
        s.downloadQuotaMb > 0 ||
        s.uploadQuotaMb > 0;
    final price = s.customPrice > 0 ? s.customPrice : planPrice;
    return SubscriberActionsContext(
      username: s.username,
      fullName: s.fullName,
      status: s.status,
      expireAt: s.expireAt,
      plan: s.planId == null && planName.isEmpty
          ? null
          : ActionPlan(
              id: s.planId,
              name: planName,
              price: planPrice,
              minutes: 0,
            ),
      effectivePrice: price,
      balance: s.balance,
      debt: s.balance < 0 ? -s.balance : 0,
      hasQuota: hasQuota,
      onlineSessions: s.onlineCount,
      legacy: true,
    );
  }

  SubscriberActionsContext copyWith({String? status, DateTime? expireAt}) =>
      SubscriberActionsContext(
        username: username,
        fullName: fullName,
        status: status ?? this.status,
        expireAt: expireAt ?? this.expireAt,
        currency: currency,
        plan: plan,
        effectivePrice: effectivePrice,
        balance: balance,
        debt: debt,
        openLoans: openLoans,
        hasQuota: hasQuota,
        dailyQuotaMb: dailyQuotaMb,
        usedTodayMb: usedTodayMb,
        quotaWindows: quotaWindows,
        quotaUsage: quotaUsage,
        onlineSessions: onlineSessions,
        smsEnabled: smsEnabled,
        whatsappEnabled: whatsappEnabled,
        templates: templates,
        maxFreeLoanHours: maxFreeLoanHours,
        maxDebtLoanDays: maxDebtLoanDays,
        permissions: permissions,
        legacy: legacy,
      );
}

// ─────────────────────────────────────────────────────────────────────────
//  Pure rules shared by the dialogs (unit-tested)
// ─────────────────────────────────────────────────────────────────────────

/// «مجاني» / «مدفوع — نقدًا» / «مدفوع — دين».
enum ChargeMode {
  free('free', 'مجاني'),
  paid('paid', 'مدفوع — نقدًا'),
  debt('debt', 'مدفوع — دين');

  const ChargeMode(this.wire, this.label);
  final String wire;
  final String label;
}

/// The web's price of added time: effective price × minutes ÷ plan minutes,
/// rounded to 2 decimals; 0 when free or when the plan has no price/period.
double priceForMinutes({
  required double effectivePrice,
  required int planMinutes,
  required int minutes,
  ChargeMode mode = ChargeMode.paid,
}) {
  if (mode == ChargeMode.free) return 0;
  if (effectivePrice <= 0 || planMinutes <= 0 || minutes <= 0) return 0;
  return (effectivePrice * (minutes / planMinutes) * 100).round() / 100;
}

/// Duration units of the extend dialog (web «الوحدة»), in minutes.
const kDurationUnits = <(int, String)>[
  (1440, 'أيّام'),
  (60, 'ساعات'),
  (1, 'دقائق'),
];

/// The quota windows a top-up may target, read from actions-context
/// `quota` (fix2 server): a total cap, and/or the plan's monthly / daily
/// caps (a daily-only plan used to be offered a top-up the server refused).
List<String> quotaWindowsOf(Map quota) {
  bool anyCap(Object? w) {
    if (w is! Map) return false;
    for (final k in const ['combined', 'download', 'upload', 'cap_mb']) {
      final v = w[k];
      final n = v is num ? v : num.tryParse('${v ?? ''}');
      if (n != null && n > 0) return true;
    }
    return false;
  }

  final out = <String>[];
  final total = quota['quota_mb'];
  final t = total is num ? total : num.tryParse('${total ?? ''}');
  if (t != null && t > 0) out.add('total');
  if (anyCap(quota['monthly'])) out.add('monthly');
  if (anyCap(quota['daily'])) out.add('daily');
  return out;
}

String _mbText(num mb) {
  if (mb >= 1024) {
    final gb = mb / 1024;
    return '${gb == gb.roundToDouble() ? gb.toStringAsFixed(0) : gb.toStringAsFixed(1)} GB';
  }
  return '${mb.round()} MB';
}

num? _numOf(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

/// The quota state of actions-context (fix2): total cap + period usage and
/// this period's top-ups, then the daily / monthly windows per direction.
/// Each line is LTR-safe Arabic, e.g. «كوتة اليوم: 150 MB من 200 MB».
List<String> quotaUsageLines(Map quota) {
  final out = <String>[];
  final cap = _numOf(quota['quota_mb']);
  final used = _numOf(quota['used_mb']);
  if (cap != null && cap > 0) {
    out.add('الكوتة الإجمالية: '
        '${used == null ? '' : '${_mbText(used)} من '}${_mbText(cap)}');
  }
  final topup = _numOf(quota['period_topup_mb']);
  if (topup != null && topup > 0) {
    out.add('إضافات هذه الفترة: ${_mbText(topup)}');
  }
  for (final (key, label) in const [('daily', 'كوتة اليوم'), ('monthly', 'كوتة الشهر')]) {
    final w = quota[key];
    if (w is! Map) continue;
    final parts = <String>[];
    for (final (dir, dirLabel, usedKey) in const [
      ('combined', 'مجمّعة', 'used_mb'),
      ('download', 'تنزيل', 'used_download_mb'),
      ('upload', 'رفع', 'used_upload_mb'),
    ]) {
      final c = _numOf(w[dir]);
      if (c == null || c <= 0) continue;
      final u = _numOf(w[usedKey]);
      parts.add('$dirLabel ${u == null ? '' : '${_mbText(u)} من '}${_mbText(c)}');
    }
    if (parts.isNotEmpty) out.add('$label: ${parts.join('، ')}');
  }
  if (out.isEmpty) {
    final today = _numOf(quota['used_today_mb']);
    if (today != null) out.add('المستهلك اليوم: ${_mbText(today)}');
  }
  return out;
}

/// Arabic label of a quota window.
String quotaWindowLabel(String w) => switch (w) {
      'total' => 'الكوتة الإجمالية',
      'monthly' => 'كوتة هذا الشهر',
      'daily' => 'كوتة اليوم',
      _ => 'تلقائي (حسب الباقة)',
    };

enum ExtendMode { duration, exact }

/// Why the extend dialog cannot be confirmed (Arabic), or null.
///
/// FIX2 caps: at most a year ([kMaxExtendDays]) per operation, a price ≤ 100,000 and no
/// expiry past [kMaxExpiryYear]; a typed «1e9» / «-5» is an error, never a
/// silently rewritten number; a paid/debt extension needs a real price.
String? extendInvalidReason({
  required ExtendMode mode,
  required String amountText,
  required int minutes,
  required ChargeMode charge,
  required double price,
  required bool unpriced,
  required DateTime anchor,
}) {
  if (mode == ExtendMode.duration) {
    final err = readNumberInput(amountText).error;
    if (err != null) return err;
    if (minutes <= 0) return 'أدخل مدّة أكبر من صفر.';
  }
  final span = validateExtendSpan(minutes);
  if (span != null) return span;
  if (anchor.add(Duration(minutes: minutes)).year > kMaxExpiryYear) {
    return '$kExpiryTooFarMessage (بعد سنة $kMaxExpiryYear).';
  }
  if (charge != ChargeMode.free) {
    if (unpriced || price < kMinMoneyAmount) {
      return 'لا يمكن احتساب قيمة لهذا الوقت (الباقة بلا سعر) — اختر «مجاني».';
    }
    if (price > kMaxMoneyAmount) {
      return 'قيمة الوقت كبيرة جدًا — الحدّ الأعلى $kMaxMoneyAmountLabel.';
    }
  }
  return null;
}

/// In «تاريخ وساعة الانتهاء» mode the price still needs a duration: the gap
/// between the chosen moment and the subscriber's effective end (the later of
/// its current expiry and now) — the same formula as the web and the server.
int exactExtendMinutes(DateTime target, DateTime? currentExpire, DateTime now) {
  final anchor =
      currentExpire != null && currentExpire.isAfter(now) ? currentExpire : now;
  final diff = target.difference(anchor).inMinutes;
  return diff > 0 ? diff : 0;
}

/// Opening suggestion for the exact-expiry picker: the current expiry when it
/// is in the future, else this time tomorrow (seconds dropped).
DateTime defaultExactExpiry(DateTime? currentExpire, DateTime now) {
  final base = currentExpire != null && currentExpire.isAfter(now)
      ? currentExpire
      : now.add(const Duration(days: 1));
  return DateTime(base.year, base.month, base.day, base.hour, base.minute);
}

/// Latin-digit number from what the operator typed («١٢٫٥» → 12.5).
///
/// Strict (core/format/number_input.dart): «-5», «1e9», «1,5» or text give
/// `null` — never a silently rewritten value.
double? parseLocalizedNumber(String raw) => parseDecimalInput(raw);

/// UTC ISO-8601 with a trailing «Z», no fractions: 2026-09-28T21:00:00Z.
String toUtcIso(DateTime t) => toServerUtcIso(t);

/// Body of POST /accounts/<u>/extend.
Map<String, dynamic> extendPayload({
  required ExtendMode mode,
  int minutes = 0,
  DateTime? expireAt,
  ChargeMode charge = ChargeMode.free,
  double amount = 0,
  String notes = '',
}) {
  return {
    'mode': mode == ExtendMode.duration ? 'duration' : 'expire_at',
    if (mode == ExtendMode.duration) 'minutes': minutes,
    if (mode == ExtendMode.exact && expireAt != null)
      'expire_at': toUtcIso(expireAt),
    'charge_mode': charge.wire,
    if (charge != ChargeMode.free) 'amount': amount,
    'notes': notes.trim(),
  };
}

/// Body shared by quota top-up / daily reset charge fields.
Map<String, dynamic> chargePayload(
  ChargeMode charge,
  double amount,
  String notes,
) =>
    {
      'charge_mode': charge.wire,
      if (charge != ChargeMode.free) 'amount': amount,
      'notes': notes.trim(),
    };

/// «نوع الكوتة» of the web top-up dialog.
const kQuotaTargets = <(String, String)>[
  ('combined', 'مشتركة تنزيل/رفع'),
  ('download', 'تنزيل فقط'),
  ('upload', 'رفع فقط'),
];

enum LoanType { free, debt }

/// Client-side guard of the web's loan rules (services/accounting.py): a free
/// loan is at most [maxFreeHours] hours, a debt loan at most [maxDebtDays]
/// days, and the duration must be positive. The server stays the authority.
String? validateLoan({
  required LoanType type,
  required int days,
  required int hours,
  int maxFreeHours = 72,
  int maxDebtDays = 366,
}) {
  if (days < 0 || hours < 0) return 'المدّة لا تكون سالبة.';
  final minutes = days * 1440 + hours * 60;
  if (minutes <= 0) return 'حدّد مدّة السلفة (أيام أو ساعات).';
  if (type == LoanType.free && minutes > maxFreeHours * 60) {
    return 'السلفة المجانية لا تتجاوز $maxFreeHours ساعة.';
  }
  // Owner rule first: one operation adds at most a year — with the
  // owner's exact wording (the dialog used its own «سلفة الدين لا تتجاوز
  // 365 يومًا.» — f03 N5).
  final span = validateExtendSpan(minutes);
  if (span != null) return span;
  if (type == LoanType.debt && minutes > maxDebtDays * 1440) {
    return 'سلفة الدين لا تتجاوز $maxDebtDays يومًا.';
  }
  return null;
}

Map<String, dynamic> loanPayload({
  required LoanType type,
  required int days,
  required int hours,
  String reason = '',
}) =>
    {
      'loan_type': type == LoanType.free ? 'free' : 'debt',
      'days': days,
      'hours': hours,
      'reason': reason.trim(),
    };

/// Per open loan inside the payment dialog: «خصم» / «تأجيل» / «مسامحة».
///
/// NOTE: the web form posts «writeoff» for مسامحة; the API contract names it
/// «forgive». [wire] is the single place to change if the server settles on
/// the web's word.
enum LoanChoice {
  settle('settle', 'خصم'),
  defer('defer', 'تأجيل'),
  forgive('forgive', 'مسامحة');

  const LoanChoice(this.wire, this.label);
  final String wire;
  final String label;
}

/// Only the non-default choices travel (like the web's hidden field): a
/// deferred loan simply stays open.
List<Map<String, dynamic>> loanActionsPayload(Map<int, LoanChoice> choices) => [
      for (final e in choices.entries)
        if (e.value != LoanChoice.defer)
          {'loan_id': e.key, 'action': e.value.wire},
    ];

double settledTotal(List<OpenLoan> loans, Map<int, LoanChoice> choices) => loans
    .where((l) => choices[l.id] == LoanChoice.settle)
    .fold(0.0, (t, l) => t + l.amount);

const kPaymentMethods = <(String, String)>[
  ('cash', 'نقدًا'),
  ('bank', 'تحويل بنكي'),
  ('manual', 'يدوي'),
];

Map<String, dynamic> paymentPayload({
  required double amount,
  String method = 'cash',
  String notes = '',
  Map<int, LoanChoice> choices = const {},
  bool settleBalance = false,
}) =>
    {
      'amount': amount,
      'method': method,
      'notes': notes.trim(),
      'loan_actions': loanActionsPayload(choices),
      'settle_balance': settleBalance,
    };

// ── Change plan ───────────────────────────────────────────────────────────

enum PlanDirection { lower, higher, neutral }

/// A plan with no duration is priced as a 30-day month on the server
/// (`users.PLAN_PERIOD_FALLBACK_MINUTES` — same basis as payments, extend
/// and loans).
const int kPlanPeriodFallbackMinutes = 43200;

/// The server's `plan_change_direction` on two prices PER MINUTE: a free
/// plan (rate 0) → any paid plan is «higher» (free → paid used to offer only
/// «تغيير العرض فقط» and the server refused it — f04 M2), paid → free is
/// «lower», both free is «neutral»; equal rates (1e-9 relative) are
/// «neutral».
PlanDirection planDirectionByRate(double oldRate, double newRate) {
  final o = oldRate.isFinite && oldRate > 0 ? oldRate : 0.0;
  final n = newRate.isFinite && newRate > 0 ? newRate : 0.0;
  if (o <= 0 && n <= 0) return PlanDirection.neutral;
  if (o <= 0) return PlanDirection.higher;
  if (n <= 0) return PlanDirection.lower;
  if ((n - o).abs() <= 1e-9 * (o > n ? o : n)) return PlanDirection.neutral;
  return n < o ? PlanDirection.lower : PlanDirection.higher;
}

/// The server's `direction` token → [PlanDirection] (null when unknown).
PlanDirection? planDirectionFromServer(Object? raw) =>
    switch ('${raw ?? ''}'.trim().toLowerCase()) {
      'lower' => PlanDirection.lower,
      'higher' => PlanDirection.higher,
      'neutral' => PlanDirection.neutral,
      _ => null,
    };

/// Direction between two plans given their [currentPrice]/[nextPrice]
/// (each already per minute, or both totals over the same period). The
/// same plan or no choice → neutral; otherwise the server rule of
/// [planDirectionByRate] (a free plan counts as rate 0 — no longer
/// «neutral» for a missing price).
PlanDirection planDirection({
  required int? currentPlanId,
  required double currentPrice,
  required int? nextPlanId,
  required double nextPrice,
}) {
  if (nextPlanId == null || nextPlanId == currentPlanId) {
    return PlanDirection.neutral;
  }
  return planDirectionByRate(currentPrice, nextPrice);
}

class PlanPolicyOption {
  const PlanPolicyOption(this.value, this.title, this.description);
  final String value;
  final String title;
  final String description;
}

/// The radio options the web shows for each direction; the first is the
/// default.
List<PlanPolicyOption> planPolicies(PlanDirection d) => switch (d) {
      PlanDirection.lower => const [
          PlanPolicyOption(
            'lower_compensate',
            'تعويض أيام إضافية',
            'يحافظ على قيمة الأيام المتبقية ويحوّلها لأيام أكثر حسب سعر '
                'العرض الأقل.',
          ),
          PlanPolicyOption(
            'lower_keep_expiry',
            'تغيير العرض بدون تعويض',
            'يتم تغيير العرض فقط مع بقاء تاريخ الانتهاء الحالي كما هو.',
          ),
        ],
      PlanDirection.higher => const [
          PlanPolicyOption(
            'higher_debt',
            'تسجيل دين فرق السعر',
            'يبقى عدد الأيام كما هو، ويتم تسجيل فرق السعر كدين على رصيد '
                'المشترك.',
          ),
          PlanPolicyOption(
            'higher_reduce_days',
            'إنقاص الأيام',
            'يتم تقليل الأيام المتبقية حسب قيمة العرض الأعلى بدون تسجيل دين.',
          ),
          PlanPolicyOption(
            'higher_keep_expiry',
            'تغيير العرض بدون دين أو إنقاص أيام',
            'تغيير إداري مباشر للعرض فقط مع بقاء تاريخ الانتهاء كما هو.',
          ),
        ],
      PlanDirection.neutral => const [
          PlanPolicyOption(
            'neutral_keep_expiry',
            'تغيير العرض فقط',
            'يستخدم عندما يكون السعر مساويًا أو لا تتوفر بيانات كافية '
                'للتعويض.',
          ),
        ],
    };

String planDirectionHint(PlanDirection d) => switch (d) {
      PlanDirection.lower =>
        'العرض الجديد أقل سعرًا: اختر التعويض أو تغيير العرض بدون تعويض.',
      PlanDirection.higher =>
        'العرض الجديد أعلى سعرًا: اختر الدين أو إنقاص الأيام أو التغيير '
            'المباشر.',
      PlanDirection.neutral =>
        'سيتم تغيير العرض فقط مع بقاء تاريخ الانتهاء الحالي.',
    };

// ── Messages ──────────────────────────────────────────────────────────────

/// Fills {username} {plan} {expire} like the web's template buttons.
String fillMessageTemplate(
  String text, {
  required String username,
  String plan = '',
  String expire = '',
}) =>
    text
        .replaceAll('{username}', username)
        .replaceAll('{plan}', plan.isEmpty ? '—' : plan)
        .replaceAll('{expire}', expire.isEmpty ? '—' : expire);

// ── Rename ────────────────────────────────────────────────────────────────

/// Rename rule — the same format check as the create form
/// ([validateSubscriberUsernameFormat]) plus «not the current name».
String? validateNewUsername(String value, {required String current}) {
  final v = value.trim();
  if (v.isEmpty) return 'اكتب اسم المستخدم الجديد.';
  if (v == current) return 'الاسم الجديد مطابق للحالي.';
  return validateSubscriberUsernameFormat(v);
}

// ── Arabic durations (web arDays/arHours/arMinutes/arDuration) ─────────────

String arDays(num n) {
  final v = n.round() < 0 ? 0 : n.round();
  if (v == 1) return 'يوم';
  if (v == 2) return 'يومان';
  if (v >= 3 && v <= 10) return '$v أيام';
  return '$v يوم';
}

String arHours(num n) {
  final v = n.round() < 0 ? 0 : n.round();
  if (v == 1) return 'ساعة';
  if (v == 2) return 'ساعتان';
  if (v >= 3 && v <= 10) return '$v ساعات';
  return '$v ساعة';
}

String arMinutes(num n) {
  final v = n.round() < 0 ? 0 : n.round();
  if (v == 1) return 'دقيقة';
  if (v == 2) return 'دقيقتان';
  if (v >= 3 && v <= 10) return '$v دقائق';
  return '$v دقيقة';
}

String arDuration(num minutes) {
  final m = minutes.round() < 0 ? 0 : minutes.round();
  if (m >= 1440) return arDays(m / 1440);
  if (m >= 60) {
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${arHours(h)} و${arMinutes(rem)}' : arHours(h);
  }
  if (m == 30) return 'نصف ساعة';
  return arMinutes(m);
}

/// How much time [credited] money buys at [price] per [planMinutes] — the
/// payment dialog's live «يُمدِّد الانتهاء بـ ≈ …» hint. Empty when unknown.
String coverageText(double credited, double price, int planMinutes) {
  if (!(price > 0 && planMinutes > 0 && credited > 0)) return '';
  final periods = credited / price;
  final total = periods * planMinutes;
  if (planMinutes >= 1440) return arDays(total / 1440);
  return arDuration(total);
}

/// The payment dialog's live hint. What is deducted for loans/debt can never
/// exceed what was paid (a 10 payment against a 13.33 debt deducts 10, not
/// 13.33 — the server settles partially up to the cash); the rest buys time.
String paymentCoverageHint({
  required double amount,
  required double settledLoans,
  required double debt,
  required double effectivePrice,
  required int planMinutes,
  required String currency,
}) {
  if (!(amount > 0)) return 'أدخل المبلغ لعرض المدّة التي يُضيفها للحساب.';
  final wanted =
      (settledLoans > 0 ? settledLoans : 0.0) + (debt > 0 ? debt : 0.0);
  final cut = wanted > amount ? amount : wanted;
  final timeAmount = amount - cut;
  final cover = coverageText(timeAmount, effectivePrice, planMinutes);
  final timeMsg = timeAmount <= 0
      ? 'لا يبقى مبلغ لتمديد الانتهاء.'
      : effectivePrice <= 0
          ? 'المدّة تُحسب على الخادم حسب سعر العرض.'
          : 'يُطبَّق على الحساب ويُمدِّد الانتهاء بـ ≈ '
              '${cover.isEmpty ? arDuration(0) : cover}.';
  if (cut <= 0) return timeMsg;
  final partial = wanted > amount
      ? ' (من أصل ${formatMoney(wanted, currency)} مستحقّة)'
      : '';
  return 'سيُخصم ${formatMoney(cut, currency)}$partial لتسوية سلف/دين؛ '
      'والباقي ${formatMoney(timeAmount, currency)} ← $timeMsg';
}

/// Minutes a payment adds after settling debt/loans (0 when unknown) — for
/// the one-year rule on «payment → time».
int paymentExtendMinutes({
  required double amount,
  double settledLoans = 0,
  double debt = 0,
  required double effectivePrice,
  required int planMinutes,
}) {
  if (!(amount > 0 && effectivePrice > 0 && planMinutes > 0)) return 0;
  final wanted =
      (settledLoans > 0 ? settledLoans : 0.0) + (debt > 0 ? debt : 0.0);
  final timeAmount = amount - (wanted > amount ? amount : wanted);
  if (timeAmount <= 0) return 0;
  return (timeAmount / effectivePrice * planMinutes).floor();
}

String formatMoney(double v, String currency) {
  // The app's one money format (grouped, 0 or 2 decimals).
  final text = formatWithCurrency(v, currency);
  // LRI…PDI: keep «50 ILS» in reading order inside an Arabic sentence.
  return currency.isEmpty ? text : '\u2066$text\u2069';
}

// ── helpers ───────────────────────────────────────────────────────────────

/// Server datetimes are UTC with or without «Z»; returned in local time.
DateTime? parseServerUtc(Object? v) => parseServerDateTime(v);

int? _intOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.round();
}

double _double(Object? v) => _doubleOrNull(v) ?? 0;

double? _doubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
