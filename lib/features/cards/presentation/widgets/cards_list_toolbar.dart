import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final search = TextField(
      controller: _queryController,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        labelText: 'بحث',
        hintText: 'اسم الحزمة، العرض، المدير...',
        prefixIcon: Icon(Icons.search),
      ),
      onSubmitted: (_) => _applySearch(),
    );
    final status = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: widget.filters.status,
      decoration: const InputDecoration(labelText: 'الحالة'),
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
              if (wide)
                Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: AppTokens.s12),
                    SizedBox(width: 220, child: status),
                  ],
                )
              else ...[
                search,
                const SizedBox(height: AppTokens.s12),
                status,
              ],
              const SizedBox(height: AppTokens.s12),
              ActionBar(
                maxPerRow: 4,
                items: [
                  ActionItem(
                    icon: Icons.filter_alt_outlined,
                    label: 'تطبيق',
                    primary: true,
                    onPressed: _applySearch,
                  ),
                  ActionItem(
                    icon: Icons.file_download_outlined,
                    label: 'CSV',
                    onPressed: widget.onExportCsv,
                  ),
                  ActionItem(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    onPressed: widget.onExportXlsx,
                  ),
                  ActionItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onPressed: widget.onExportPdf,
                  ),
                ],
              ),
              if (widget.selectedCount > 0) ...[
                const SizedBox(height: AppTokens.s12),
                Text(
                  'محدد: ${widget.selectedCount} حزمة',
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
