import 'package:flutter/material.dart';

/// How a report cell should be rendered. Drives the bespoke per-report
/// formatting (dates, byte counters, durations, booleans, money).
enum ReportColumnKind { text, date, bytes, duration, boolean, amount, status }

/// One curated column in a bespoke operational-report table. The ordering of
/// the [OperationalReportDef.columns] list is the on-screen column order, so it
/// mirrors the tailored `rep_*` web pages instead of the alphabetical fallback.
class ReportColumn {
  const ReportColumn(
    this.key,
    this.label, {
    this.kind = ReportColumnKind.text,
    this.numeric = false,
  });

  final String key;
  final String label;
  final ReportColumnKind kind;
  final bool numeric;
}

/// Metadata describing a single operational report: identity for the hub
/// catalog, plus the curated column spec + date key for the detail screen.
class OperationalReportDef {
  const OperationalReportDef({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.columns,
    this.dateKey,
  });

  final String slug;
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final List<ReportColumn> columns;

  /// Row key holding the primary timestamp, used for the client-side
  /// date-range filter (the API only exposes `q`/`limit`/`offset`).
  final String? dateKey;
}

/// The 15 wired operational-report slugs, each with a tailored column layout
/// and grouped into catalogue categories for the reports-center hub. Mirrors
/// the web `rep_*` pages (column choice + ordering + date drill-down).
const List<OperationalReportDef> operationalReportCatalog = [
  // ── الجلسات والاتصال ──────────────────────────────────────────────
  OperationalReportDef(
    slug: 'sessions',
    title: 'جلسات الاتصال',
    subtitle: 'كل جلسات الريدياس المسجلة في جدول المحاسبة.',
    icon: Icons.lan_outlined,
    category: 'الجلسات والاتصال',
    dateKey: 'acctstarttime',
    columns: [
      ReportColumn('username', 'اسم الدخول'),
      ReportColumn('callingstationid', 'MAC'),
      ReportColumn('framedipaddress', 'IP'),
      ReportColumn('nasipaddress', 'جهاز الشبكة'),
      ReportColumn('acctstarttime', 'بدأت', kind: ReportColumnKind.date),
      ReportColumn('acctstoptime', 'انتهت', kind: ReportColumnKind.date),
      ReportColumn(
        'acctsessiontime',
        'المدة',
        kind: ReportColumnKind.duration,
        numeric: true,
      ),
      ReportColumn(
        'acctinputoctets',
        'تحميل',
        kind: ReportColumnKind.bytes,
        numeric: true,
      ),
      ReportColumn(
        'acctoutputoctets',
        'رفع',
        kind: ReportColumnKind.bytes,
        numeric: true,
      ),
      ReportColumn('acctterminatecause', 'سبب الإنهاء'),
    ],
  ),
  OperationalReportDef(
    slug: 'mac-history',
    title: 'تاريخ MAC',
    subtitle: 'الأجهزة المختلفة التي ظهرت لكل اسم دخول.',
    icon: Icons.devices_other_outlined,
    category: 'الجلسات والاتصال',
    dateKey: 'last_seen',
    columns: [
      ReportColumn('username', 'اسم الدخول'),
      ReportColumn('mac', 'MAC'),
      ReportColumn('nasipaddress', 'جهاز الشبكة'),
      ReportColumn('sessions', 'عدد الجلسات', numeric: true),
      ReportColumn('last_seen', 'آخر ظهور', kind: ReportColumnKind.date),
    ],
  ),
  OperationalReportDef(
    slug: 'login-status',
    title: 'حالة دخول المستفيدين',
    subtitle: 'آخر دخول وظهور وحالة الحساب.',
    icon: Icons.how_to_reg_outlined,
    category: 'الجلسات والاتصال',
    dateKey: 'last_seen_at',
    columns: [
      ReportColumn('username', 'اسم الدخول'),
      ReportColumn('status', 'الحالة', kind: ReportColumnKind.status),
      ReportColumn('online_count', 'متصل الآن', numeric: true),
      ReportColumn('last_login_at', 'آخر دخول', kind: ReportColumnKind.date),
      ReportColumn('last_seen_at', 'آخر ظهور', kind: ReportColumnKind.date),
      ReportColumn('expire_at', 'ينتهي في', kind: ReportColumnKind.date),
    ],
  ),
  // ── الدخول والمصادقة ──────────────────────────────────────────────
  OperationalReportDef(
    slug: 'login-states',
    title: 'حالات الدخول الموحدة',
    subtitle: 'تجميع دخول اللوحة والبوابات ومصادقة الشبكة في سجل واحد.',
    icon: Icons.login_outlined,
    category: 'الدخول والمصادقة',
    dateKey: 'when',
    columns: [
      ReportColumn('when', 'وقت الحدث', kind: ReportColumnKind.date),
      ReportColumn('username', 'اسم الدخول'),
      ReportColumn('actor_type', 'نوع المستخدم'),
      ReportColumn('success', 'النتيجة', kind: ReportColumnKind.boolean),
      ReportColumn('reason', 'السبب'),
      ReportColumn('source', 'المصدر'),
      ReportColumn('ip', 'IP'),
      ReportColumn('device', 'الجهاز'),
    ],
  ),
  OperationalReportDef(
    slug: 'failed-logins',
    title: 'محاولات فاشلة',
    subtitle: 'رفض الدخول من radpostauth بدون كشف كلمة المرور.',
    icon: Icons.gpp_bad_outlined,
    category: 'الدخول والمصادقة',
    dateKey: 'authdate',
    columns: [
      ReportColumn('authdate', 'وقت المحاولة', kind: ReportColumnKind.date),
      ReportColumn('username', 'اسم الدخول'),
      ReportColumn('reply', 'النتيجة'),
      ReportColumn('nas', 'جهاز الشبكة'),
      ReportColumn('class', 'التصنيف'),
    ],
  ),
  // ── الأحداث والتدقيق ─────────────────────────────────────────────
  OperationalReportDef(
    slug: 'profile-changes',
    title: 'تغييرات الباقة',
    subtitle: 'أحداث تعديل أو تمديد حسابات المستفيدين.',
    icon: Icons.edit_note_outlined,
    category: 'الأحداث والتدقيق',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت الحدث', kind: ReportColumnKind.date),
      ReportColumn('actor', 'المنفذ'),
      ReportColumn('action', 'الإجراء'),
      ReportColumn('target_id', 'الهدف'),
      ReportColumn('result_status', 'النتيجة', kind: ReportColumnKind.status),
    ],
  ),
  OperationalReportDef(
    slug: 'api-messages',
    title: 'رسائل واجهة الربط',
    subtitle: 'أحداث نفذتها مفاتيح الربط.',
    icon: Icons.api_outlined,
    category: 'الأحداث والتدقيق',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت الحدث', kind: ReportColumnKind.date),
      ReportColumn('actor', 'المفتاح'),
      ReportColumn('action', 'الإجراء'),
      ReportColumn('target_type', 'نوع الهدف'),
      ReportColumn('target_id', 'الهدف'),
    ],
  ),
  OperationalReportDef(
    slug: 'manager-events',
    title: 'أحداث المدراء',
    subtitle: 'الأفعال الإدارية من غير مفاتيح الربط.',
    icon: Icons.manage_accounts_outlined,
    category: 'الأحداث والتدقيق',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت الحدث', kind: ReportColumnKind.date),
      ReportColumn('actor', 'المدير'),
      ReportColumn('action', 'الإجراء'),
      ReportColumn('target_type', 'نوع الهدف'),
      ReportColumn('target_id', 'الهدف'),
      ReportColumn('result_status', 'النتيجة', kind: ReportColumnKind.status),
    ],
  ),
  OperationalReportDef(
    slug: 'user-events',
    title: 'أحداث المستفيدين',
    subtitle: 'سجل الأحداث المرتبطة بحسابات المستفيدين.',
    icon: Icons.history_edu_outlined,
    category: 'الأحداث والتدقيق',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت الحدث', kind: ReportColumnKind.date),
      ReportColumn('actor', 'المنفذ'),
      ReportColumn('action', 'الإجراء'),
      ReportColumn('target_id', 'الهدف'),
      ReportColumn('result_status', 'النتيجة', kind: ReportColumnKind.status),
    ],
  ),
  OperationalReportDef(
    slug: 'speed-failures',
    title: 'فشل تعديل السرعات',
    subtitle: 'أوامر السرعة والبروفايل التي فشلت وتحتاج مراجعة تشغيلية.',
    icon: Icons.speed_outlined,
    category: 'الأحداث والتدقيق',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت الحدث', kind: ReportColumnKind.date),
      ReportColumn('actor', 'المنفذ'),
      ReportColumn('action', 'الإجراء'),
      ReportColumn('target_id', 'الهدف'),
      ReportColumn('error_message', 'رسالة الخطأ'),
    ],
  ),
  // ── الشبكة والمزامنة ─────────────────────────────────────────────
  OperationalReportDef(
    slug: 'coa-failures',
    title: 'فشل أوامر الشبكة',
    subtitle: 'عمليات فصل أو مزامنة فشلت أو تنتظر إعادة محاولة.',
    icon: Icons.sync_problem_outlined,
    category: 'الشبكة والمزامنة',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت التسجيل', kind: ReportColumnKind.date),
      ReportColumn('kind', 'النوع'),
      ReportColumn('entity_key', 'العنصر'),
      ReportColumn('status', 'الحالة', kind: ReportColumnKind.status),
      ReportColumn('attempts', 'المحاولات', numeric: true),
      ReportColumn('last_error', 'آخر خطأ'),
      ReportColumn(
        'next_attempt_at',
        'المحاولة القادمة',
        kind: ReportColumnKind.date,
      ),
    ],
  ),
  // ── الإدارة ──────────────────────────────────────────────────────
  OperationalReportDef(
    slug: 'manager-login-status',
    title: 'دخول المدراء',
    subtitle: 'آخر دخول وحالة حسابات الإدارة.',
    icon: Icons.admin_panel_settings_outlined,
    category: 'الإدارة',
    dateKey: 'last_login_at',
    columns: [
      ReportColumn('username', 'اسم الدخول'),
      ReportColumn('full_name', 'الاسم الكامل'),
      ReportColumn('email', 'البريد'),
      ReportColumn('role_display_name', 'الدور'),
      ReportColumn('enabled', 'مفعّل', kind: ReportColumnKind.boolean),
      ReportColumn('last_login_at', 'آخر دخول', kind: ReportColumnKind.date),
      ReportColumn('created_at', 'تاريخ الإنشاء', kind: ReportColumnKind.date),
    ],
  ),
  // ── البطاقات ─────────────────────────────────────────────────────
  OperationalReportDef(
    slug: 'used-cards',
    title: 'الكروت المستخدمة',
    subtitle: 'كل الكروت التي تم استخدامها مع MAC ووقت أول استخدام.',
    icon: Icons.style_outlined,
    category: 'البطاقات',
    dateKey: 'first_used_at',
    columns: [
      ReportColumn('username', 'اسم الكرت'),
      ReportColumn('used_by_mac', 'MAC المستخدم'),
      ReportColumn('plan_name', 'الباقة'),
      ReportColumn(
        'first_used_at',
        'أول استخدام',
        kind: ReportColumnKind.date,
      ),
      ReportColumn('expire_at', 'ينتهي في', kind: ReportColumnKind.date),
      ReportColumn('revoked', 'ملغي', kind: ReportColumnKind.boolean),
    ],
  ),
  // ── المالية ──────────────────────────────────────────────────────
  OperationalReportDef(
    slug: 'balance-movements',
    title: 'حركات الرصيد',
    subtitle: 'حركات أرصدة المشتركين والمديرين والموزعين في سجل واحد.',
    icon: Icons.swap_vert_outlined,
    category: 'المالية',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت الحركة', kind: ReportColumnKind.date),
      ReportColumn('scope', 'النطاق'),
      ReportColumn('entry_type', 'نوع الحركة'),
      ReportColumn('direction', 'الاتجاه'),
      ReportColumn(
        'amount',
        'المبلغ',
        kind: ReportColumnKind.amount,
        numeric: true,
      ),
      ReportColumn('currency', 'العملة'),
      ReportColumn('username', 'المستفيد'),
      ReportColumn('operator', 'الموظف'),
      ReportColumn('status', 'الحالة', kind: ReportColumnKind.status),
    ],
  ),
  OperationalReportDef(
    slug: 'cash-transactions',
    title: 'الحركات النقدية',
    subtitle: 'دفعات الكاش والتحصيل اليدوي مع الخصومات والدقائق المكتسبة.',
    icon: Icons.payments_outlined,
    category: 'المالية',
    dateKey: 'created_at',
    columns: [
      ReportColumn('created_at', 'وقت الدفع', kind: ReportColumnKind.date),
      ReportColumn('username', 'المستفيد'),
      ReportColumn(
        'amount',
        'المبلغ',
        kind: ReportColumnKind.amount,
        numeric: true,
      ),
      ReportColumn('currency', 'العملة'),
      ReportColumn('method', 'الطريقة'),
      ReportColumn('status', 'الحالة', kind: ReportColumnKind.status),
      ReportColumn(
        'effective_price',
        'السعر الفعلي',
        kind: ReportColumnKind.amount,
        numeric: true,
      ),
      ReportColumn(
        'discount_amount',
        'الخصم',
        kind: ReportColumnKind.amount,
        numeric: true,
      ),
      ReportColumn('earned_minutes', 'الدقائق المكتسبة', numeric: true),
      ReportColumn('created_by', 'أنشأها'),
    ],
  ),
];

/// Ordered list of categories as they should appear in the hub.
List<String> operationalReportCategories() {
  final seen = <String>[];
  for (final def in operationalReportCatalog) {
    if (!seen.contains(def.category)) seen.add(def.category);
  }
  return seen;
}

OperationalReportDef? operationalReportBySlug(String slug) {
  for (final def in operationalReportCatalog) {
    if (def.slug == slug) return def;
  }
  return null;
}
