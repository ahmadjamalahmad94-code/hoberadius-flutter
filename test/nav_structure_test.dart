import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';

/// Locks the Flutter nav to the web sidebar structure (docs/STRUCTURE_MAP.md,
/// web source radius-module@main app/templates/admin/_sidebar.html). If the web
/// changes, update both the map and this test in the same commit.
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
        'التكامل والجسر',
      ],
    );
  });

  test('dashboard is the standalone first item', () {
    expect(dashboardNavItem.label, 'لوحة التحكم');
    expect(appNavigationItems.first.routeName, 'dashboard');
  });

  test('each group exposes the mapped pages in web order + labels', () {
    final expected = <String, List<String>>{
      'المشتركون': ['المشتركين 360', 'إضافة مشترك', 'المشتركون المتصلون'],
      'البطاقات': [
        'فحص بطاقة',
        'حزم البطاقات',
        'إضافة حزمة',
        'قوالب الطباعة',
      ],
      'البطاقات الإلكترونية': [
        'مستخدمو البطاقات',
        'بطاقات الشحن المسبق',
        'دعم وطلبات المتجر',
      ],
      'العروض والسرعات': ['قائمة العروض', 'إضافة عرض', 'جدولة السرعات'],
      'الشبكة': [
        'غرفة عمليات الراوترات',
        'أجهزة الشبكة',
        'نطاقات العناوين',
        'إعداد راوتر متقدم',
        'التنبيهات الذكيّة',
        'سجل العمليات',
      ],
      'المال والتحصيل': [
        'المركز المالي',
        'الخزائن والمحافظ',
        'السلف والديون',
        'السجل والتقارير المحاسبية',
        'الفواتير',
        'الكوبونات',
        'التحصيل والمدفوعات',
      ],
      'التشغيل والمخاطر': ['التواصل والحملات', 'الأحداث والمخاطر'],
      'التقارير': ['التقرير المالي', 'تقارير التشغيل'],
      'الدعم': ['التذاكر', 'الخدمات / المعدّات', 'بوابات العملاء'],
      'الإدارة': [
        'المدراء والموزعون',
        'الموزعون',
        'الأدوار والصلاحيات',
        'مشغّلو الأعمال',
        'البيانات والحفظ والأرشفة',
        'سلة المحذوفات',
        'الأرشفة التلقائية',
        'إعدادات النظام',
        'حسابي',
      ],
      'التكامل والجسر': [
        'جسر الإدارة',
        'ترخيص النظام',
        'تنبيهات تيليجرام',
        'الأدوات',
      ],
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
