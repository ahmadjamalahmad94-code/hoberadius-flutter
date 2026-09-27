/// Dart mirror of `provider_service_labels.SERVICE_NAMES_AR` (radius-module).
/// Arabic names for provider service-keys shown on the gate screens.
/// Unknown keys fall back to a humanized form (web parity).
library;

const Map<String, String> _serviceNamesAr = {
  'subscribers': 'المشتركون',
  'subscriber_groups': 'مجموعات المشتركين',
  'cards': 'البطاقات',
  'card_users': 'مستخدمو البطاقات',
  'card_marketplace': 'سوق البطاقات',
  'cards_recharge': 'بطاقات الشحن المسبق',
  'card_checker': 'فحص البطاقات',
  'vouchers': 'القسائم',
  'hotspot_cards': 'بطاقات الهوتسبوت',
  'profiles': 'العروض والباقات',
  'plans': 'العروض والباقات',
  'bandwidth_control': 'التحكّم بالسرعة',
  'bandwidth_schedules': 'جدولة السرعات',
  'temp_speed': 'السرعة المؤقتة',
  'finance': 'المالية',
  'accounting': 'المحاسبة والتحصيل',
  'payments': 'الدفعات',
  'invoices': 'الفواتير',
  'ledger': 'دفتر الأستاذ',
  'loans': 'السلف',
  'payment_collection': 'تحصيل المدفوعات',
  'reports': 'التقارير',
  'audit': 'التدقيق',
  'audit_logs': 'سجلّ التدقيق',
  'operational_reports': 'التقارير التشغيلية',
  'events': 'الأحداث',
  'network': 'الشبكة والمايكروتيك',
  'nas': 'أجهزة NAS',
  'routers': 'الراوترات',
  'devices': 'أجهزة الشبكة',
  'device_health': 'تتبّع صحة الأجهزة',
  'network_policy': 'سياسات الشبكة',
  'pools': 'نطاقات العناوين',
  'monitoring': 'المراقبة والصحة',
  'router_alerts': 'تنبيهات الراوترات',
  'router_metrics': 'مقاييس الراوترات',
  'access_control': 'التحكم بالدخول',
  'anti_mac_clone': 'منع استنساخ MAC',
  'security': 'الأمان',
  'admins': 'المدراء والصلاحيات',
  'settings': 'الإعدادات',
  'tenants': 'المستأجرون',
  'backups': 'النسخ الاحتياطية',
  'recycle_bin': 'سلّة المحذوفات',
  'lifecycle': 'دورة الحياة',
  'system': 'النظام',
  'tools': 'الأدوات',
  'business_os': 'أعمال HobeOS',
  'print_templates': 'قوالب الطباعة',
  'communications': 'الرسائل والتنبيهات',
  'customer_portal': 'بوّابة المشترك',
  'service_requests': 'طلبات الخدمات',
  'tickets': 'تذاكر الدعم',
  'store': 'المتجر',
  'store_admin': 'إدارة المتجر',
  'distributors': 'الموزّعون',
  'sessions': 'الجلسات',
  'online': 'المتّصلون الآن',
};

/// Arabic label for a provider service-key. Never returns empty.
String serviceLabelAr(String key) {
  final k = key.trim().toLowerCase();
  if (k.isEmpty) return '';
  final mapped = _serviceNamesAr[k];
  if (mapped != null) return mapped;
  return k.replaceAll('_', ' ').replaceAll('-', ' ').trim();
}
