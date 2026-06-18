import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_skeleton_loader.dart';
import '../application/cards_list_controller.dart';
import '../application/cards_list_providers.dart';
import 'widgets/cards_batches_table.dart';
import 'widgets/cards_list_header.dart';
import 'widgets/cards_list_pagination.dart';
import 'widgets/cards_list_toolbar.dart';
import 'widgets/cards_list_totals.dart';

/// Card-batches operations room. Composes header + toolbar + totals
/// + table + pagination; all state lives in
/// [cards_list_providers.dart] and async actions in
/// [cardsListControllerProvider].
class CardsListScreen extends ConsumerWidget {
  const CardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(batchesOperationsProvider);
    final filters = ref.watch(batchOpsFiltersProvider);
    final selected = ref.watch(selectedBatchIdsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardsListHeader(
          onRefresh: () {
            ref.invalidate(batchesOperationsProvider);
            ref.invalidate(batchesListProvider);
          },
        ),
        const SizedBox(height: AppTokens.s16),
        CardsListToolbar(
          selectedCount: selected.length,
          filters: filters,
          onFiltersChanged: (next) {
            ref.read(selectedBatchIdsProvider.notifier).state = <int>{};
            ref.read(batchOpsFiltersProvider.notifier).state = next;
          },
          onExportCsv: () => _runExport(context, ref, _Export.csv),
          onExportXlsx: () => _runExport(context, ref, _Export.xlsx),
          onExportPdf: () => _runExport(context, ref, _Export.pdf),
          onBulkAction: (action) => _runBulkAction(context, ref, action),
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HubSkeletonLoader.tiles(count: 4),
                const SizedBox(height: AppTokens.s16),
                AppCard(child: HubSkeletonLoader.list()),
              ],
            ),
          ),
          error: (e, _) => HubErrorState(
            title: 'تعذّر جلب حزم البطاقات',
            subtitle: visibleErrorMessage(e),
            showToastOnce: true,
            onRetry: () => ref.invalidate(batchesOperationsProvider),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return EmptyState(
                icon: Icons.credit_card_off_outlined,
                title: 'لا توجد حزم مطابقة',
                subtitle: 'جرّب تغيير البحث أو الفلتر، أو أنشئ حزمة جديدة.',
                action: ElevatedButton.icon(
                  onPressed: () => context.goNamed('card-batch-new'),
                  icon: const Icon(Icons.add),
                  label: const Text('حزمة جديدة'),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CardsListTotals(totals: page.totals),
                const SizedBox(height: AppTokens.s16),
                CardsBatchesTable(page: page),
                const SizedBox(height: AppTokens.s12),
                CardsListPagination(page: page, filters: filters),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _runExport(
    BuildContext context,
    WidgetRef ref,
    _Export which,
  ) async {
    final controller = ref.read(cardsListControllerProvider);
    final result = switch (which) {
      _Export.csv => await controller.exportCsv(),
      _Export.xlsx => await controller.exportXlsx(),
      _Export.pdf => await controller.exportPdf(),
    };
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? result.savedAs ?? '')),
    );
  }

  Future<void> _runBulkAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final ids = ref.read(selectedBatchIdsProvider).toList()..sort();
    if (ids.isEmpty) return;
    final destructive = action == 'archive';
    final label = switch (action) {
      'archive' => 'أرشفة',
      'restore' => 'استعادة',
      _ => 'تحديث',
    };
    if (action != 'refresh') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('$label الحزم المحددة'),
          content: Text(
            destructive
                ? 'سيتم نقل ${ids.length} حزمة إلى الأرشيف بدون حذف البطاقات.'
                : 'سيتم تنفيذ الإجراء على ${ids.length} حزمة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    final result =
        await ref.read(cardsListControllerProvider).runBulk(action);
    if (!context.mounted) return;
    final text = result.error ?? result.message;
    if (text != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }
}

enum _Export { csv, xlsx, pdf }
