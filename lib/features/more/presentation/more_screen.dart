import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/tokens.dart';

class _MoreItem {
  const _MoreItem(this.icon, this.label, this.routeName, {this.sub});
  final IconData icon;
  final String label;
  final String routeName;
  final String? sub;
}

const _items = <_MoreItem>[
  _MoreItem(
    Icons.workspace_premium_outlined,
    'الباقات',
    'plans',
    sub: 'عرض الباقات والأسعار',
  ),
  _MoreItem(
    Icons.signal_wifi_4_bar,
    'الجلسات الحيّة',
    'sessions',
    sub: 'المتّصلون الآن + قطع',
  ),
  _MoreItem(
    Icons.manage_search_outlined,
    'فحص بطاقة',
    'card-checker',
    sub: 'حالة البطاقة والجلسات وعمليات التشغيل',
  ),
  _MoreItem(
    Icons.admin_panel_settings_outlined,
    'المدراء',
    'admins',
    sub: 'حسابات الإدارة',
  ),
  _MoreItem(
    Icons.router_outlined,
    'MikroTik',
    'mikrotik',
    sub: 'إعداد اتصال API واختبار الراوترات',
  ),
  _MoreItem(
    Icons.devices_other_outlined,
    'بصمات الأجهزة',
    'device-fingerprints',
    sub: 'MAC، نظام الجهاز، آخر ظهور ومزامنة DHCP',
  ),
  _MoreItem(
    Icons.people_alt_outlined,
    'الموزعون',
    'distributors',
    sub: 'حزم مربوطة ونطاقات تشغيل',
  ),
  _MoreItem(
    Icons.account_balance_wallet_outlined,
    'السجل المالي',
    'ledger',
    sub: 'دفعات وسلف وقيود عكسية',
  ),
  _MoreItem(
    Icons.insert_chart_outlined,
    'التقارير المالية',
    'financial-reports',
    sub: 'مبيعات ودفعات وسلف من Ledger',
  ),
  _MoreItem(
    Icons.query_stats_outlined,
    'تقارير التشغيل',
    'operational-reports',
    sub: 'جلسات، محاولات فاشلة، MAC وأحداث المدراء',
  ),
  _MoreItem(
    Icons.business_center_outlined,
    'الوحدات التجارية',
    'saas-modules',
    sub: 'قسائم، فواتير، خدمات، مجموعات مشاركة، Pools وبروفايلات سرعة',
  ),
  _MoreItem(
    Icons.inventory_2_outlined,
    'سلة المحذوفات',
    'recycle-bin',
    sub: 'استعادة العناصر المؤرشفة بأمان',
  ),
  _MoreItem(
    Icons.storage_outlined,
    'النسخ الاحتياطي',
    'backups',
    sub: 'حالة النسخ المحلي وGoogle Drive لاحقًا',
  ),
  _MoreItem(
    Icons.monitor_heart_outlined,
    'عمليات النظام',
    'system-operations',
    sub: 'حالة الخادم، التشخيص، طابور المزامنة والمطابقة',
  ),
  _MoreItem(
    Icons.manage_accounts_outlined,
    'التحكم الإداري',
    'admin-control',
    sub: 'الإعدادات، مفاتيح API، المستأجرون وWebhooks',
  ),
  _MoreItem(
    Icons.construction_outlined,
    'الأدوات',
    'tools',
    sub: 'تعديل سرعات، اختبار دخول، سجل RADIUS وصيانة آمنة',
  ),
  _MoreItem(
    Icons.speed_outlined,
    'جدولة السرعات',
    'bandwidth-schedules',
    sub: 'جداول وقتية مع تجربة تطبيق فقط',
  ),
  _MoreItem(
    Icons.print_outlined,
    'قوالب الطباعة',
    'print-templates',
    sub: 'تخطيط الكروت ومعاينة JSON بدون PDF',
  ),
  _MoreItem(Icons.shield_outlined, 'الأدوار', 'roles', sub: 'الصلاحيات'),
  _MoreItem(Icons.history, 'سجل التدقيق', 'audit', sub: 'الأحداث الإدارية'),
];

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final admin = auth.admin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (admin != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTokens.cyan500,
                    child: Text(
                      admin.username.isEmpty
                          ? '?'
                          : admin.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin.fullName.isEmpty
                              ? admin.username
                              : admin.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTokens.navy900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          admin.email.isEmpty
                              ? '@${admin.username}'
                              : admin.email,
                          style: const TextStyle(
                            color: AppTokens.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (admin.isSuperAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTokens.cyan100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'مدير عام',
                        style: TextStyle(
                          color: AppTokens.cyan500,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppTokens.s16),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _Tile(item: _items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s16),
        Card(
          color: const Color(0xFFFDE9E9),
          child: ListTile(
            leading: const Icon(Icons.logout, color: AppTokens.red),
            title: const Text(
              'تسجيل خروج',
              style:
                  TextStyle(color: AppTokens.red, fontWeight: FontWeight.w700),
            ),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final _MoreItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTokens.cyan100,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(item.icon, color: AppTokens.cyan500, size: 20),
      ),
      title: Text(
        item.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: item.sub == null ? null : Text(item.sub!),
      trailing: const Icon(Icons.chevron_left, color: AppTokens.textMuted),
      onTap: () => context.goNamed(item.routeName),
    );
  }
}
