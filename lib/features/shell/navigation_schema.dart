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
      AppNavItem(
        icon: Icons.print_outlined,
        label: 'قوالب الطباعة',
        routeName: 'print-templates',
        path: '/print-templates',
        description: 'قوالب الطباعة، المعاينة، التصدير، وتجهيز ملفات البطاقات.',
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
        icon: Icons.add_card_outlined,
        label: 'بطاقات الشحن المسبق',
        routeName: 'cards-recharge',
        path: '/cards/recharge',
        description: 'حزم رصيد للمحافظ مع متابعة القيم والحالة.',
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
      AppNavItem(
        icon: Icons.add_business_outlined,
        label: 'إضافة عرض',
        routeName: 'plan-new',
        path: '/plans/new',
        description: 'إنشاء عرض جديد بنفس قواعد لوحة الويب.',
      ),
      AppNavItem(
        icon: Icons.speed_outlined,
        label: 'جدولة السرعات',
        routeName: 'bandwidth-schedules',
        path: '/bandwidth-schedules',
        description: 'سرعات حسب الوقت مع معاينة قبل التطبيق.',
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
        icon: Icons.lan_outlined,
        label: 'نطاقات العناوين',
        routeName: 'radius-resources',
        path: '/radius-resources',
        description: 'تجمعات العناوين ومجموعات المشاركة المرتبطة بالباقات.',
      ),
      AppNavItem(
        icon: Icons.playlist_add_check_outlined,
        label: 'إعداد راوتر متقدم',
        routeName: 'setup-wizard',
        path: '/setup-wizard',
        description: 'تشغيل مراحل الإعداد ومزامنة حالة الخدمات على الراوتر.',
      ),
      AppNavItem(
        icon: Icons.notifications_active_outlined,
        label: 'التنبيهات الذكيّة',
        routeName: 'router-alerts',
        path: '/router-alerts',
        description: 'حدود الانقطاع والترافيك والاستهلاك لكل راوتر.',
      ),
      AppNavItem(
        icon: Icons.history,
        label: 'سجل العمليات',
        routeName: 'audit',
        path: '/audit',
        description: 'الأحداث الإدارية والتغييرات الحساسة.',
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
        icon: Icons.account_balance_wallet_outlined,
        label: 'الخزائن والمحافظ',
        routeName: 'wallets',
        path: '/wallets',
        description: 'إنشاء المحافظ والشحن أو الخصم مع حركة قابلة للتتبع.',
      ),
      AppNavItem(
        icon: Icons.handshake_outlined,
        label: 'السلف والديون',
        routeName: 'loans-center',
        path: '/loans',
        description: 'متابعة السلف المفتوحة وتسجيل دين أو تسويته.',
      ),
      AppNavItem(
        icon: Icons.receipt_long_outlined,
        label: 'السجل والتقارير المحاسبية',
        routeName: 'ledger',
        path: '/ledger',
        description: 'قيود الدفع والسلف والتسويات المالية.',
      ),
      AppNavItem(
        icon: Icons.receipt_outlined,
        label: 'الفواتير',
        routeName: 'invoices',
        path: '/invoices',
        description: 'إصدار الفواتير وتحديث حالتها ومتابعة التحصيل.',
      ),
      AppNavItem(
        icon: Icons.confirmation_number_outlined,
        label: 'الكوبونات',
        routeName: 'vouchers',
        path: '/vouchers',
        description: 'توليد كوبونات الشحن ومراجعة حالتها وإلغاؤها.',
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
        icon: Icons.campaign_outlined,
        label: 'التواصل والحملات',
        routeName: 'communications',
        path: '/communications',
        description: 'قوالب الرسائل والجمهور والحملات وطابور الإرسال.',
      ),
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
      AppNavItem(
        icon: Icons.handyman_outlined,
        label: 'الخدمات / المعدّات',
        routeName: 'saas-modules',
        path: '/saas-modules',
        description: 'الخدمات، القسائم، الفواتير، ومجموعات المشاركة.',
      ),
      AppNavItem(
        icon: Icons.door_front_door_outlined,
        label: 'بوابات العملاء',
        routeName: 'customer-portals',
        path: '/customer-portals',
        description: 'روابط بوابة المشترك وبوابة البطاقة وقيود الأمان.',
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
        icon: Icons.manage_accounts_outlined,
        label: 'المدراء والموزعون',
        routeName: 'admins',
        path: '/admins',
        description: 'حسابات الإدارة وصلاحيات الوصول.',
      ),
      AppNavItem(
        icon: Icons.storefront_outlined,
        label: 'الموزعون',
        routeName: 'distributors',
        path: '/distributors',
        description: 'إدارة الموزعين والحزم والتسويات.',
      ),
      AppNavItem(
        icon: Icons.security_outlined,
        label: 'الأدوار والصلاحيات',
        routeName: 'roles',
        path: '/roles',
        description: 'مجموعات الصلاحيات وقواعد الوصول.',
      ),
      AppNavItem(
        icon: Icons.business_center_outlined,
        label: 'مشغّلو الأعمال',
        routeName: 'business-ops',
        path: '/business-ops',
        description:
            'السجل المالي للأعمال، قيود التصحيح، ولقطات التسعير الثابتة.',
      ),
      AppNavItem(
        icon: Icons.backup_outlined,
        label: 'البيانات والحفظ والأرشفة',
        routeName: 'backups',
        path: '/backups',
        description: 'حالة النسخ المحلي والنسخ الخارجي عند تفعيله.',
      ),
      AppNavItem(
        icon: Icons.restore_from_trash_outlined,
        label: 'سلة المحذوفات',
        routeName: 'recycle-bin',
        path: '/recycle-bin',
        description: 'استعادة العناصر المؤرشفة بأمان.',
      ),
      AppNavItem(
        icon: Icons.event_repeat_outlined,
        label: 'الأرشفة التلقائية',
        routeName: 'lifecycle',
        path: '/lifecycle',
        description: 'سياسات الاحتفاظ ومعاينة الأرشفة قبل التنفيذ.',
      ),
      AppNavItem(
        icon: Icons.settings_outlined,
        label: 'إعدادات النظام',
        routeName: 'admin-control',
        path: '/admin-control',
        description: 'الإعدادات، مفاتيح الربط، المستأجرون، واستدعاءات الويب.',
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
  // ───────── 11) التكامل والجسر ─────────
  AppNavSection(
    id: 'integration',
    icon: Icons.cable_outlined,
    label: 'التكامل والجسر',
    items: [
      AppNavItem(
        icon: Icons.hub_outlined,
        label: 'جسر الإدارة',
        routeName: 'system-operations',
        path: '/system-operations',
        description: 'حالة الخادم، التشخيص، المزامنة، والمطابقة.',
      ),
      AppNavItem(
        icon: Icons.verified_user_outlined,
        label: 'ترخيص النظام',
        routeName: 'license-file',
        path: '/license-file',
        description: 'عقد الترخيص، مزامنة الهوية، الخدمات، وسر الربط.',
      ),
      AppNavItem(
        icon: Icons.notifications_active_outlined,
        label: 'تنبيهات تيليجرام',
        routeName: 'telegram-alerts',
        path: '/alerts/telegram',
        description: 'إعداد بوت تيليجرام وتفعيل تنبيهات النظام واختبارها.',
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
