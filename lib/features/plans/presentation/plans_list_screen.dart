import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../provider_grants/presentation/limit_usage_banner.dart';
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
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(plansListProvider),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        const LimitUsageBanner(serviceKey: 'profiles'),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب الباقات',
            subtitle: visibleErrorMessage(e),
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(plansListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: 'لا توجد باقات بعد',
                subtitle: 'أضف الباقات من لوحة الويب لتظهر هنا.',
              );
            }
            return _PlanGrid(plans: items);
          },
        ),
      ],
    );
  }
}

/// Plan cards whose height follows their content: one column on phones,
/// equal-width columns on wide screens (a row takes its tallest card's
/// height) — no fixed aspect ratio, so no dead space under short cards.
class _PlanGrid extends StatelessWidget {
  const _PlanGrid({required this.plans});
  final List<Plan> plans;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / 360).floor().clamp(1, 4);
        final rows = <Widget>[];
        for (var i = 0; i < plans.length; i += cols) {
          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: i + j < plans.length
                      ? _PlanCard(plan: plans[i + j])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          );
          rows.add(
            cols == 1 ? _PlanCard(plan: plans[i]) : IntrinsicHeight(child: row),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppTokens.s8),
              rows[i],
            ],
          ],
        );
      },
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
        _ => t.trim().isEmpty ? 'غير محدد' : 'نوع غير معروف',
      };

  String _serviceTypeLabel(String value) {
    final v = value.trim().toLowerCase();
    return switch (v) {
      'hotspot' => 'هوتسبوت',
      'pppoe' || 'broadband' => 'برودباند',
      'cards' || 'card' => 'كروت',
      '' => 'غير محدد',
      _ => 'خدمة غير معروفة',
    };
  }

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
    final facts = <(IconData, String)>[
      if (plan.speedDownKbps > 0 || plan.speedUpKbps > 0)
        (
          Icons.speed,
          'تنزيل ${plan.speedDownKbps} • رفع ${plan.speedUpKbps} kbps',
        ),
      if (plan.validityDays > 0)
        (Icons.timer_outlined, 'صلاحية: ${plan.validityDays} يوم'),
      if (plan.quotaTotalMb > 0)
        (Icons.data_usage, 'حصة: ${plan.quotaTotalMb} MB'),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.r14),
        onTap: plan.id == null
            ? null
            : () => context.goNamed(
                  'plan-edit',
                  pathParameters: {'id': '${plan.id}'},
                ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.workspace_premium_outlined,
                      color: accent,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                  ),
                  if (plan.price > 0) ...[
                    const SizedBox(width: AppTokens.s8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${plan.price.toStringAsFixed(2)} ${plan.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (!plan.enabled)
                    const StatusPill(text: 'معطّل', tone: PillTone.red),
                  StatusPill(
                    text: _typeLabel(plan.planType),
                    tone: PillTone.brand,
                  ),
                  StatusPill(
                    text: _serviceTypeLabel(plan.serviceType),
                    tone: PillTone.blue,
                  ),
                  if (plan.autoRenew)
                    const StatusPill(text: 'متجدّد', tone: PillTone.green),
                ],
              ),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s8),
                Wrap(
                  spacing: AppTokens.s12,
                  runSpacing: 4,
                  children: [
                    for (final f in facts)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(f.$1, size: 14, color: AppTokens.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            f.$2,
                            style: const TextStyle(
                              color: AppTokens.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
