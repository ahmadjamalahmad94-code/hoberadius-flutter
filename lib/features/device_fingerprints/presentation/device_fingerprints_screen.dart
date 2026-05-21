import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/device_fingerprints_repository.dart';
import '../domain/device_fingerprint_model.dart';

final deviceFingerprintsProvider =
    FutureProvider.autoDispose.family<DeviceFingerprintsPage, String>(
  (ref, osFamily) =>
      ref.watch(deviceFingerprintsRepositoryProvider).list(osFamily: osFamily),
);

class DeviceFingerprintsScreen extends ConsumerStatefulWidget {
  const DeviceFingerprintsScreen({super.key});

  @override
  ConsumerState<DeviceFingerprintsScreen> createState() =>
      _DeviceFingerprintsScreenState();
}

class _DeviceFingerprintsScreenState
    extends ConsumerState<DeviceFingerprintsScreen> {
  final _search = TextEditingController();
  String _osFamily = 'all';
  bool _syncing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(deviceFingerprintsProvider(_osFamily));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'بصمات الأجهزة',
          subtitle:
              'أجهزة ظهرت من DHCP leases في MikroTik. هذه بيانات قراءة ومزامنة فقط ولا تكشف كلمات مرور.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () =>
                  ref.invalidate(deviceFingerprintsProvider(_osFamily)),
              icon: const Icon(Icons.refresh),
            ),
            ElevatedButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_syncing ? 'جار المزامنة...' : 'مزامنة الآن'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'بحث',
                  hintText: 'MAC، اسم جهاز، IP، نظام، موديل...',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  for (final option in _osOptions)
                    ChoiceChip(
                      selected: _osFamily == option.value,
                      label: Text(option.label),
                      onSelected: (_) => setState(() {
                        _osFamily = option.value;
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب بصمات الأجهزة',
            subtitle: '$error',
            action: OutlinedButton.icon(
              onPressed: () =>
                  ref.invalidate(deviceFingerprintsProvider(_osFamily)),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (page) {
            final items =
                page.items.where((item) => item.matches(_search.text)).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(page: page, shown: items.length),
                const SizedBox(height: AppTokens.s12),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.devices_other_outlined,
                    title: 'لا توجد أجهزة مطابقة',
                    subtitle:
                        'جرّب تغيير الفلتر أو تشغيل المزامنة إذا كانت بيانات الراوتر جاهزة.',
                  )
                else
                  for (final item in items) ...[
                    _DeviceCard(item: item),
                    const SizedBox(height: AppTokens.s12),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      final result =
          await ref.read(deviceFingerprintsRepositoryProvider).syncNow();
      ref.invalidate(deviceFingerprintsProvider(_osFamily));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت المزامنة. أجهزة مرئية: ${result.macsSeen}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.page, required this.shown});

  final DeviceFingerprintsPage page;
  final int shown;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 720 ? 3 : 1;
        return GridView.count(
          crossAxisCount: cols,
          crossAxisSpacing: AppTokens.s8,
          mainAxisSpacing: AppTokens.s8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cols == 1 ? 3.2 : 2.1,
          children: [
            _MetricCard(
              title: 'إجمالي محفوظ',
              value: '${page.total}',
              icon: Icons.devices_other_outlined,
            ),
            _MetricCard(
              title: 'المعروض الآن',
              value: '$shown',
              icon: Icons.filter_alt_outlined,
            ),
            _MetricCard(
              title: 'حد القراءة',
              value: '${page.limit}',
              icon: Icons.format_list_numbered,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.item});

  final DeviceFingerprint item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(_osIcon(item.osFamily), color: AppTokens.brand),
              Text(
                item.title,
                style: const TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              StatusPill(text: item.osLabel, tone: PillTone.blue),
              if (item.nasId != null)
                StatusPill(text: 'NAS #${item.nasId}', tone: PillTone.neutral),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _InfoChip(icon: Icons.memory, label: item.deviceLabel),
              _InfoChip(
                icon: Icons.lan_outlined,
                label: item.ipAddress.isEmpty ? 'IP غير معروف' : item.ipAddress,
              ),
              _InfoChip(icon: Icons.badge_outlined, label: item.mac),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            [
              if (item.firstSeenAt.isNotEmpty) 'أول ظهور: ${item.firstSeenAt}',
              if (item.lastSeenAt.isNotEmpty) 'آخر ظهور: ${item.lastSeenAt}',
              if (item.dhcpClassId.isNotEmpty) 'DHCP: ${item.dhcpClassId}',
            ].join(' · '),
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          const SizedBox(height: AppTokens.s8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: item.mac));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ MAC')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('نسخ MAC'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTokens.textMuted),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTokens.textSecondary)),
        ],
      ),
    );
  }
}

IconData _osIcon(String value) {
  return switch (value.toLowerCase()) {
    'android' => Icons.android,
    'ios' || 'macos' => Icons.phone_iphone,
    'windows' => Icons.desktop_windows_outlined,
    'linux' => Icons.terminal,
    _ => Icons.devices_other_outlined,
  };
}

const _osOptions = [
  _OsOption('all', 'كل الأنظمة'),
  _OsOption('android', 'Android'),
  _OsOption('ios', 'iOS'),
  _OsOption('windows', 'Windows'),
  _OsOption('macos', 'macOS'),
  _OsOption('linux', 'Linux'),
  _OsOption('other', 'أخرى'),
];

class _OsOption {
  const _OsOption(this.value, this.label);
  final String value;
  final String label;
}
