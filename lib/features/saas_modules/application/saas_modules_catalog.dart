import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saas_modules_repository.dart';
import '../domain/saas_module_model.dart';

class SaasModuleDef {
  const SaasModuleDef({
    required this.title,
    required this.subtitle,
    required this.path,
    required this.fields,
    required this.columns,
    this.createLabel = 'إضافة',
    this.canDelete = false,
    this.canRevokeVoucher = false,
    this.canMarkPaid = false,
    this.canReply = false,
  });

  final String title;
  final String subtitle;
  final String path;
  final List<SaasModuleField> fields;
  final List<String> columns;
  final String createLabel;
  final bool canDelete;
  final bool canRevokeVoucher;
  final bool canMarkPaid;
  final bool canReply;
}

class SaasModuleField {
  const SaasModuleField(
    this.key,
    this.label, {
    this.number = false,
    this.defaultValue = '',
  });

  final String key;
  final String label;
  final bool number;
  final String defaultValue;
}

const Map<String, SaasModuleDef> kSaasModules = {
  'bandwidth': SaasModuleDef(
    title: 'بروفايلات السرعة',
    subtitle: 'قوالب سرعة محفوظة للاستخدام مع الباقات والمشتركين.',
    path: '/api/v1/bandwidth-profiles',
    fields: [
      SaasModuleField('name', 'الاسم'),
      SaasModuleField('rate_down', 'تنزيل Kbps', number: true),
      SaasModuleField('rate_up', 'رفع Kbps', number: true),
      SaasModuleField('priority', 'الأولوية', number: true),
    ],
    columns: ['name', 'rate_down', 'rate_up', 'priority'],
    canDelete: true,
  ),
  'pools': SaasModuleDef(
    title: 'مجموعات العناوين',
    subtitle: 'IP pools كما تظهر في الويب.',
    path: '/api/v1/pools',
    fields: [
      SaasModuleField('pool_name', 'اسم المجموعة'),
      SaasModuleField('range_ip', 'نطاق العناوين'),
      SaasModuleField('local_ip', 'العنوان المحلي'),
    ],
    columns: ['pool_name', 'range_ip', 'local_ip'],
    canDelete: true,
  ),
  'vouchers': SaasModuleDef(
    title: 'قسائم الشحن',
    subtitle: 'إنشاء قسائم وشحنها أو إلغاؤها من الخادم.',
    path: '/api/v1/vouchers',
    createLabel: 'توليد قسائم',
    fields: [
      SaasModuleField('amount', 'القيمة', number: true),
      SaasModuleField('count', 'العدد', number: true, defaultValue: '1'),
      SaasModuleField('plan_id', 'رقم الباقة', number: true),
    ],
    columns: ['code', 'amount', 'status', 'created_at'],
    canRevokeVoucher: true,
  ),
  'invoices': SaasModuleDef(
    title: 'الفواتير',
    subtitle: 'فواتير تشغيلية بدون حذف نهائي.',
    path: '/api/v1/invoices',
    fields: [
      SaasModuleField('subscriber_id', 'رقم المستفيد', number: true),
      SaasModuleField('username', 'اسم الدخول'),
      SaasModuleField('amount', 'المبلغ', number: true),
      SaasModuleField('note', 'ملاحظة'),
    ],
    columns: ['invoice_number', 'username', 'amount', 'status'],
    canMarkPaid: true,
  ),
  'tickets': SaasModuleDef(
    title: 'التذاكر',
    subtitle: 'شكاوى ومتابعة المستفيدين.',
    path: '/api/v1/tickets',
    fields: [
      SaasModuleField('subscriber_id', 'رقم المستفيد', number: true),
      SaasModuleField('subject', 'العنوان'),
      SaasModuleField('body', 'الوصف'),
    ],
    columns: ['subject', 'status', 'priority', 'created_at'],
    canReply: true,
  ),
  'services': SaasModuleDef(
    title: 'الخدمات والمعدات',
    subtitle: 'أجهزة أو خدمات مرتبطة بالمستفيد.',
    path: '/api/v1/services',
    fields: [
      SaasModuleField('subscriber_id', 'رقم المستفيد', number: true),
      SaasModuleField('name', 'الاسم'),
      SaasModuleField('serial', 'السيريال'),
      SaasModuleField('mac', 'MAC'),
      SaasModuleField('rent_per_month', 'الإيجار الشهري', number: true),
    ],
    columns: ['name', 'subscriber_id', 'status', 'rent_per_month'],
    canDelete: true,
  ),
  'share-groups': SaasModuleDef(
    title: 'مجموعات المشاركة',
    subtitle: 'مشاركة حصة أو سرعة بين أكثر من مستفيد.',
    path: '/api/v1/share-groups',
    fields: [
      SaasModuleField('name', 'الاسم'),
      SaasModuleField('shared_quota_mb', 'الحصة MB', number: true),
      SaasModuleField('shared_speed_down_kbps', 'سرعة التنزيل', number: true),
      SaasModuleField('shared_speed_up_kbps', 'سرعة الرفع', number: true),
      SaasModuleField('max_members', 'أقصى عدد أعضاء', number: true),
    ],
    columns: ['name', 'members', 'shared_quota_mb', 'enabled'],
    canDelete: true,
  ),
};

final saasModuleProvider =
    FutureProvider.autoDispose.family<SaasModuleSnapshot, String>((ref, key) {
  final def = kSaasModules[key]!;
  return ref.watch(saasModulesRepositoryProvider).list(def.path);
});

String saasFieldLabel(String key) {
  const labels = {
    'name': 'الاسم',
    'pool_name': 'المجموعة',
    'range_ip': 'النطاق',
    'local_ip': 'العنوان المحلي',
    'rate_down': 'تنزيل',
    'rate_up': 'رفع',
    'priority': 'الأولوية',
    'code': 'الكود',
    'amount': 'المبلغ',
    'status': 'الحالة',
    'created_at': 'تاريخ الإنشاء',
    'invoice_number': 'الفاتورة',
    'username': 'اسم الدخول',
    'subject': 'العنوان',
    'rent_per_month': 'الإيجار',
    'subscriber_id': 'المستفيد',
    'shared_quota_mb': 'الحصة',
    'members': 'الأعضاء',
    'enabled': 'مفعلة',
  };
  return labels[key] ?? key;
}
