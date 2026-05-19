import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/plans_repository.dart';
import '../domain/plan_model.dart';

final plansListProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

class PlansListScreen extends ConsumerWidget {
  const PlansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(plansListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'الباقات',
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
                icon: Icons.workspace_premium_outlined,
                title: 'لا توجد باقات بعد',
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisSpacing: AppTokens.s16,
                crossAxisSpacing: AppTokens.s16,
                childAspectRatio: 1.6,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _PlanCard(plan: items[i]),
            );
          },
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final Plan plan;

  String _planTypeLabel(String t) => switch (t) {
        'time' => 'وقت',
        'quota' => 'حصة',
        'mixed' => 'وقت وحصة',
        'unlimited' => 'غير محدود',
        _ => t,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined,
                      color: AppTokens.cyan500),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.navy900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusPill(
                    text: _planTypeLabel(plan.planType),
                    tone: PillTone.cyan,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              if (plan.downloadKbps != null || plan.uploadKbps != null)
                Row(
                  children: [
                    const Icon(Icons.speed, size: 16, color: AppTokens.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'تنزيل ${plan.downloadKbps ?? 0} • رفع ${plan.uploadKbps ?? 0} kbps',
                      style: const TextStyle(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
              if (plan.validityDays != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: AppTokens.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'صلاحية: ${plan.validityDays} يوم',
                      style: const TextStyle(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  if (plan.priceMonthly > 0)
                    Text(
                      '${plan.priceMonthly.toStringAsFixed(2)} / شهر',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.navy800,
                      ),
                    ),
                  const Spacer(),
                  if (plan.autoRenew)
                    const StatusPill(text: 'متجدّد', tone: PillTone.purple),
                ],
              ),
            ],
          ),
        ),
    );
  }
}
