import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: color,
        content: Text(
          r.ok
              ? 'نجح: ${r.ip}:${r.port} في ${r.ms} ms'
              : '${r.status}: ${r.message}',
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الاختبار: $e')),
      );
    } finally {
      if (mounted) setState(() => _testing.remove(d.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(nasListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'أجهزة الشبكة',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(nasListProvider),
            ),
            const SizedBox(width: AppTokens.s4),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('nas-new'),
              icon: const Icon(Icons.add),
              label: const Text('جهاز جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب القائمة',
            subtitle: '$e',
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
                action: ElevatedButton.icon(
                  onPressed: () => context.goNamed('nas-new'),
                  icon: const Icon(Icons.add),
                  label: const Text('جهاز جديد'),
                ),
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: _NasTable(items: items, testing: _testing, onTest: _runTest),
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
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final d = items[i];
        final tone = switch (d.lastCheckStatus) {
          'reachable' => PillTone.green,
          'timeout' || 'unreachable' => PillTone.red,
          '' => PillTone.neutral,
          _ => PillTone.orange,
        };
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTokens.cyan100,
            child: Icon(
              d.enabled ? Icons.router : Icons.router_outlined,
              color: AppTokens.cyan500,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  d.name.isEmpty ? d.address : d.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!d.enabled)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: StatusPill(text: 'معطّل', tone: PillTone.neutral),
                ),
            ],
          ),
          subtitle: Text(
            [
              d.address,
              d.vendor,
              if (d.lastCheckAt != null) 'آخر فحص: ${df.format(d.lastCheckAt!)}',
            ].join(' • '),
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(
                text: d.lastCheckStatus.isEmpty ? '—' : d.lastCheckStatus,
                tone: tone,
              ),
              const SizedBox(width: AppTokens.s4),
              if (d.id != null && testing.contains(d.id))
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: 'اختبار الاتصال',
                  onPressed: () => onTest(d),
                  icon: const Icon(Icons.network_check),
                ),
            ],
          ),
          onTap: d.id == null
              ? null
              : () => ctx.goNamed('nas-edit', pathParameters: {'id': '${d.id}'}),
        );
      },
    );
  }
}
