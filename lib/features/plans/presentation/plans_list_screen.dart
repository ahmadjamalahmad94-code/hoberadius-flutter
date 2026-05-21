import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
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
        PageHeader(
          title: 'الباقات',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(plansListProvider),
            ),
            ElevatedButton.icon(
              onPressed: () => context.goNamed('plan-new'),
              icon: const Icon(Icons.add),
              label: const Text('باقة جديدة'),
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
            title: 'تعذّر جلب الباقات',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(plansListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: 'لا توجد باقات بعد',
                subtitle: 'ابدأ بإضافة أول باقة لتظهر هنا.',
                action: ElevatedButton.icon(
                  onPressed: () => context.goNamed('plan-new'),
                  icon: const Icon(Icons.add),
                  label: const Text('باقة جديدة'),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisSpacing: AppTokens.s16,
                crossAxisSpacing: AppTokens.s16,
                childAspectRatio: 1.55,
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

  String _typeLabel(String t) => switch (t) {
        'time' => 'وقت',
        'quota' => 'حصة',
        'hybrid' => 'وقت وحصة',
        'unlimited' => 'غير محدود',
        'recurring' => 'متجدّد',
        _ => t,
      };

  Color _typeTone(String t) => switch (t) {
        'time' => AppTokens.brand,
        'quota' => AppTokens.brand,
        'hybrid' => AppTokens.sidebarBgElev2,
        'unlimited' => AppTokens.green,
        'recurring' => AppTokens.amber,
        _ => AppTokens.brand,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _typeTone(plan.planType);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r14),
        onTap: plan.id == null
            ? null
            : () => context.goNamed(
                  'plan-edit',
                  pathParameters: {'id': '${plan.id}'},
                ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!plan.enabled)
                    const StatusPill(text: 'معطّل', tone: PillTone.red),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusPill(
                    text: _typeLabel(plan.planType),
                    tone: PillTone.cyan,
                  ),
                  StatusPill(text: plan.serviceType, tone: PillTone.navy),
                  if (plan.autoRenew)
                    const StatusPill(text: 'متجدّد', tone: PillTone.purple),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              if (plan.speedDownKbps > 0 || plan.speedUpKbps > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.speed,
                      size: 14,
                      color: AppTokens.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'تنزيل ${plan.speedDownKbps} • رفع ${plan.speedUpKbps} kbps',
                        style: const TextStyle(
                          color: AppTokens.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (plan.validityDays > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppTokens.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'صلاحية: ${plan.validityDays} يوم',
                      style: const TextStyle(
                        color: AppTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              if (plan.quotaTotalMb > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.data_usage,
                      size: 14,
                      color: AppTokens.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'حصة: ${plan.quotaTotalMb} MB',
                      style: const TextStyle(
                        color: AppTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (plan.price > 0)
                Text(
                  '${plan.price.toStringAsFixed(2)} ${plan.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.sidebarBgElev1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
