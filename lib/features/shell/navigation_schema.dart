import 'package:flutter/material.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.label,
    required this.routeName,
    required this.path,
    this.description,
  });

  final IconData icon;
  final String label;
  final String routeName;
  final String path;
  final String? description;
}

class AppNavSection {
  const AppNavSection({
    required this.id,
    required this.icon,
    required this.label,
    required this.items,
  });

  final String id;
  final IconData icon;
  final String label;
  final List<AppNavItem> items;
}

const dashboardNavItem = AppNavItem(
  icon: Icons.dashboard_outlined,
  label: 'لوحة التحكم',
  routeName: 'dashboard',
  path: '/',
  description: 'المؤشرات اليومية وحالة الشبكة والخدمات الأساسية.',
);

const moreNavItem = AppNavItem(
  icon: Icons.more_horiz,
  label: 'المزيد',
  routeName: 'more',
  path: '/more',
  description: 'كل أقسام لوحة الويب مرتبة بنفس منطق التشغيل.',
);

// ════════════════════════════════════════════════════════════════════════
// 1:1 MIRROR of the web sidebar (radius-module@main app/templates/admin/
// _sidebar.html). Group set + order + Arabic labels + page placement match
// the web exactly; see docs/STRUCTURE_MAP.md. Only screens that EXIST in the
// app are listed (web pages with no Flutter screen are gaps in the map, not
// dead links). Web hub/tab pages are consolidated onto the matching screen.
// ════════════════════════════════════════════════════════════════════════
/// Pages that exist in the app (routes kept, reachable by deep link such as
/// a notification) but are hidden from the menu: setup / accounting /
/// administration work that belongs on the web panel (owner decision
/// 2026-09-27, «كله اخفاء»). To bring one back, re-add its AppNavItem.
const kWebOnlyPaths = <String>{
  '/print-templates',
  '/cards/recharge',
  '/plans/new',
  '/bandwidth-schedules',
  '/radius-resources',
  '/router-alerts',
  '/wallets',
  '/ledger',
  '/vouchers',
  '/communications',
  '/alerts/telegram',
  '/saas-modules',
  '/admins',
  '/roles',
  '/business-ops',
  '/backups',
  '/recycle-bin',
  '/lifecycle',
  '/admin-control',
  '/audit',
  '/invoices',
};

const appNavSections = <AppNavSection>[
  // ───────── 1) المشتركون ─────────
  AppNavSection(
    id: 'subscribers',
    icon: Icons.groups_2_outlined,
    label: 'المشتركون',
    items: [
      AppNavItem(
        icon: Icons.list_alt_outlined,
        label: 'المشتركين 360',
        routeName: 'subscribers',
        path: '/subscribers',
        description:
            'إدارة الحسابات، البحث، التفعيل، الإيقاف، والعمليات السريعة.',
      ),
      AppNavItem(
        icon: Icons.person_add_alt_1_outlined,
        label: 'إضافة مشترك',
        routeName: 'subscriber-new',
        path: '/subscribers/new',
        description: 'إنشاء حساب مشترك وربطه بالباقة والحدود المطلوبة.',
      ),
      AppNavItem(
        icon: Icons.online_prediction,
        label: 'المشتركون المتصلون',
        routeName: 'sessions',
        path: '/sessions',
        description:
            'الجلسات الحية، قطع الاتصال، تثبيت MAC أو IP، وسرعة مؤقتة.',
      ),
    ],
  ),
  // ───────── 2) البطاقات ─────────
  AppNavSection(
    id: 'cards',
    icon: Icons.credit_card_outlined,
    label: 'البطاقات',
    items: [
      AppNavItem(
        icon: Icons.fact_check_outlined,
        label: 'فحص بطاقة',
        routeName: 'card-checker',
        path: '/cards/checker',
        description: 'فحص حالة البطاقة وجلساتها وتنفيذ إجراءات التشغيل.',
      ),
      AppNavItem(
        icon: Icons.inventory_2_outlined,
        label: 'حزم البطاقات',
        routeName: 'cards',
        path: '/cards',
        description:
            'إدارة الحزم، التصدير، الاستيراد، وتعطيل أو تفعيل البطاقات.',
      ),
      AppNavItem(
        icon: Icons.add_card_outlined,
        label: 'إضافة حزمة',
        routeName: 'card-batch-new',
        path: '/cards/new',
        description:
            'توليد حزمة بطاقات جديدة حسب الباقة والكمية وطريقة الطباعة.',
      ),
    ],
  ),
  // ───────── 3) البطاقات الإلكترونية ─────────
  AppNavSection(
    id: 'electronic-cards',
    icon: Icons.wallet_outlined,
    label: 'البطاقات الإلكترونية',
    items: [
      AppNavItem(
        icon: Icons.people_alt_outlined,
        label: 'مستخدمو البطاقات',
        routeName: 'card-users',
        path: '/card-users',
        description: 'محافظ مستخدمي البطاقات، المشتريات، الشحن، وكلمة المرور.',
      ),
      AppNavItem(
        icon: Icons.storefront_outlined,
        label: 'دعم وطلبات المتجر',
        routeName: 'store-admin',
        path: '/store-admin',
        description:
            'دعم المتجر: الإيداعات، السحوبات، محافظ الاستلام، والمحادثات.',
      ),
    ],
  ),
  // ───────── 4) العروض والسرعات ─────────
  AppNavSection(
    id: 'offers',
    icon: Icons.local_offer_outlined,
    label: 'العروض والسرعات',
    items: [
      AppNavItem(
        icon: Icons.sell_outlined,
        label: 'قائمة العروض',
        routeName: 'plans',
        path: '/plans',
        description: 'الباقات، الأسعار، السرعات، وحدود الاستخدام.',
      ),
    ],
  ),
  // ───────── 5) الشبكة ─────────
  // Web subgroups (إدارة الراوترات / إضافة وإعداد / التحكم بالسرعة / المراقبة
  // والسجلات) are flattened in web order; «سجل العمليات» (audit) lives here per
  // the web. Per-router bind creds / fingerprints / hidden network-devices keep
  // their routes but are not web sidebar items.
  AppNavSection(
    id: 'network',
    icon: Icons.router_outlined,
    label: 'الشبكة',
    items: [
      AppNavItem(
        icon: Icons.dvr_outlined,
        label: 'غرفة عمليات الراوترات',
        routeName: 'router-operations',
        path: '/router-operations',
        description: 'حالة الراوتر، الموارد، الصحة، الهوية، والوقت.',
      ),
      AppNavItem(
        icon: Icons.dns_outlined,
        label: 'أجهزة الشبكة',
        routeName: 'nas',
        path: '/nas',
        description: 'راوترات ونقاط وصول RADIUS واختبار الاتصال.',
      ),
      AppNavItem(
        icon: Icons.build_outlined,
        label: 'الأدوات',
        routeName: 'tools',
        path: '/tools',
        description: 'تعديل السرعات، اختبار الدخول، سجل RADIUS، والصيانة.',
      ),
    ],
  ),
  // ───────── 6) المال والتحصيل ─────────
  // Web finance hubs (finance_center / accounting / billing) are tabbed; the
  // app keeps granular screens — placed under the same web group, web order.
  AppNavSection(
    id: 'billing',
    icon: Icons.account_balance_wallet_outlined,
    label: 'المال والتحصيل',
    items: [
      AppNavItem(
        icon: Icons.monetization_on_outlined,
        label: 'المركز المالي',
        routeName: 'revenue',
        path: '/revenue',
        description: 'السعر والتحصيل والتكلفة والربح حسب العمليات.',
      ),
      AppNavItem(
        icon: Icons.handshake_outlined,
        label: 'السلف والديون',
        routeName: 'loans-center',
        path: '/loans',
        description: 'متابعة السلف المفتوحة وتسجيل دين أو تسويته.',
      ),
      AppNavItem(
        icon: Icons.fact_check_outlined,
        label: 'التحصيل والمدفوعات',
        routeName: 'payment-collection',
        path: '/payment-collection',
        description: 'مراجعة إثبات الدفع، القبول أو الرفض، وتطبيق الخدمة.',
      ),
    ],
  ),
  // ───────── 7) التشغيل والمخاطر ─────────
  AppNavSection(
    id: 'engagement',
    icon: Icons.warning_amber_outlined,
    label: 'التشغيل والمخاطر',
    items: [
      AppNavItem(
        icon: Icons.event_note_outlined,
        label: 'الأحداث والمخاطر',
        routeName: 'events-center',
        path: '/events',
        description: 'الأحداث التشغيلية والأمنية والمالية.',
      ),
    ],
  ),
  // ───────── 8) التقارير ─────────
  // Web's 5 report subgroups (~24 pages) are consolidated into the financial
  // report screen + the operational-reports hub (which serves all 15 slugs).
  AppNavSection(
    id: 'reports',
    icon: Icons.insights_outlined,
    label: 'التقارير',
    items: [
      AppNavItem(
        icon: Icons.bar_chart_outlined,
        label: 'التقرير المالي',
        routeName: 'financial-reports',
        path: '/reports',
        description: 'تقارير مالية من السجل المحاسبي ومخرجات التصدير.',
      ),
      AppNavItem(
        icon: Icons.query_stats_outlined,
        label: 'تقارير التشغيل',
        routeName: 'operational-reports',
        path: '/operational-reports',
        description: 'جلسات، محاولات دخول، أحداث، وسجل تشغيل.',
      ),
    ],
  ),
  // ───────── 9) الدعم ─────────
  AppNavSection(
    id: 'support',
    icon: Icons.headset_mic_outlined,
    label: 'الدعم',
    items: [
      AppNavItem(
        icon: Icons.support_agent_outlined,
        label: 'التذاكر',
        routeName: 'tickets',
        path: '/tickets',
        description: 'طلبات الخدمة والمحادثات والمتابعة مع الإدارة.',
      ),
    ],
  ),
  // ───────── 10) الإدارة ─────────
  AppNavSection(
    id: 'administration',
    icon: Icons.admin_panel_settings_outlined,
    label: 'الإدارة',
    items: [
      AppNavItem(
        icon: Icons.storefront_outlined,
        label: 'الموزعون',
        routeName: 'distributors',
        path: '/distributors',
        description: 'إدارة الموزعين والحزم والتسويات.',
      ),
      AppNavItem(
        icon: Icons.account_circle_outlined,
        label: 'حسابي',
        routeName: 'account',
        path: '/account',
        description: 'بيانات الدخول وتغيير كلمة المرور.',
      ),
    ],
  ),
];

const mobileNavDestinations = <AppNavItem>[
  dashboardNavItem,
  AppNavItem(
    icon: Icons.person_outline,
    label: 'المشتركون',
    routeName: 'subscribers',
    path: '/subscribers',
  ),
  AppNavItem(
    icon: Icons.credit_card_outlined,
    label: 'البطاقات',
    routeName: 'cards',
    path: '/cards',
  ),
  AppNavItem(
    icon: Icons.online_prediction,
    label: 'المتصلون',
    routeName: 'sessions',
    path: '/sessions',
  ),
  moreNavItem,
];

List<AppNavItem> get appNavigationItems => [
      dashboardNavItem,
      for (final section in appNavSections) ...section.items,
      moreNavItem,
    ];

bool navPathMatches(String location, String path) {
  if (path == '/') return location == '/';
  return location == path || location.startsWith('$path/');
}

bool navSectionIsActive(String location, AppNavSection section) {
  return section.items.any((item) => navPathMatches(location, item.path));
}

int mobileNavIndexForLocation(String location) {
  for (var i = 0; i < mobileNavDestinations.length - 1; i++) {
    if (navPathMatches(location, mobileNavDestinations[i].path)) return i;
  }
  if (location == moreNavItem.path ||
      appNavigationItems.any((item) => navPathMatches(location, item.path))) {
    return mobileNavDestinations.length - 1;
  }
  return 0;
}

AppNavItem? navItemByRouteName(String routeName) {
  for (final item in appNavigationItems) {
    if (item.routeName == routeName) return item;
  }
  return null;
}
