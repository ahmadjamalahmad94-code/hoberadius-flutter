import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/auth/route_permissions.dart';
import '../../../core/format/bidi.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../provider_grants/application/provider_grants_provider.dart';
import '../../provider_grants/presentation/limit_usage_banner.dart';
import '../data/nas_repository.dart';
import '../domain/nas_model.dart';

final nasListProvider = FutureProvider.autoDispose<List<NasDevice>>((ref) {
  return ref.watch(nasRepositoryProvider).list();
});

class NasListScreen extends ConsumerStatefulWidget {
  const NasListScreen({super.key});

  @override
  ConsumerState<NasListScreen> createState() => _NasListScreenState();
}

class _NasListScreenState extends ConsumerState<NasListScreen> {
  final Set<int> _testing = {};

  Future<void> _runTest(NasDevice d) async {
    if (d.id == null || _testing.contains(d.id)) return;
    setState(() => _testing.add(d.id!));
    try {
      final r = await ref.read(nasRepositoryProvider).test(d.id!);
      ref.invalidate(nasListProvider);
      if (!mounted) return;
      final color = r.ok ? AppTokens.green : AppTokens.red;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Text(
            r.ok
                ? 'نجح: ${ltrIsolate('${r.ip}:${r.port}')} في ${r.ms} مللي ثانية'
                : visibleErrorMessage(
                    r.message,
                    fallback: 'فشل اختبار الاتصال بالجهاز.',
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _testing.remove(d.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(nasListProvider);
    final newDenied = routeDenial(ref.watch(permissionsProvider), '/nas/new');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'أجهزة الشبكة',
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(nasListProvider),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.add,
              label: 'جهاز جديد',
              primary: true,
              // blocked at the provider's NAS cap (the limit banner below
              // explains why) — same rule the guarded create button applied.
              onPressed:
                  ((ref.watch(grantLimitProvider('nas'))?.atCap ?? false) ||
                          newDenied != null)
                      ? null
                      : () => context.goNamed('nas-new'),
              tooltip: newDenied,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const LimitUsageBanner(serviceKey: 'nas'),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب القائمة',
            subtitle: visibleErrorMessage(e),
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(nasListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.router_outlined,
                title: 'لا توجد أجهزة بعد',
                subtitle: 'سجّل أول راوتر/AP للبدء بالعمليات.',
                action: newDenied != null
                    ? null
                    : ElevatedButton.icon(
                        onPressed: () => context.goNamed('nas-new'),
                        icon: const Icon(Icons.add),
                        label: const Text('جهاز جديد'),
                      ),
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: _NasTable(
                items: items,
                testing: _testing,
                onTest: _runTest,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NasTable extends StatelessWidget {
  const _NasTable({
    required this.items,
    required this.testing,
    required this.onTest,
  });
  final List<NasDevice> items;
  final Set<int> testing;
  final Future<void> Function(NasDevice) onTest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _NasRow(
            device: items[i],
            testing: items[i].id != null && testing.contains(items[i].id),
            onTest: () => onTest(items[i]),
          ),
        ],
      ],
    );
  }
}

/// One device: name + a single status pill on line 1, «IP · vendor» on
/// line 2, a short «فحص» time on line 3, and the test button at the end.
class _NasRow extends ConsumerWidget {
  const _NasRow({
    required this.device,
    required this.testing,
    required this.onTest,
  });
  final NasDevice device;
  final bool testing;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = device;
    // The row opens the edit form — only when nas.edit (and the network
    // section) would accept its save.
    final canEdit =
        routeAllowed(ref.watch(permissionsProvider), '/nas/${d.id ?? 0}');
    final p = AppPalette.of(context);
    final df = DateFormat('MM-dd HH:mm');
    final pulseOk = d.lastCheckStatus == 'reachable' && d.enabled;
    final (pillText, pillTone) = d.enabled
        ? (_nasCheckStatusLabel(d.lastCheckStatus), _nasCheckTone(d))
        : ('معطّل', PillTone.neutral);
    const muted = TextStyle(color: AppTokens.textMuted, fontSize: 12.5);
    return InkWell(
      onTap: d.id == null || !canEdit
          ? null
          : () =>
              context.goNamed('nas-edit', pathParameters: {'id': '${d.id}'}),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s4,
          AppTokens.s8 + 2,
          AppTokens.s12,
          AppTokens.s8 + 2,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: p.brandSoft,
                  child: Icon(
                    d.enabled ? Icons.router : Icons.router_outlined,
                    color: d.enabled ? p.brand : AppTokens.textMuted,
                    size: 20,
                  ),
                ),
                if (pulseOk)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: p.successStrong,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.card, width: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.name.isEmpty ? ltrIsolate(d.address) : d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTokens.sidebarBg,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      StatusPill(text: pillText, tone: pillTone),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // IPs stay one LTR run: «::ffff:192.0.2.171» rendered
                    // as «ffff:192.0.2.171::» in RTL (R07 N10).
                    '${ltrIsolate(d.address)} · ${_nasVendorLabel(d.vendor)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  if (d.lastCheckAt != null)
                    Text(
                      'فحص: ${df.format(d.lastCheckAt!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s4),
            if (testing)
              const SizedBox(
                width: 40,
                height: 40,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'اختبار الاتصال',
                onPressed: onTest,
                icon: const Icon(Icons.network_check, color: AppTokens.brand),
              ),
          ],
        ),
      ),
    );
  }
}

/// online green · timeout amber · unreachable/failed red · never checked grey.
PillTone _nasCheckTone(NasDevice d) =>
    switch (d.lastCheckStatus.toLowerCase()) {
      'reachable' => PillTone.green,
      'timeout' => PillTone.amber,
      'unreachable' || 'failed' => PillTone.red,
      '' => PillTone.neutral,
      _ => PillTone.amber,
    };

String _nasVendorLabel(String value) {
  final v = value.toLowerCase();
  if (v == 'mikrotik') return 'ميكروتك';
  if (v == 'cisco') return 'Cisco';
  if (v == 'huawei') return 'Huawei';
  if (v == 'ubiquiti') return 'Ubiquiti';
  if (v == 'other') return 'أخرى';
  return value.isEmpty ? 'غير محدد' : value;
}

String _nasCheckStatusLabel(String value) {
  final v = value.toLowerCase();
  return switch (v) {
    '' => 'لم يُفحص',
    'reachable' => 'متصل',
    'timeout' => 'انتهت المهلة',
    'unreachable' => 'غير متاح',
    'failed' => 'فشل الفحص',
    _ => value.trim().isEmpty ? 'غير محدد' : 'حالة غير معروفة',
  };
}
