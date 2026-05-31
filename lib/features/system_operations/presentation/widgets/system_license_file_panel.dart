import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/system_operations_providers.dart';
import '../../domain/system_operations_model.dart';

class SystemLicenseFilePanel extends StatelessWidget {
  const SystemLicenseFilePanel({
    super.key,
    required this.state,
    required this.busyAction,
    required this.onSyncLicense,
    required this.onSyncIdentity,
    required this.onHeartbeat,
  });

  final LicenseFileState state;
  final String? busyAction;
  final VoidCallback onSyncLicense;
  final VoidCallback onSyncIdentity;
  final VoidCallback onHeartbeat;

  @override
  Widget build(BuildContext context) {
    final services = state.services.entries.toList();
    return AppCard(
      title: 'ملف الترخيص والمزامنة',
      icon: Icons.verified_user_outlined,
      actions: [
        _ActionButton(
          label: 'تحديث العقد',
          icon: Icons.sync,
          busy: busyAction == 'license',
          onPressed: onSyncLicense,
        ),
        _ActionButton(
          label: 'مزامنة الهوية',
          icon: Icons.manage_accounts_outlined,
          busy: busyAction == 'identity',
          onPressed: onSyncIdentity,
        ),
        _ActionButton(
          label: 'فحص النبض',
          icon: Icons.monitor_heart_outlined,
          busy: busyAction == 'heartbeat',
          onPressed: onHeartbeat,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: state.config.enabled ? 'الربط مفعل' : 'الربط متوقف',
                tone: state.config.enabled ? PillTone.green : PillTone.neutral,
                dot: true,
              ),
              StatusPill(
                text: state.config.httpsReady ? 'HTTPS جاهز' : 'HTTPS غير جاهز',
                tone:
                    state.config.httpsReady ? PillTone.green : PillTone.orange,
                dot: true,
              ),
              StatusPill(
                text: state.config.licenseKeyConfigured
                    ? 'مفتاح الترخيص محفوظ'
                    : 'مفتاح الترخيص ناقص',
                tone: state.config.licenseKeyConfigured
                    ? PillTone.green
                    : PillTone.orange,
                dot: true,
              ),
              StatusPill(
                text: state.config.sharedSecretConfigured
                    ? 'سر الربط محفوظ'
                    : 'سر الربط ناقص',
                tone: state.config.sharedSecretConfigured
                    ? PillTone.green
                    : PillTone.orange,
                dot: true,
              ),
              StatusPill(
                text: state.config.runtimeContractSync
                    ? 'عقد التشغيل مفعل'
                    : 'عقد التشغيل متوقف',
                tone: state.config.runtimeContractSync
                    ? PillTone.green
                    : PillTone.neutral,
                dot: true,
              ),
              StatusPill(
                text: state.config.identitySyncEnabled
                    ? 'مزامنة الهوية مفعلة'
                    : 'مزامنة الهوية متوقفة',
                tone: state.config.identitySyncEnabled
                    ? PillTone.green
                    : PillTone.neutral,
                dot: true,
              ),
              StatusPill(
                text: state.config.workerEnabled
                    ? 'العامل الخلفي مفعل'
                    : 'العامل الخلفي متوقف',
                tone: state.config.workerEnabled
                    ? PillTone.green
                    : PillTone.neutral,
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          _InfoGrid(
            items: [
              _InfoItem(
                'لوحة التراخيص',
                state.config.baseUrl.isEmpty
                    ? 'غير محددة'
                    : state.config.baseUrl,
                Icons.link,
              ),
              _InfoItem(
                'مفتاح الترخيص',
                state.config.licenseKeyConfigured
                    ? state.config.licenseKeyMasked
                    : 'غير محفوظ',
                Icons.vpn_key_outlined,
              ),
              _InfoItem(
                'فاصل المزامنة',
                '${state.config.syncIntervalSeconds} ثانية',
                Icons.timer_outlined,
              ),
              _InfoItem(
                'الخدمات الفعالة',
                '${state.activeServicesCount} من ${state.services.length}',
                Icons.toggle_on_outlined,
              ),
            ],
          ),
          if (state.hasMissingConfig) ...[
            const SizedBox(height: AppTokens.s12),
            _WarningBox(
              title: 'إعدادات ناقصة',
              lines: state.missing.map(_missingLabel).toList(),
            ),
          ],
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 780;
              final snapshots = [
                _SnapshotTile(
                  title: 'الترخيص',
                  snapshot: state.snapshots['license'],
                ),
                _SnapshotTile(
                  title: 'عقد التشغيل',
                  snapshot: state.snapshots['runtime_contract'],
                ),
                _SnapshotTile(
                  title: 'مزامنة الهوية',
                  snapshot: state.snapshots['identity_sync'],
                ),
              ];
              if (!wide) {
                return Column(
                  children: [
                    for (final tile in snapshots) ...[
                      tile,
                      const SizedBox(height: AppTokens.s8),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < snapshots.length; i++) ...[
                    Expanded(child: snapshots[i]),
                    if (i != snapshots.length - 1)
                      const SizedBox(width: AppTokens.s8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            'الخدمات المستلمة من لوحة التراخيص',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTokens.textPrimary,
                ),
          ),
          const SizedBox(height: AppTokens.s8),
          if (services.isEmpty)
            const Text(
              'لم يصل عقد خدمات بعد. شغل تحديث العقد بعد اكتمال إعدادات الربط.',
              style: TextStyle(color: AppTokens.textSecondary),
            )
          else
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                for (final entry in services)
                  StatusPill(
                    text:
                        '${_serviceLabel(entry.key)}: ${systemStatusLabel(_serviceStatus(entry.value))}',
                    tone: systemStatusTone(_serviceStatus(entry.value)),
                    dot: true,
                  ),
              ],
            ),
          if (state.limits.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: [
                for (final entry in state.limits.entries.take(8))
                  _SoftChip(
                    label: _limitLabel(entry.key),
                    value: _limitSummary(entry.value),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 860
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: AppTokens.s8,
          mainAxisSpacing: AppTokens.s8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 1 ? 3.8 : 2.4,
          children: items.map(_InfoTile.new).toList(),
        );
      },
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.item);

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.warningBg,
        border: Border.all(color: AppTokens.warningMed),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppTokens.warningFg),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTokens.warningFg,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  lines.join('، '),
                  style: const TextStyle(color: AppTokens.warningFg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({required this.title, required this.snapshot});

  final String title;
  final BridgeSnapshotSummary? snapshot;

  @override
  Widget build(BuildContext context) {
    final item = snapshot;
    final status = item?.status ?? 'missing';
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.card,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                text: systemStatusLabel(status),
                tone: systemStatusTone(status),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            _snapshotTime(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        border: Border.all(color: AppTokens.brandLine),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppTokens.brandInk,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _snapshotTime(BridgeSnapshotSummary? item) {
  if (item == null || !item.available) return 'لا توجد مزامنة محفوظة بعد';
  if (item.fetchedAt.isNotEmpty) return 'آخر جلب: ${item.fetchedAt}';
  if (item.createdAt.isNotEmpty) return 'آخر حفظ: ${item.createdAt}';
  return 'وقت المزامنة غير متوفر';
}

String _serviceStatus(Object? value) {
  final map =
      value is Map ? value.map((key, val) => MapEntry('$key', val)) : {};
  if (map['enabled'] == false) return 'disabled';
  return (map['status'] ?? (map['enabled'] == true ? 'active' : 'unknown'))
      .toString();
}

String _limitSummary(Object? value) {
  if (value is Map) {
    final total = value['max_total'];
    final monthly = value['monthly_generated'];
    final batch = value['generate_per_batch'];
    if (total != null) return 'حتى $total';
    if (monthly != null) return 'شهريًا $monthly';
    if (batch != null) return 'كل دفعة $batch';
  }
  return 'محدد';
}

String _missingLabel(String key) {
  return switch (key) {
    'HOBERADIUS_ADMIN_BASE_URL' => 'رابط لوحة التراخيص',
    'HOBERADIUS_LICENSE_KEY or INSTANCE_LICENSE_KEY' => 'مفتاح الترخيص',
    'HOBERADIUS_ADMIN_SHARED_SECRET' => 'سر الربط',
    _ => 'إعداد مطلوب',
  };
}

String _serviceLabel(String key) {
  return switch (key) {
    'ip_change_vpn' => 'تغيير IP / VPN',
    'payment_collection' => 'تحصيل المدفوعات',
    'customer_portal' => 'بوابة العميل',
    'customer_support' => 'الدعم الفني',
    'cards' => 'الكروت',
    'cards_recharge' => 'شحن الكروت',
    'communications' => 'الرسائل والتنبيهات',
    'distributors' => 'الموزعون',
    'finance_center' => 'المركز المالي',
    'integration_bridge' => 'ربط لوحة التراخيص',
    'integration_tokens' => 'مفاتيح الربط',
    'subscribers' => 'المشتركين',
    'sessions' => 'الجلسات',
    'nas' => 'أجهزة NAS',
    'mikrotik' => 'مايكروتك',
    'reports' => 'التقارير',
    'backups' => 'النسخ الاحتياطي',
    _ => 'خدمة مرخّصة إضافية',
  };
}

String _limitLabel(String key) {
  return switch (key) {
    'subscribers' => 'المشتركين',
    'cards' => 'الكروت',
    'nas' => 'أجهزة NAS',
    'routers' => 'الراوترات',
    'sessions' => 'الجلسات',
    'vpn_users' => 'مستخدمي VPN',
    _ => 'حد إضافي',
  };
}
