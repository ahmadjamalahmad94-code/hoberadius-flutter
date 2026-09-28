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
  });

  final int? id;
  final String name;
  final double price;

  /// Plan period in minutes (30 days = 43200).
  final int minutes;

  static ActionPlan? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return ActionPlan(
      id: _intOrNull(raw['id']),
      name: (raw['name'] ?? '').toString(),
      price: _double(raw['price']),
      minutes: _intOrNull(raw['minutes']) ?? 0,
    );
  }
}

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
    this.currency = 'ILS',
    this.plan,
    this.effectivePrice = 0,
    this.balance = 0,
    this.debt = 0,
    this.openLoans = const [],
    this.hasQuota = false,
    this.dailyQuotaMb,
    this.usedTodayMb,
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
      currency: (j['currency'] ?? 'ILS').toString(),
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

enum ExtendMode { duration, exact }

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
double? parseLocalizedNumber(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final a = arabic.indexOf(ch);
    final p = persian.indexOf(ch);
    if (a >= 0) {
      b.write(a);
    } else if (p >= 0) {
      b.write(p);
    } else if (ch == '٫' || ch == ',') {
      b.write('.');
    } else {
      b.write(ch);
    }
  }
  s = b.toString();
  return double.tryParse(s);
}

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

/// Same rule as the web's updatePlanPolicy(): same plan, a missing price on
/// either side, or equal prices → neutral.
PlanDirection planDirection({
  required int? currentPlanId,
  required double currentPrice,
  required int? nextPlanId,
  required double nextPrice,
}) {
  if (nextPlanId == null ||
      nextPlanId == currentPlanId ||
      currentPrice <= 0 ||
      nextPrice <= 0) {
    return PlanDirection.neutral;
  }
  if (nextPrice < currentPrice) return PlanDirection.lower;
  if (nextPrice > currentPrice) return PlanDirection.higher;
  return PlanDirection.neutral;
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

String formatMoney(double v, String currency) {
  final fixed =
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  // LRI…PDI: keep «50 ILS» in reading order inside an Arabic sentence.
  return currency.isEmpty ? fixed : '\u2066$fixed $currency\u2069';
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
