import '../format/bidi.dart';
import '../format/currency.dart';

String currencyLabel(String code) {
  return switch (code.trim().toUpperCase()) {
    'ILS' => 'شيكل إسرائيلي',
    'JOD' => 'دينار أردني',
    'USD' => 'دولار أمريكي',
    '' => 'عملة غير محددة',
    _ => 'عملة غير معروفة',
  };
}

/// «20 ₪» for the shekel (owner 2026-10-01: the symbol, like the web, never
/// «ILS» nor «شيكل إسرائيلي»); other currencies keep their Arabic name
/// («20 دينار أردني»).
String amountWithCurrency(String amount, String code) {
  final value = amount.trim().isEmpty ? '0' : amount.trim();
  final c = code.trim().toUpperCase();
  if (isShekelCode(c)) return amountWithCurrencyCode(value, c);
  return '$value ${currencyLabel(code)}';
}

/// A currency picker option label: «شيكل (₪)» for ILS, «دينار أردني (JOD)»
/// otherwise. The option VALUE stays the ISO code.
String currencyOptionLabel(String code) {
  final c = code.trim().toUpperCase();
  if (isShekelCode(c)) return 'شيكل (${currencyDisplay(c)})';
  return '${currencyLabel(c)} ($c)';
}

String unknownStatusLabel(
  String value, {
  String emptyLabel = 'غير محدد',
  String unknownLabel = 'حالة غير معروفة',
}) {
  return value.trim().isEmpty ? emptyLabel : unknownLabel;
}

String unknownActionLabel(
  String value, {
  String emptyLabel = 'عملية',
  String unknownLabel = 'عملية غير معروفة',
}) {
  return value.trim().isEmpty ? emptyLabel : unknownLabel;
}

/// Arabic for the raw status / type / direction tokens the API returns in
/// report rows and logs (`posted`, `credit`, `password_wrong`, `enabled`…).
/// Unknown tokens are returned unchanged.
const Map<String, String> kRawTokenLabels = {
  'posted': 'مرحّل',
  'voided': 'معكوس',
  'reversed': 'معكوس',
  'pending': 'قيد الانتظار',
  'open': 'مفتوح',
  'settled': 'مسدّد',
  'failed': 'فشل',
  'success': 'نجاح',
  'ok': 'ناجح',
  'credit': 'دائن (إيداع)',
  'debit': 'مدين (خصم)',
  'settlement': 'تسوية',
  'loan': 'سلفة',
  'payment': 'دفعة',
  'payment_to_balance': 'دفعة — إضافة للرصيد',
  'payment_to_debt': 'دفعة — خصم من الدين',
  'debt_settle': 'تسديد دين',
  'debt': 'دين',
  'balance': 'رصيد',
  'adjustment': 'تعديل',
  'void': 'قيد عكسي',
  'general': 'عام',
  'extension': 'تمديد وقت',
  'quota_topup': 'إضافة كوتة',
  'subscriber': 'مشترك',
  'distributor': 'موزّع',
  'manager': 'مدير',
  'admin': 'مدير',
  'card': 'كرت',
  'enabled': 'مفعّل',
  'disabled': 'معطّل',
  'active': 'نشط',
  'inactive': 'غير نشط',
  'expired': 'منتهي',
  'suspended': 'موقوف',
  'banned': 'محظور',
  'password_wrong': 'كلمة مرور خاطئة',
  'user_not_found': 'مستخدم غير موجود',
  'not_found': 'غير موجود',
  'manual': 'يدوي',
  'cash': 'نقدًا',
  'bank': 'تحويل بنكي',
  // Ledger entry types (server `entry_type`).
  'time_extension': 'تمديد وقت',
  'debt_settlement': 'تسديد دين',
  'writeoff': 'مسامحة / إعفاء',
  'on_account_credit': 'رصيد على الحساب',
  'cash_balance': 'رصيد نقدي',
  'correction': 'تصحيح',
  'card_sale': 'بيع بطاقة',
  'wallet_recharge': 'شحن محفظة',
  'batch_creation': 'إنشاء حزمة بطاقات',
  'reversal': 'قيد عكسي',
  'refund': 'استرداد',
  'discount': 'خصم',
  'topup': 'شحن رصيد',
  'invoice': 'فاتورة',
  // Ledger sources (server `source_type`).
  'payment_void': 'إلغاء دفعة',
  'payment_balance_settlement': 'تسوية رصيد من دفعة',
  'payment_collection_request': 'طلب تحصيل',
  'loan_writeoff': 'مسامحة سلفة',
  'ledger_void': 'عكس قيد',
  'subscriber_time_extension': 'تمديد وقت المشترك',
  'subscriber_quota_topup': 'شحن كوتة المشترك',
  'subscriber_plan_change': 'تغيير عرض المشترك',
  'subscriber_daily_quota_reset': 'استعادة الكوتة اليومية',
  'subscriber_cash_balance': 'رصيد نقدي للمشترك',
  'subscriber_payment': 'دفعة مشترك',
  'external': 'مصدر خارجي',
  'imported': 'مستورد',
  'accounting_ledger_entries': 'دفتر القيود',
  // Operational report tokens (speed changes, login states, attempts).
  'temporary_speed': 'سرعة مؤقتة',
  'all_failed': 'فشل الكل',
  'partial': 'جزئي',
  'no_active_session': 'لا توجد جلسة نشطة',
  'router_not_configured': 'الراوتر غير مهيّأ',
  'apply': 'تطبيق',
  'revert': 'إرجاع',
  'panel': 'لوحة التحكم',
  'network': 'الشبكة',
  'unknown': 'غير معروف',
  'provider_active_cap': 'تجاوز حدّ الاشتراكات النشطة للمزوّد',
  'skipped': 'تم التخطّي',
  'never_run': 'لم يُشغَّل بعد',
  'running': 'قيد التشغيل',
  'queued': 'بالانتظار',
  'cancelled': 'أُلغي',
  'wallet': 'محفظة',
  'sent': 'أُرسل',
  'delivered': 'سُلِّم',
  'read': 'مقروء',
  'sms': 'رسالة SMS',
  'whatsapp': 'واتساب',
  'telegram': 'تيليجرام',
  'email': 'بريد إلكتروني',
  'push': 'إشعار',
  // Business-ops ledger accounts / reference types.
  'revenue': 'الإيرادات',
  'expense': 'المصروفات',
  'receivable': 'ذمم مدينة',
  'payable': 'ذمم دائنة',
  'company': 'الشركة',
  'card_user': 'مستخدم كروت',
  'package': 'باقة',
  'plan': 'عرض',
  'card_batch': 'حزمة بطاقات',
  'subscription': 'اشتراك',
  'voucher': 'كوبون',
  'renewal': 'تجديد',
  'profit_share': 'حصة ربح',
  // Backups / delivery / job states.
  'done': 'تمّ',
  'completed': 'مكتمل',
  'error': 'خطأ',
  'never': 'أبدًا',
  'not_configured': 'غير مهيّأ',
  'disconnected': 'غير متصل',
  'connected': 'متصل',
  'local': 'محلي',
  'google_drive': 'جوجل درايف',
  'drive': 'جوجل درايف',
  'undelivered': 'لم يُسلَّم',
  'bounced': 'مرتدّ',
  'rejected': 'مرفوض',
  'retry': 'إعادة محاولة',
  'retrying': 'إعادة محاولة',
  'in_app': 'داخل التطبيق',
  'fcm': 'إشعار',
  'webhook': 'ويب هوك',
  'no_recipient': 'لا يوجد مستلم',
  'no_phone': 'لا يوجد رقم هاتف',
  'channel_disabled': 'القناة معطّلة',
  'disabled_channel': 'القناة معطّلة',
  'opted_out': 'ألغى المستلم الاشتراك',
  'duplicate': 'مكرّر',
  'rate_limited': 'تجاوز حدّ الإرسال',
  // Audit / report ACTION codes (the web's reports._ACTION_LABELS +
  // audit_format) — «الإجراء create», «extend_time» were shown raw (f07
  // N-C1).
  'create': 'إنشاء',
  'update': 'تعديل',
  'delete': 'حذف',
  'disable': 'تعطيل',
  'enable': 'تفعيل',
  'extend_time': 'إضافة وقت / تمديد',
  'extend': 'تمديد',
  'change_plan': 'تجديد / تغيير الباقة',
  'archive': 'أرشفة',
  'restore': 'استعادة',
  'rename': 'إعادة تسمية',
  'reset_password': 'إعادة تعيين كلمة المرور',
  'bulk_set_speeds': 'تحديث جماعي للسرعات',
  'temporary_speed.apply': 'فتح سرعة',
  'temporary_speed.revert': 'إرجاع السرعة',
  'subscriber.cash_balance_add': 'إضافة رصيد',
  'subscriber.quota_topup': 'إضافة كوتة',
  'subscriber.daily_quota_reset': 'تصفير الكوتة اليوميّة',
  'subscriber.debt_settled_from_payment': 'تسوية دين من دفعة',
  'notification.manual_queued': 'رسالة يدوية',
  'payment_collection.settings_saved': 'حفظ إعدادات التحصيل',
  'payment_collection.request_approved': 'اعتماد طلب دفع',
  'payment_collection.request_rejected': 'رفض طلب دفع',
  'auth_login_failed': 'فشل تسجيل الدخول',
  'auth_login': 'تسجيل الدخول',
  'auth_logout': 'تسجيل الخروج',
  'login': 'تسجيل الدخول',
  'logout': 'تسجيل الخروج',
  'page_visit': 'زيارة صفحة',
  'manager_activity': 'نشاط مدير',
  'disconnect': 'فصل',
  'lock_mac': 'تثبيت MAC',
  'lock_ip': 'تثبيت IP',
  // Audit TARGET types.
  'user': 'مشترك',
  'router': 'راوتر',
  'nas': 'جهاز شبكة',
  'service': 'خدمة',
  'role': 'دور',
  'session': 'جلسة',
  'notification_campaign': 'حملة رسائل',
  'payment_request': 'طلب دفع',
  'card_print_template': 'قالب طباعة بطاقات',
  'bandwidth_profile': 'ملف عرض النطاق',
  'demo-seed': 'بيانات تجريبية',
  'demo_seed': 'بيانات تجريبية',
  // Service types / health metrics.
  'hotspot': 'هوتسبوت',
  'pppoe': 'PPPoE',
  'both': 'هوتسبوت و PPPoE',
  'disk': 'القرص',
  'cpu': 'المعالج',
  'ram': 'الذاكرة',
  'memory': 'الذاكرة',
  'attention': 'يحتاج انتباهًا',
  'warning': 'تحذير',
  'critical': 'حرج',
  'healthy': 'سليم',
  'degraded': 'متدهور',
  'offline': 'غير متصل',
  'online': 'متصل',
};

/// Arabic for an audit ACTOR written by the server: `api-token:N` (every
/// app / API write — f07 N-C2 «بواسطة api-token:20»), `system:<job>`,
/// `system`, `ui`. Anything else (an admin name) is returned unchanged.
/// The server's resolved name (`actor_label` / `*_name`) always wins over
/// this — see [actorDisplay].
String actorLabel(String raw) {
  final a = raw.trim();
  if (a.isEmpty) return '—';
  final lower = a.toLowerCase();
  if (lower == 'system') return 'النظام';
  if (lower == 'ui') return 'عملية واجهة (تلقائي)';
  if (lower.startsWith('system:')) {
    final job = a.substring(7).trim();
    final known = kSystemActorLabels[job.toLowerCase()];
    final tail = known ?? job.replaceAll('-', ' ').replaceAll('_', ' ');
    return tail.isEmpty ? 'النظام' : 'النظام: $tail';
  }
  final token = RegExp(r'^api[-_]token(?:\s*[:#-]\s*(\w+))?$', caseSensitive: false)
      .firstMatch(a);
  if (token != null) {
    final id = token.group(1);
    return id == null || id.toLowerCase() == 'env'
        ? 'التطبيق / مفتاح ربط'
        : 'التطبيق / مفتاح ربط #$id';
  }
  return a;
}

/// The actor to show for a row: the server's resolved name when it sent
/// one (`actor_label`, `actor_name`, `created_by_label`, `created_by_name`),
/// else [actorLabel] of the raw value.
String actorDisplay(Map<String, dynamic> row, {String key = 'actor'}) {
  for (final k in ['${key}_label', '${key}_name', '${key}_display']) {
    final v = '${row[k] ?? ''}'.trim();
    if (v.isNotEmpty) return v;
  }
  return actorLabel('${row[key] ?? ''}');
}

/// Replaces raw actor tokens inside a server sentence («أضافه: api-token:119»).
String humanizeActorsInText(String text) => text.replaceAllMapped(
      RegExp(r'api[-_]token(?:\s*[:#-]\s*\w+)?', caseSensitive: false),
      (m) => actorLabel(m.group(0)!),
    );

/// `system:<job>` actors (the web's _SYSTEM_ACTOR_AR).
const kSystemActorLabels = <String, String>{
  'backup-scheduler': 'مجدول النسخ الاحتياطي',
  'temp-speed': 'السرعة المؤقتة',
  'notifications': 'الإشعارات',
  'policy-reconciler': 'مُصالِح السياسات',
  'log-retention': 'الاحتفاظ بالسجلّات',
  'lifecycle': 'دورة الحياة',
};

String rawTokenLabel(String value) {
  final key = value.trim().toLowerCase();
  if (key.startsWith('api-token') ||
      key.startsWith('api_token') ||
      key.startsWith('system:')) {
    return actorLabel(value);
  }
  final known = kRawTokenLabels[key];
  if (known != null) return known;
  // «wallet:4» / «distributor #1» (business-ops ledger parties).
  final party = RegExp(r'^([a-z_]+)\s*[:#]\s*(\d+)$').firstMatch(key);
  if (party != null) {
    final kind = kRawTokenLabels[party.group(1)!];
    if (kind != null) return '$kind #${party.group(2)}';
  }
  return value;
}

/// A business-ops ledger account / party code in Arabic: `cash` → «نقدًا»,
/// `wallet:4` → «محفظة #4», `distributor #1` → «موزّع #1». A code the app
/// does not know stays as one left-to-right run so RTL never reorders it
/// (`revenue:plan` would otherwise read «plan:revenue»).
String businessAccountLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) return '—';
  final label = rawTokenLabel(text);
  if (label != text) return label;
  return RegExp('[A-Za-z]').hasMatch(text) ? ltrIsolate(text) : text;
}

/// Arabic for a ledger `entry_type` — never «نوع غير معروف» for a type the
/// server writes (debt, settlement, writeoff…); an unseen one → «قيد مالي».
String ledgerTypeLabel(String value) {
  final key = value.trim().toLowerCase();
  if (key.isEmpty) return 'غير محدد';
  if (key == 'void') return 'قيد عكسي';
  if (key == 'adjustment') return 'تعديل مالي';
  if (key == 'settlement') return 'تسوية سلفة';
  if (key == 'debt') return 'دين';
  return kRawTokenLabels[key] ?? 'قيد مالي';
}

/// Arabic for a ledger `source_type`; an unseen one → «مصدر آخر».
String ledgerSourceLabel(String value) {
  final key = value.trim().toLowerCase();
  if (key.isEmpty) return '—';
  if (key == 'void') return 'قيد عكسي';
  return kRawTokenLabels[key] ?? 'مصدر آخر';
}
