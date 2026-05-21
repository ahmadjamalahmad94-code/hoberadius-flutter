import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
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
