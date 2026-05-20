import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';

final batchesListProvider = FutureProvider.autoDispose<List<CardBatch>>((ref) {
  return ref.watch(cardsRepositoryProvider).listBatches();
});

class CardsListScreen extends ConsumerWidget {
  const CardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(batchesListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'الكروت',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(batchesListProvider),
            ),
            const SizedBox(width: AppTokens.s4),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('card-batch-new'),
              icon: const Icon(Icons.add),
              label: const Text('دفعة جديدة'),
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
            title: 'تعذّر جلب الدفعات',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(batchesListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.credit_card_outlined,
                title: 'لا توجد دفعات بعد',
                subtitle: 'ابدأ بإنشاء أول دفعة كروت.',
                action: ElevatedButton.icon(
                  onPressed: () => context.goNamed('card-batch-new'),
                  icon: const Icon(Icons.add),
                  label: const Text('دفعة جديدة'),
                ),
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: _BatchesTable(items: items),
            );
          },
        ),
      ],
    );
  }
}

class _BatchesTable extends StatelessWidget {
  const _BatchesTable({required this.items});
  final List<CardBatch> items;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd HH:mm');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final b = items[i];
        final tone = b.status == 'active'
            ? PillTone.green
            : b.status == 'exhausted'
                ? PillTone.orange
                : b.status == 'revoked'
                    ? PillTone.red
                    : PillTone.neutral;
        final usedPct = b.count == 0 ? 0.0 : (b.used / b.count).clamp(0.0, 1.0);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          leading: const CircleAvatar(
            backgroundColor: AppTokens.cyan100,
            child: Icon(Icons.credit_card, color: AppTokens.cyan500),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  b.batchCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusPill(text: _statusLabel(b.status), tone: tone),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                [
                  if (b.packageName.isNotEmpty) b.packageName,
                  'العدد: ${b.count}',
                  'المُستخدَم: ${b.used}',
                  'المتاح: ${b.available}',
                  if (b.createdAt != null) df.format(b.createdAt!),
                ].join(' • '),
                style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
              ),
              if (b.count > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: usedPct,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEFF2F7),
                    valueColor: AlwaysStoppedAnimation(
                      usedPct >= 0.9 ? AppTokens.red : AppTokens.cyan500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_left, color: AppTokens.textMuted),
          onTap: b.id == null
              ? null
              : () => ctx.goNamed(
                    'card-batch-detail',
                    pathParameters: {'id': '${b.id}'},
                  ),
        );
      },
    );
  }

  String _statusLabel(String s) => switch (s) {
        'active' => 'نشِط',
        'exhausted' => 'منتهٍ',
        'revoked' => 'مُلغى',
        _ => s,
      };
}
