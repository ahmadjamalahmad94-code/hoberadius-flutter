import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';

/// Locks the Flutter nav to the web sidebar structure (docs/STRUCTURE_MAP.md,
/// web source radius-module@main app/templates/admin/_sidebar.html). If the web
/// changes, update both the map and this test in the same commit.
///
/// Deliberate divergence (owner decision 2026-09-27): the web's «التكامل
/// والجسر» group (bridge, licence, activation) is NOT in the operator app —
/// that lives on the web panel only. Its two operational items moved:
/// «تنبيهات تيليجرام» -> «التشغيل والمخاطر», «الأدوات» -> «الشبكة».
void main() {
  test('sidebar groups match the web order + labels exactly', () {
    expect(
      appNavSections.map((s) => s.label).toList(),
      <String>[
        'المشتركون',
        'البطاقات',
        'البطاقات الإلكترونية',
        'العروض والسرعات',
        'الشبكة',
        'المال والتحصيل',
        'التشغيل والمخاطر',
        'التقارير',
        'الدعم',
        'الإدارة',
      ],
    );
  });

  test('dashboard is the standalone first item', () {
    expect(dashboardNavItem.label, 'لوحة التحكم');
    expect(appNavigationItems.first.routeName, 'dashboard');
  });

  test('each group exposes the mapped pages in web order + labels', () {
    // The app menu after the owner's «كله اخفاء» (2026-09-27): only pages an
    // operator needs away from the office. Everything else is web-only
    // (kWebOnlyPaths — routes kept, menu entries hidden).
    final expected = <String, List<String>>{
      'المشتركون': ['المشتركين 360', 'إضافة مشترك', 'المشتركون المتصلون'],
      'البطاقات': ['فحص بطاقة', 'حزم البطاقات', 'إضافة حزمة'],
      'البطاقات الإلكترونية': ['مستخدمو البطاقات', 'دعم وطلبات المتجر'],
      'العروض والسرعات': ['قائمة العروض'],
      'الشبكة': [
        'غرفة عمليات الراوترات',
        'أجهزة الشبكة',
        'سجل العمليات',
        'الأدوات',
      ],
      'المال والتحصيل': [
        'المركز المالي',
        'السلف والديون',
        'الفواتير',
        'التحصيل والمدفوعات',
      ],
      'التشغيل والمخاطر': ['الأحداث والمخاطر'],
      'التقارير': ['التقرير المالي', 'تقارير التشغيل'],
      'الدعم': ['التذاكر'],
      'الإدارة': ['الموزعون', 'حسابي'],
    };
    for (final section in appNavSections) {
      expect(
        section.items.map((i) => i.label).toList(),
        expected[section.label],
        reason: 'مجموعة «${section.label}» لا تطابق ترتيب الويب',
      );
    }
  });

  test('every nav route is unique', () {
    final names = appNavigationItems.map((i) => i.routeName).toList();
    expect(names.toSet().length, names.length);
  });
}
