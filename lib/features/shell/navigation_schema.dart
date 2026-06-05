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

const appNavSections = <AppNavSection>[
  AppNavSection(
    id: 'subscribers',
    icon: Icons.groups_2_outlined,
    label: 'المشتركون',
    items: [
      AppNavItem(
        icon: Icons.list_alt_outlined,
        label: 'قائمة المشتركين',
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
        label: 'المتصلون الآن',
        routeName: 'sessions',
        path: '/sessions',
        description:
            'الجلسات الحية، قطع الاتصال، تثبيت MAC أو IP، وسرعة مؤقتة.',
      ),
    ],
  ),
  AppNavSection(
    id: 'cards',
    icon: Icons.credit_card_outlined,
    label: 'البطاقات',
    items: [
      AppNavItem(
        icon: Icons.inventory_2_outlined,
        label: 'حزم البطاقات',
        routeName: 'cards',
        path: '/cards',
        description:
            'إدارة الحزم، التصدير، الاستيراد، وتعطيل أو تفعيل البطاقات.',
      ),
      AppNavItem(
        icon: Icons.fact_check_outlined,
        label: 'فحص بطاقة',
        routeName: 'card-checker',
        path: '/cards/checker',
        description: 'فحص حالة البطاقة وجلساتها وتنفيذ إجراءات التشغيل.',
      ),
      AppNavItem(
        icon: Icons.add_card_outlined,
        label: 'حزمة جديدة',
        routeName: 'card-batch-new',
        path: '/cards/new',
        description:
            'توليد حزمة بطاقات جديدة حسب الباقة والكمية وطريقة الطباعة.',
      ),
      AppNavItem(
        icon: Icons.upload_file_outlined,
        label: 'استيراد ملف',
        routeName: 'card-batch-import',
        path: '/cards/import',
        description: 'استيراد بطاقات جاهزة مع معاينة قبل الحفظ.',
      ),
      AppNavItem(
        icon: Icons.people_alt_outlined,
        label: 'مستخدمو البطاقات',
        routeName: 'card-users',
        path: '/card-users',
        description: 'محافظ مستخدمي البطاقات، المشتريات، الشحن، وكلمة المرور.',
      ),
      AppNavItem(
        icon: Icons.add_card_outlined,
        label: 'كروت الشحن',
        routeName: 'cards-recharge',
        path: '/cards/recharge',
        description: 'حزم رصيد للمحافظ مع متابعة القيم والحالة.',
      ),
      AppNavItem(
        icon: Icons.print_outlined,
        label: 'تصميم وتصدير',
        routeName: 'print-templates',
        path: '/print-templates',
        description: 'قوالب الطباعة، المعاينة، التصدير، وتجهيز ملفات البطاقات.',
      ),
    ],
  ),
  AppNavSection(
    id: 'plans',
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
  AppNavSection(
    id: 'network',
    icon: Icons.router_outlined,
    label: 'الشبكة والراوترات',
    items: [
      AppNavItem(
        icon: Icons.dns_outlined,
        label: 'أجهزة الشبكة',
        routeName: 'nas',
        path: '/nas',
        description: 'راوترات ونقاط وصول RADIUS واختبار الاتصال.',
      ),
      AppNavItem(
        icon: Icons.wifi_tethering,
        label: 'اتصالات ميكروتك',
        routeName: 'mikrotik',
        path: '/mikrotik',
        description: 'بيانات ربط MikroTik واختبارها بأمان.',
      ),
      AppNavItem(
        icon: Icons.monitor_heart_outlined,
        label: 'عمليات الراوتر',
        routeName: 'router-operations',
        path: '/router-operations',
        description: 'حالة الراوتر، الموارد، الصحة، الهوية، والوقت.',
      ),
      AppNavItem(
        icon: Icons.playlist_add_check_outlined,
        label: 'معالج إعداد الراوترات',
        routeName: 'setup-wizard',
        path: '/setup-wizard',
        description: 'تشغيل مراحل الإعداد ومزامنة حالة الخدمات على الراوتر.',
      ),
      AppNavItem(
        icon: Icons.fingerprint_outlined,
        label: 'بصمات الأجهزة',
        routeName: 'device-fingerprints',
        path: '/device-fingerprints',
        description: 'أثر الأجهزة حسب العنوان الفيزيائي وآخر ظهور.',
      ),
      AppNavItem(
        icon: Icons.devices_other_outlined,
        label: 'مراقبة أجهزة الشبكة',
        routeName: 'network-devices',
        path: '/network-devices',
        description: 'السويتشات والكاميرات ونقاط الوصول وفحص الاستجابة.',
      ),
      AppNavItem(
        icon: Icons.notifications_active_outlined,
        label: 'تنبيهات الراوترات',
        routeName: 'router-alerts',
        path: '/router-alerts',
        description: 'حدود الانقطاع والترافيك والاستهلاك لكل راوتر.',
      ),
      AppNavItem(
        icon: Icons.policy_outlined,
        label: 'سياسات الشبكة',
        routeName: 'network-policy',
        path: '/network-policy',
        description: 'الوصول البعيد، حظر المواقع، والمواقع المسموحة.',
      ),
      AppNavItem(
        icon: Icons.hub_outlined,
        label: 'موارد التشغيل',
        routeName: 'radius-resources',
        path: '/radius-resources',
        description: 'تجمعات العناوين ومجموعات المشاركة المرتبطة بالباقات.',
      ),
    ],
  ),
  AppNavSection(
    id: 'finance',
    icon: Icons.account_balance_wallet_outlined,
    label: 'التحصيل والمحاسبة',
    items: [
      AppNavItem(
        icon: Icons.receipt_long_outlined,
        label: 'السجل والتقارير المحاسبية',
        routeName: 'ledger',
        path: '/ledger',
        description: 'قيود الدفع والسلف والتسويات المالية.',
      ),
      AppNavItem(
        icon: Icons.fact_check_outlined,
        label: 'التحصيل والمدفوعات',
        routeName: 'payment-collection',
        path: '/payment-collection',
        description: 'مراجعة إثبات الدفع، القبول أو الرفض، وتطبيق الخدمة.',
      ),
      AppNavItem(
        icon: Icons.receipt_long_outlined,
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
        icon: Icons.monetization_on_outlined,
        label: 'الإيرادات',
        routeName: 'revenue',
        path: '/revenue',
        description: 'السعر والتحصيل والتكلفة والربح حسب العمليات.',
      ),
      AppNavItem(
        icon: Icons.bar_chart_outlined,
        label: 'التقارير المالية',
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
  AppNavSection(
    id: 'support',
    icon: Icons.support_agent_outlined,
    label: 'الدعم والبوابات',
    items: [
      AppNavItem(
        icon: Icons.support_agent_outlined,
        label: 'تذاكر الدعم',
        routeName: 'tickets',
        path: '/tickets',
        description: 'طلبات الخدمة والمحادثات والمتابعة مع الإدارة.',
      ),
      AppNavItem(
        icon: Icons.door_front_door_outlined,
        label: 'بوابات العملاء',
        routeName: 'customer-portals',
        path: '/customer-portals',
        description: 'روابط بوابة المشترك وبوابة البطاقة وقيود الأمان.',
      ),
      AppNavItem(
        icon: Icons.campaign_outlined,
        label: 'التواصل والحملات',
        routeName: 'communications',
        path: '/communications',
        description: 'قوالب الرسائل والجمهور والحملات وطابور الإرسال.',
      ),
      AppNavItem(
        icon: Icons.business_center_outlined,
        label: 'الوحدات التجارية',
        routeName: 'saas-modules',
        path: '/saas-modules',
        description: 'الخدمات، القسائم، الفواتير، ومجموعات المشاركة.',
      ),
    ],
  ),
  AppNavSection(
    id: 'admin',
    icon: Icons.admin_panel_settings_outlined,
    label: 'الإدارة والصلاحيات',
    items: [
      AppNavItem(
        icon: Icons.account_circle_outlined,
        label: 'حسابي',
        routeName: 'account',
        path: '/account',
        description: 'بيانات الدخول وتغيير كلمة المرور.',
      ),
      AppNavItem(
        icon: Icons.manage_accounts_outlined,
        label: 'المدراء',
        routeName: 'admins',
        path: '/admins',
        description: 'حسابات الإدارة وصلاحيات الوصول.',
      ),
      AppNavItem(
        icon: Icons.security_outlined,
        label: 'الأدوار',
        routeName: 'roles',
        path: '/roles',
        description: 'مجموعات الصلاحيات وقواعد الوصول.',
      ),
      AppNavItem(
        icon: Icons.history,
        label: 'سجل التدقيق',
        routeName: 'audit',
        path: '/audit',
        description: 'الأحداث الإدارية والتغييرات الحساسة.',
      ),
      AppNavItem(
        icon: Icons.storefront_outlined,
        label: 'الموزعون',
        routeName: 'distributors',
        path: '/distributors',
        description: 'إدارة الموزعين والحزم والتسويات.',
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
        icon: Icons.backup_outlined,
        label: 'النسخ الاحتياطي',
        routeName: 'backups',
        path: '/backups',
        description: 'حالة النسخ المحلي والنسخ الخارجي عند تفعيله.',
      ),
    ],
  ),
  AppNavSection(
    id: 'integration',
    icon: Icons.tune_outlined,
    label: 'التكامل والجسر',
    items: [
      AppNavItem(
        icon: Icons.monitor_heart_outlined,
        label: 'عمليات النظام',
        routeName: 'system-operations',
        path: '/system-operations',
        description: 'حالة الخادم، التشخيص، المزامنة، والمطابقة.',
      ),
      AppNavItem(
        icon: Icons.verified_user_outlined,
        label: 'ملف الترخيص والمزامنة',
        routeName: 'license-file',
        path: '/license-file',
        description: 'عقد الترخيص، مزامنة الهوية، الخدمات، وسر الربط.',
      ),
      AppNavItem(
        icon: Icons.event_note_outlined,
        label: 'مركز الأحداث',
        routeName: 'events-center',
        path: '/events',
        description: 'الأحداث التشغيلية والأمنية والمالية.',
      ),
      AppNavItem(
        icon: Icons.settings_outlined,
        label: 'التحكم الإداري',
        routeName: 'admin-control',
        path: '/admin-control',
        description: 'الإعدادات، مفاتيح الربط، المستأجرون، واستدعاءات الويب.',
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
