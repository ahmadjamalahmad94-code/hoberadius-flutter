import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/lifecycle_providers.dart';
import '../data/lifecycle_repository.dart';
import 'widgets/lifecycle_create_policy_card.dart';
import 'widgets/lifecycle_policy_card.dart';
import 'widgets/lifecycle_preview_panel.dart';

class LifecycleScreen extends ConsumerStatefulWidget {
  const LifecycleScreen({super.key});

  @override
  ConsumerState<LifecycleScreen> createState() => _LifecycleScreenState();
}

class _LifecycleScreenState extends ConsumerState<LifecycleScreen> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final policies = ref.watch(lifecyclePoliciesProvider);
    final preview = ref.watch(lifecyclePreviewProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'الأرشفة التلقائية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTokens.brand),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'هذه الصفحة تنقل الكروت والمشتركين المنتهين إلى سلة المحذوفات فقط. لا يوجد حذف نهائي ولا فصل RADIUS في هذه الشريحة.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        preview.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل معاينة الأرشفة',
            subtitle: visibleErrorMessage(e),
          ),
          data: (data) => LifecyclePreviewPanel(
            preview: data,
            running: _running,
            onRun: _runNow,
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        LifecycleCreatePolicyCard(onCreated: _refresh),
        const SizedBox(height: AppTokens.s12),
        policies.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل السياسات',
            subtitle: visibleErrorMessage(e),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.rule_folder_outlined,
                title: 'لا توجد سياسات أرشفة',
                subtitle: 'أضف قاعدة للكروت المنتهية أو المشتركين المنتهين.',
              );
            }
            return Column(
              children: [
                for (final policy in items) ...[
                  LifecyclePolicyCard(policy: policy, onChanged: _refresh),
                  const SizedBox(height: AppTokens.s8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _refresh() {
    ref.invalidate(lifecyclePoliciesProvider);
    ref.invalidate(lifecyclePreviewProvider);
  }

  Future<void> _runNow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تشغيل الأرشفة الآن'),
        content: const Text(
          'سيتم نقل العناصر المؤهلة إلى سلة المحذوفات فقط. العدد الأصلي للحزم لن يتغير، ولا يتم تنفيذ أي RADIUS أو CoA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تشغيل'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _running = true);
    try {
      final result = await ref.read(lifecycleRepositoryProvider).run();
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت أرشفة ${result.changed} عنصر، تخطي ${result.skipped}، فشل ${result.failed}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}
