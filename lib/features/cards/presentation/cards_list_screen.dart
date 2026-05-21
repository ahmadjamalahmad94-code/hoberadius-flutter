import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';

class _BatchOpsFilters {
  const _BatchOpsFilters({
    this.query = '',
    this.status = '',
    this.page = 1,
    this.perPage = 25,
  });

  final String query;
  final String status;
  final int page;
  final int perPage;

  _BatchOpsFilters copyWith({
    String? query,
    String? status,
    int? page,
    int? perPage,
  }) =>
      _BatchOpsFilters(
        query: query ?? this.query,
        status: status ?? this.status,
        page: page ?? this.page,
        perPage: perPage ?? this.perPage,
      );
}

final _batchOpsFiltersProvider = StateProvider.autoDispose<_BatchOpsFilters>(
  (_) => const _BatchOpsFilters(),
);

final _selectedBatchIdsProvider =
    StateProvider.autoDispose<Set<int>>((_) => <int>{});

final batchesOperationsProvider =
    FutureProvider.autoDispose<CardBatchOperationsPage>((ref) {
  final filters = ref.watch(_batchOpsFiltersProvider);
  return ref.watch(cardsRepositoryProvider).listBatchOperations(
        query: filters.query,
        status: filters.status,
        page: filters.page,
        perPage: filters.perPage,
      );
});

final batchesListProvider = FutureProvider.autoDispose<List<CardBatch>>((ref) {
  return ref.watch(cardsRepositoryProvider).listBatchOperations().then(
        (page) => page.items,
      );
});

class CardsListScreen extends ConsumerWidget {
  const CardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(batchesOperationsProvider);
    final filters = ref.watch(_batchOpsFiltersProvider);
    final selected = ref.watch(_selectedBatchIdsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          onRefresh: () {
            ref.invalidate(batchesOperationsProvider);
            ref.invalidate(batchesListProvider);
          },
        ),
        const SizedBox(height: AppTokens.s16),
        _Toolbar(
          selectedCount: selected.length,
          filters: filters,
          onFiltersChanged: (next) {
            ref.read(_selectedBatchIdsProvider.notifier).state = <int>{};
            ref.read(_batchOpsFiltersProvider.notifier).state = next;
          },
          onExportCsv: () => _exportCsv(context, ref),
          onExportXlsx: () => _exportXlsx(context, ref),
          onExportPdf: () => _exportPdf(context, ref),
          onBulkAction: (action) => _runBulkAction(context, ref, action),
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب حزم البطاقات',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(batchesOperationsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
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
                _TotalsPanel(totals: page.totals),
                const SizedBox(height: AppTokens.s16),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: _BatchesOperationsTable(page: page),
                ),
                const SizedBox(height: AppTokens.s12),
                _Pagination(page: page, filters: filters),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(_batchOpsFiltersProvider);
    try {
      final bytes = await ref.read(cardsRepositoryProvider).exportBatchesCsv(
            query: filters.query,
            status: filters.status,
          );
      await FileSaver.instance.saveFile(
        name: 'card-batches',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل ملف الحزم المعروضة')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر التصدير: $e')),
      );
    }
  }

  Future<void> _exportXlsx(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(_batchOpsFiltersProvider);
    try {
      final bytes = await ref.read(cardsRepositoryProvider).exportBatchesXlsx(
            query: filters.query,
            status: filters.status,
          );
      await FileSaver.instance.saveFile(
        name: 'card-batches',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل ملف Excel للحزم المعروضة')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تصدير Excel: $e')),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(_batchOpsFiltersProvider);
    try {
      final bytes = await ref.read(cardsRepositoryProvider).exportBatchesPdf(
            query: filters.query,
            status: filters.status,
          );
      await FileSaver.instance.saveFile(
        name: 'card-batches',
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل ملف PDF للحزم المعروضة')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تصدير PDF: $e')),
      );
    }
  }

  Future<void> _runBulkAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final ids = ref.read(_selectedBatchIdsProvider).toList()..sort();
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
    try {
      final result = await ref.read(cardsRepositoryProvider).bulkBatches(
            action: action,
            batchIds: ids,
            reason: action == 'archive' ? 'أرشفة من تطبيق الإدارة' : '',
          );
      ref.read(_selectedBatchIdsProvider.notifier).state = <int>{};
      ref.invalidate(batchesOperationsProvider);
      ref.invalidate(batchesListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'refresh'
                ? 'تم تحديث العرض'
                : 'تم تنفيذ $label على ${result.changed} من ${result.requested} حزمة',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تنفيذ الإجراء: $e')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'مركز عمليات حزم البطاقات',
      subtitle: 'فلاتر، إحصائيات، أرشفة آمنة، وتصدير ملف من الخادم الحقيقي.',
      actions: [
        IconButton(
          tooltip: 'تحديث',
          icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
          onPressed: onRefresh,
        ),
        OutlinedButton.icon(
          onPressed: () => context.goNamed('card-checker'),
          icon: const Icon(Icons.manage_search_outlined),
          label: const Text('فحص بطاقة'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.goNamed('card-batch-import'),
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('استيراد ملف'),
        ),
        ElevatedButton.icon(
          onPressed: () => context.goNamed('card-batch-new'),
          icon: const Icon(Icons.add),
          label: const Text('حزمة جديدة'),
        ),
      ],
    );
  }
}

class _Toolbar extends ConsumerStatefulWidget {
  const _Toolbar({
    required this.filters,
    required this.selectedCount,
    required this.onFiltersChanged,
    required this.onExportCsv,
    required this.onExportXlsx,
    required this.onExportPdf,
    required this.onBulkAction,
  });

  final _BatchOpsFilters filters;
  final int selectedCount;
  final ValueChanged<_BatchOpsFilters> onFiltersChanged;
  final VoidCallback onExportCsv;
  final VoidCallback onExportXlsx;
  final VoidCallback onExportPdf;
  final ValueChanged<String> onBulkAction;

  @override
  ConsumerState<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends ConsumerState<_Toolbar> {
  late final TextEditingController _queryController;

  static const _statuses = <String, String>{
    '': 'كل الحزم النشطة',
    'all': 'كل الحزم',
    'active': 'نشطة',
    'available': 'فيها متاح',
    'used': 'مستخدمة',
    'expired': 'منتهية',
    'exhausted': 'مستهلكة',
    'archived': 'مؤرشفة',
  };

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.filters.query);
  }

  @override
  void didUpdateWidget(covariant _Toolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filters.query != _queryController.text) {
      _queryController.text = widget.filters.query;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final controlWidth = compact ? constraints.maxWidth : 280.0;
          final statusWidth = compact ? constraints.maxWidth : 190.0;
          return Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: controlWidth,
                child: TextField(
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'بحث',
                    hintText: 'اسم الحزمة، العرض، المدير...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _applySearch(),
                ),
              ),
              SizedBox(
                width: statusWidth,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.filters.status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: [
                    for (final item in _statuses.entries)
                      DropdownMenuItem(
                        value: item.key,
                        child: Text(item.value),
                      ),
                  ],
                  onChanged: (value) => widget.onFiltersChanged(
                    widget.filters.copyWith(status: value ?? '', page: 1),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _applySearch,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('تطبيق'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onExportCsv,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('تصدير ملف'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onExportXlsx,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Excel'),
              ),
              OutlinedButton.icon(
                onPressed: widget.onExportPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
              if (widget.selectedCount > 0) ...[
                const SizedBox(width: AppTokens.s8),
                Text(
                  'محدد: ${widget.selectedCount}',
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => widget.onBulkAction('archive'),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('أرشفة'),
                ),
                OutlinedButton.icon(
                  onPressed: () => widget.onBulkAction('restore'),
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('استعادة'),
                ),
                OutlinedButton.icon(
                  onPressed: () => widget.onBulkAction('refresh'),
                  icon: const Icon(Icons.sync),
                  label: const Text('تحديث'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _applySearch() {
    widget.onFiltersChanged(
      widget.filters.copyWith(query: _queryController.text.trim(), page: 1),
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({required this.totals});
  final CardBatchOperationsTotals totals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 640
                ? 3
                : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: AppTokens.s12,
          mainAxisSpacing: AppTokens.s12,
          childAspectRatio: constraints.maxWidth < 520 ? 2.05 : 2.8,
          children: [
            _StatCard(
              icon: Icons.inventory_2_outlined,
              label: 'الحزم المعروضة',
              value: '${totals.batchCount}',
            ),
            _StatCard(
              icon: Icons.today_outlined,
              label: 'بطاقات اليوم',
              value: '${totals.usedToday}',
              footnote: _money(totals.valueToday),
            ),
            _StatCard(
              icon: Icons.calendar_month_outlined,
              label: 'بطاقات الشهر',
              value: '${totals.usedMonth}',
              footnote: _money(totals.valueMonth),
            ),
            _StatCard(
              icon: Icons.payments_outlined,
              label: 'قيمة تقديرية',
              value: _money(totals.configuredValue),
              footnote: 'ليست تقريرًا ماليًا',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.footnote = '',
  });

  final IconData icon;
  final String label;
  final String value;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 145;
          final iconWidget = CircleAvatar(
            radius: compact ? 18 : 20,
            backgroundColor: AppTokens.brandSoft,
            child:
                Icon(icon, color: AppTokens.brand, size: compact ? 18 : 20),
          );
          final textWidget = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              if (footnote.isNotEmpty)
                Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconWidget,
                const SizedBox(height: AppTokens.s8),
                textWidget,
              ],
            );
          }
          return Row(
            children: [
              iconWidget,
              const SizedBox(width: AppTokens.s12),
              Expanded(child: textWidget),
            ],
          );
        },
      ),
    );
  }
}

class _BatchesOperationsTable extends ConsumerWidget {
  const _BatchesOperationsTable({required this.page});
  final CardBatchOperationsPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedBatchIdsProvider);
    final ids = page.items.map((item) => item.id).whereType<int>().toSet();
    final allSelected = ids.isNotEmpty && ids.difference(selected).isEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTokens.surfaceMuted),
        columns: [
          DataColumn(
            label: Checkbox(
              value: allSelected,
              onChanged: (_) {
                ref.read(_selectedBatchIdsProvider.notifier).state =
                    allSelected ? <int>{} : ids;
              },
            ),
          ),
          const DataColumn(label: Text('الحزمة')),
          const DataColumn(label: Text('الحالة')),
          const DataColumn(label: Text('الأعداد')),
          const DataColumn(label: Text('العرض/السرعة')),
          const DataColumn(label: Text('الموزع')),
          const DataColumn(label: Text('القيمة التقديرية')),
          const DataColumn(label: Text('آخر بيانات')),
          const DataColumn(label: Text('إجراءات')),
        ],
        rows: [
          for (final batch in page.items)
            DataRow(
              selected: batch.id != null && selected.contains(batch.id),
              cells: [
                DataCell(
                  Checkbox(
                    value: batch.id != null && selected.contains(batch.id),
                    onChanged: batch.id == null
                        ? null
                        : (_) {
                            final next = {...selected};
                            if (next.contains(batch.id)) {
                              next.remove(batch.id);
                            } else {
                              next.add(batch.id!);
                            }
                            ref.read(_selectedBatchIdsProvider.notifier).state =
                                next;
                          },
                  ),
                ),
                DataCell(_BatchName(batch: batch)),
                DataCell(
                  StatusPill(
                    text: _statusLabel(batch.displayStatus),
                    tone: _statusTone(batch.displayStatus),
                  ),
                ),
                DataCell(_Counts(batch: batch)),
                DataCell(_PlanAndSpeed(batch: batch)),
                DataCell(Text(_distributorLabel(batch))),
                DataCell(Text(_money(batch.estimatedValue))),
                DataCell(_Activity(batch: batch)),
                DataCell(_RowActions(batch: batch)),
              ],
            ),
        ],
      ),
    );
  }
}

class _BatchName extends StatelessWidget {
  const _BatchName({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            batch.batchCode,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            [
              if (batch.displayName.isNotEmpty) batch.displayName,
              if (batch.createdAt != null) df.format(batch.createdAt!),
            ].join(' • '),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _MiniCount(label: 'كلها', value: batch.generated),
          _MiniCount(label: 'الأصلي', value: batch.originalCount),
          _MiniCount(label: 'متاح', value: batch.availableCount),
          _MiniCount(label: 'نشط', value: batch.activeCount),
          _MiniCount(label: 'منتهي', value: batch.expiredCount),
          _MiniCount(label: 'مؤرشف', value: batch.archivedCount),
          _MiniCount(label: 'قادم', value: batch.pendingArchiveCount),
          _MiniCount(label: 'تشغيلي', value: batch.operationalRemainingCount),
          _MiniCount(label: 'ملغى', value: batch.revokedCount),
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 11, color: AppTokens.textSecondary),
      ),
    );
  }
}

class _PlanAndSpeed extends StatelessWidget {
  const _PlanAndSpeed({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    final speed = [
      if ((batch.planSpeedDownKbps ?? 0) > 0) '↓ ${batch.planSpeedDownKbps}',
      if ((batch.planSpeedUpKbps ?? 0) > 0) '↑ ${batch.planSpeedUpKbps}',
    ].join(' / ');
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            batch.planName.isNotEmpty ? batch.planName : 'بدون عرض',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            [
              if (speed.isNotEmpty) speed,
              if (batch.activeSpeedRules > 0)
                '${batch.activeSpeedRules} قاعدة سرعة',
            ].join(' • '),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Text(
        [
          '${batch.sessionsCount} جلسة',
          '${batch.uniqueMacs} MAC',
          if (batch.onlineSessions > 0) '${batch.onlineSessions} متصل',
        ].join(' • '),
        style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.batch});
  final CardBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (batch.id == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'تفاصيل الحزمة',
          icon: const Icon(Icons.open_in_new, size: 18),
          onPressed: () => context.goNamed(
            'card-batch-detail',
            pathParameters: {'id': '${batch.id}'},
          ),
        ),
        IconButton(
          tooltip: 'تعديل الحزمة',
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: () => context.goNamed(
            'card-batch-edit',
            pathParameters: {'id': '${batch.id}'},
          ),
        ),
        IconButton(
          tooltip: 'قواعد السرعة',
          icon: const Icon(Icons.speed_outlined, size: 18),
          onPressed: () => context.goNamed('bandwidth-schedules'),
        ),
      ],
    );
  }
}

class _Pagination extends ConsumerWidget {
  const _Pagination({required this.page, required this.filters});
  final CardBatchOperationsPage page;
  final _BatchOpsFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          'صفحة ${page.page} من ${page.pages} • ${page.total} حزمة',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: filters.perPage,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
            DropdownMenuItem(value: 100, child: Text('100')),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref.read(_batchOpsFiltersProvider.notifier).state =
                filters.copyWith(perPage: value, page: 1);
          },
        ),
        IconButton(
          tooltip: 'السابق',
          onPressed: page.page <= 1
              ? null
              : () {
                  ref.read(_batchOpsFiltersProvider.notifier).state =
                      filters.copyWith(page: page.page - 1);
                },
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'التالي',
          onPressed: page.page >= page.pages
              ? null
              : () {
                  ref.read(_batchOpsFiltersProvider.notifier).state =
                      filters.copyWith(page: page.page + 1);
                },
          icon: const Icon(Icons.chevron_left),
        ),
      ],
    );
  }
}

String _distributorLabel(CardBatch batch) {
  if (batch.distributorDisplayName.isNotEmpty) {
    return batch.distributorDisplayName;
  }
  if (batch.distributorName.isNotEmpty) return batch.distributorName;
  if (batch.distributorId != null) return '#${batch.distributorId}';
  return 'غير مخصص';
}

String _statusLabel(String status) => switch (status) {
      'active' => 'نشطة',
      'available' => 'متاحة',
      'used' => 'مستخدمة',
      'expired' => 'منتهية',
      'exhausted' => 'مستهلكة',
      'deleted' || 'archived' => 'مؤرشفة',
      'revoked' || 'cancelled' || 'canceled' => 'ملغاة',
      _ => status,
    };

PillTone _statusTone(String status) => switch (status) {
      'active' || 'available' => PillTone.green,
      'used' || 'expired' || 'exhausted' => PillTone.orange,
      'deleted' ||
      'archived' ||
      'revoked' ||
      'cancelled' ||
      'canceled' =>
        PillTone.red,
      _ => PillTone.neutral,
    };

String _money(num value) {
  final formatted = NumberFormat('#,##0.##').format(value);
  return '$formatted ₪';
}
