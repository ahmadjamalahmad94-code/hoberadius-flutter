import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class NasListScreen extends ConsumerWidget {
  const NasListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox.shrink(),
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
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.router_outlined,
                title: 'لا توجد أجهزة بعد',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: _NasTable(items: items, ref: ref),
            );
          },
        ),
      ],
    );
  }
}

class _NasTable extends StatelessWidget {
  const _NasTable({required this.items, required this.ref});
  final List<NasDevice> items;
  final WidgetRef ref;

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
        final ok = d.lastCheckStatus == 'ok';
        final fail = d.lastCheckStatus == 'fail' || d.lastCheckStatus == 'timeout';
        final tone = ok
            ? PillTone.green
            : fail
                ? PillTone.red
                : PillTone.neutral;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTokens.cyan100,
            child: const Icon(Icons.router, color: AppTokens.cyan500),
          ),
          title: Text(
            d.name.isEmpty ? d.ipAddress : d.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              d.ipAddress,
              d.nasType,
              if (d.lastCheckAt != null) 'آخر فحص: ${df.format(d.lastCheckAt!)}',
              if (d.lastCheckMs != null) '${d.lastCheckMs} ms',
            ].join(' • '),
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(
                text: d.lastCheckStatus ?? '—',
                tone: tone,
              ),
              const SizedBox(width: AppTokens.s8),
              IconButton(
                tooltip: 'اختبار الاتصال',
                onPressed: () async {
                  if (d.id == null) return;
                  try {
                    final r = await ref.read(nasRepositoryProvider).test(d.id!);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(r.ok
                            ? 'نجح الاتصال — ${r.ms ?? 0} ms'
                            : 'فشل: ${r.message ?? r.status ?? "?"}'),
                      ));
                    }
                    ref.invalidate(nasListProvider);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('تعذّر الاختبار: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.network_check),
              ),
            ],
          ),
        );
      },
    );
  }
}
