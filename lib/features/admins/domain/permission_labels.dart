import 'package:flutter/material.dart';

/// Arabic localisation of permission keys — the Flutter mirror of the web
/// `radius/_perm_labels.html` catalogue.
///
/// Permission keys on the server are fixed English strings (e.g. `users.view`
/// from `ALL_PERMISSIONS`). The `/api/v1/permissions` endpoint localises only
/// the group *prefix* (and only ~10 of them); individual keys come back raw.
/// This catalogue gives every key + group an Arabic label, a group icon, and a
/// group colour identity so the role editor reads like the web matrix instead
/// of showing `users.view`. Unknown keys fall back to the raw key (safe
/// containment — new server permissions never break the screen).

/// Group prefix → Arabic label. Mirrors `GROUP_LABELS`.
const Map<String, String> _groupLabels = {
  'dashboard': 'لوحة التحكم',
  'users': 'المستفيدون',
  'online': 'المتصلون الآن',
  'cards': 'البطاقات',
  'plans': 'الباقات',
  'admin_pricing': 'أسعار العروض',
  'nas': 'أجهزة الشبكة',
  'sessions': 'الجلسات',
  'admins': 'المدراء',
  'reports': 'التقارير',
  'store': 'المتجر الإلكتروني',
  'scope': 'النطاق والإشراف',
  'settings': 'الإعدادات',
  'audit': 'سجل التدقيق',
  'api': 'الواجهة البرمجية',
  'general': 'عام',
};

/// Full permission key → Arabic label. Mirrors `PERM_LABELS`, covering
/// `ALL_PERMISSIONS`.
const Map<String, String> _permLabels = {
  'dashboard.view': 'عرض لوحة التحكم',
  'users.view': 'عرض المستفيدين',
  'users.create': 'إنشاء مستفيد',
  'users.edit': 'تعديل مستفيد',
  'users.delete': 'حذف مستفيد',
  'users.disconnect': 'قطع اتصال مستفيد',
  'users.change_status': 'تفعيل/تعطيل مستفيد',
  'users.extend': 'تجديد وتمديد الاشتراك',
  'users.change_plan': 'تغيير باقة المستفيد',
  'users.quota': 'إضافة كوتا وتصفير يومي',
  'users.balance_add': 'إضافة رصيد للمستفيد',
  'users.payments': 'الشحن النقدي والدفعات',
  'users.loans': 'السلفة وتسوية الديون',
  'users.send_message': 'إرسال رسالة للمستفيد',
  'users.temp_speed': 'التحكم بالسرعة المؤقتة',
  'users.export': 'تصدير جداول البيانات',
  'online.view': 'عرض شاشة المتصلين',
  'online.disconnect': 'قطع اتصال متصل',
  'online.lock_mac': 'إغلاق على عنوان MAC',
  'online.lock_ip': 'تثبيت عنوان IP',
  'cards.view': 'عرض البطاقات',
  'cards.generate': 'توليد بطاقات',
  'cards.revoke': 'إبطال بطاقات',
  'cards.edit_batch': 'تعديل حزمة بطاقات',
  'cards.batch_ops': 'عمليات الحزم الجماعية',
  'cards.import': 'استيراد بطاقات',
  'cards.verify': 'فحص البطاقات وعملياتها',
  'cards.restore': 'استعادة من سلة المحذوفات',
  'cards.recharge': 'بطاقات الشحن',
  'cards.print': 'حزم طباعة البطاقات',
  'plans.view': 'عرض الباقات',
  'plans.create': 'إنشاء باقة',
  'plans.edit': 'تعديل باقة',
  'plans.delete': 'حذف باقة',
  'admin_pricing.view': 'عرض أسعار المدراء',
  'admin_pricing.edit': 'تعديل سعر مدير خاص',
  'admin_pricing.reset': 'إعادة السعر الرسمي',
  'nas.view': 'عرض أجهزة الشبكة',
  'nas.create': 'إضافة جهاز شبكة',
  'nas.edit': 'تعديل جهاز شبكة',
  'nas.delete': 'حذف جهاز شبكة',
  'sessions.view': 'عرض الجلسات',
  'sessions.disconnect': 'قطع جلسة نشطة',
  'admins.view': 'عرض المدراء',
  'admins.create': 'إنشاء مدير',
  'admins.edit': 'تعديل مدير',
  'admins.delete': 'حذف مدير',
  'admins.deposit_balance': 'شحن محفظة مشغّل',
  'admins.policy': 'ضبط صلاحيات المشغّلين',
  'reports.view': 'عرض التقارير',
  'reports.finance': 'التقارير المالية ودفتر القيود',
  'store.review': 'دعم المتجر: تأكيد الإيداع/السحب',
  'scope.act_non_owned': 'التصرف بمشترك غير تابع له',
  'scope.view_all_subscribers': 'رؤية كل المشتركين',
  'scope.view_all_managers': 'رؤية كل المدراء',
  'scope.view_all_cards': 'رؤية كل البطاقات',
  'scope.view_all_reports': 'رؤية تقارير الجميع',
  'scope.view_passwords': 'كشف كلمات السر',
  'settings.view': 'عرض الإعدادات',
  'settings.edit': 'تعديل الإعدادات',
  'audit.view': 'عرض سجل التدقيق',
  'api.use': 'استخدام الواجهة البرمجية',
};

/// Visual identity (icon + soft/ink colours) per group, mirroring `GROUP_META`
/// with Material icons in place of FontAwesome.
class PermissionGroupStyle {
  const PermissionGroupStyle(this.icon, this.soft, this.ink);
  final IconData icon;
  final Color soft;
  final Color ink;
}

const PermissionGroupStyle _generalStyle = PermissionGroupStyle(
  Icons.circle,
  Color(0xFFE2E8F0),
  Color(0xFF334155),
);

const Map<String, PermissionGroupStyle> _groupStyles = {
  'dashboard':
      PermissionGroupStyle(Icons.speed, Color(0xFFE0F2FE), Color(0xFF0369A1)),
  'users':
      PermissionGroupStyle(Icons.group, Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
  'online':
      PermissionGroupStyle(Icons.wifi, Color(0xFFDCFCE7), Color(0xFF15803D)),
  'cards': PermissionGroupStyle(
    Icons.credit_card,
    Color(0xFFEDE9FE),
    Color(0xFF6D28D9),
  ),
  'plans': PermissionGroupStyle(
    Icons.inventory_2,
    Color(0xFFCCFBF1),
    Color(0xFF0F766E),
  ),
  'admin_pricing':
      PermissionGroupStyle(Icons.sell, Color(0xFFFAE8FF), Color(0xFFA21CAF)),
  'nas': PermissionGroupStyle(Icons.dns, Color(0xFFFFEDD5), Color(0xFFC2410C)),
  'sessions': PermissionGroupStyle(
    Icons.cell_tower,
    Color(0xFFCFFAFE),
    Color(0xFF0E7490),
  ),
  'admins': PermissionGroupStyle(
    Icons.admin_panel_settings,
    Color(0xFFFEE2E2),
    Color(0xFFB91C1C),
  ),
  'reports': PermissionGroupStyle(
    Icons.bar_chart,
    Color(0xFFECFCCB),
    Color(0xFF4D7C0F),
  ),
  'store': PermissionGroupStyle(
    Icons.shopping_cart,
    Color(0xFFCCFBF1),
    Color(0xFF0F766E),
  ),
  'scope': PermissionGroupStyle(
    Icons.visibility,
    Color(0xFFFCE7F3),
    Color(0xFFBE185D),
  ),
  'settings': PermissionGroupStyle(
    Icons.settings,
    Color(0xFFEDEAFF),
    Color(0xFF4F46B8),
  ),
  'audit': PermissionGroupStyle(
    Icons.fact_check,
    Color(0xFFFEF3C7),
    Color(0xFFB45309),
  ),
  'api':
      PermissionGroupStyle(Icons.power, Color(0xFFD1FAE5), Color(0xFF047857)),
  'general': _generalStyle,
};

/// Arabic label for a full permission key (`users.view` → «عرض المستفيدين»).
/// Unknown keys are returned unchanged.
String permissionLabel(String key) => _permLabels[key] ?? key;

/// Arabic label for a group prefix. Falls back to [fallback] (e.g. the
/// API-provided label) then the prefix itself.
String permissionGroupLabel(String prefix, {String fallback = ''}) {
  final local = _groupLabels[prefix];
  if (local != null) return local;
  if (fallback.trim().isNotEmpty && fallback != prefix) return fallback;
  return prefix;
}

/// Visual identity for a group prefix; unknown prefixes fall back to «general».
PermissionGroupStyle permissionGroupStyle(String prefix) =>
    _groupStyles[prefix] ?? _generalStyle;

/// The group prefix of a permission key (`users.view` → `users`).
String permissionGroupPrefix(String key) {
  final dot = key.indexOf('.');
  return dot <= 0 ? 'general' : key.substring(0, dot);
}

/// Number of localised permission keys in the catalogue (test/diagnostics).
int permissionLabelCount() => _permLabels.length;

/// True if [key] has an explicit Arabic label (not a raw-key fallback).
bool hasPermissionLabel(String key) => _permLabels.containsKey(key);
