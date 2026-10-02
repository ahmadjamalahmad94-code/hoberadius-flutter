import 'package:hoberadius_app/core/format/arabic_plural.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/permissions.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/cards_list_providers.dart';

/// Filter + export + bulk-action toolbar above the batches table.
class CardsListToolbar extends ConsumerStatefulWidget {
  const CardsListToolbar({
    super.key,
    required this.filters,
    required this.selectedCount,
    required this.onFiltersChanged,
    required this.onExportCsv,
    required this.onExportXlsx,
    required this.onExportPdf,
    required this.onBulkAction,
  });

  final CardBatchOpsFilters filters;
  final int selectedCount;
  final ValueChanged<CardBatchOpsFilters> onFiltersChanged;
  final VoidCallback onExportCsv;
  final VoidCallback onExportXlsx;
  final VoidCallback onExportPdf;
  final ValueChanged<String> onBulkAction;

  @override
  ConsumerState<CardsListToolbar> createState() => _CardsListToolbarState();
}

class _CardsListToolbarState extends ConsumerState<CardsListToolbar> {
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
  void didUpdateWidget(covariant CardsListToolbar oldWidget) {
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
    final perms = ref.watch(permissionsProvider);
    // Exports = data.export (users.export); bulk = cards.batch_ops.
    final exportDenied = perms.canAction('data.export')
        ? null
        : perms.deniedReason(action: 'data.export', perm: 'users.export');
    final canBulk = perms.canAction('cards.batch_ops');
    final search = TextField(
      controller: _queryController,
      textInputAction: TextInputAction.search,
      // Compact (owner 2026-10-02: «صغّر شريط البحث» — lower, simpler card).
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'بحث: اسم الحزمة، العرض، المدير...',
        prefixIcon: Icon(Icons.search, size: 20),
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      onSubmitted: (_) => _applySearch(),
    );
    final status = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: widget.filters.status,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'الحالة',
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
      items: [
        for (final item in _statuses.entries)
          DropdownMenuItem(value: item.key, child: Text(item.value)),
      ],
      onChanged: (value) => widget.onFiltersChanged(
        widget.filters.copyWith(status: value ?? '', page: 1),
      ),
    );
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: search + «تطبيق» beside it (was a separate button row).
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: AppTokens.s8),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: _applySearch,
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('تطبيق'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: AppTokens.s8),
                    SizedBox(width: 220, child: status),
                  ],
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              // Row 2 (owner 2026-10-02): status + ONE «تصدير» button whose
              // menu holds CSV / Excel / PDF (were three buttons on a row).
              Row(
                children: [
                  if (!wide) Expanded(child: status) else const Spacer(),
                  const SizedBox(width: AppTokens.s8),
                  Tooltip(
                    message: exportDenied ?? '',
                    child: PopupMenuButton<VoidCallback>(
                      key: const ValueKey('cards-export-menu'),
                      enabled: exportDenied == null,
                      tooltip: exportDenied ?? 'تصدير الحزم المعروضة',
                      onSelected: (run) => run(),
                      itemBuilder: (_) => [
                        for (final e in <(IconData, String, VoidCallback)>[
                          (Icons.file_download_outlined, 'CSV', widget.onExportCsv),
                          (Icons.table_chart_outlined, 'Excel', widget.onExportXlsx),
                          (Icons.picture_as_pdf_outlined, 'PDF', widget.onExportPdf),
                        ])
                          PopupMenuItem<VoidCallback>(
                            value: e.$3,
                            child: Row(
                              children: [
                                Icon(e.$1, size: 20, color: AppTokens.brand),
                                const SizedBox(width: AppTokens.s8),
                                Text(e.$2),
                              ],
                            ),
                          ),
                      ],
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTokens.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.ios_share,
                              size: 18,
                              color: exportDenied == null
                                  ? AppTokens.brand
                                  : AppTokens.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'تصدير',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: exportDenied == null
                                    ? AppTokens.brand
                                    : AppTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.selectedCount > 0 && canBulk) ...[
                const SizedBox(height: AppTokens.s12),
                Text(
                  'محدد: ${arCount(widget.selectedCount, arBatch, showOne: true)}',
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                ActionBar(
                  items: [
                    ActionItem(
                      icon: Icons.archive_outlined,
                      label: 'أرشفة',
                      tone: PillTone.amber,
                      onPressed: () => widget.onBulkAction('archive'),
                    ),
                    ActionItem(
                      icon: Icons.restore_outlined,
                      label: 'استعادة',
                      onPressed: () => widget.onBulkAction('restore'),
                    ),
                    ActionItem(
                      icon: Icons.sync,
                      label: 'تحديث',
                      onPressed: () => widget.onBulkAction('refresh'),
                    ),
                  ],
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
