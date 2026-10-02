import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/format/currency.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/revenue_repository.dart';
import '../domain/revenue_model.dart';

const _statusOptions = [
  (value: '', label: 'كل الحالات'),
  (value: 'posted', label: 'مرحلة'),
  (value: 'pending', label: 'بانتظار الترحيل'),
  (value: 'voided', label: 'ملغاة'),
  (value: 'refunded', label: 'مسترجعة'),
];

final _revenueProvider = FutureProvider.autoDispose<RevenuePage>((ref) {
  return ref.watch(revenueRepositoryProvider).list();
});

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  String _status = '';
  String _sourceType = '';

  /// Rows loaded with «تحميل المزيد» beyond the first page.
  RevenuePage? _paged;
  bool _loadingMore = false;
  Object? _moreError;

  Future<void> _loadMore(RevenuePage current) async {
    if (_loadingMore || !current.hasMore) return;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final next = await ref
          .read(revenueRepositoryProvider)
          .list(offset: current.items.length);
      final before = current.items.length;
      var merged = current.withMore(next.items, hasMore: next.hasMore);
      // An old server that ignores the offset: nothing new → stop.
      if (merged.items.length == before) {
        merged = merged.withMore(const [], hasMore: false);
      }
      if (mounted) setState(() => _paged = merged);
    } catch (e) {
      if (mounted) setState(() => _moreError = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// The page as the stats should read it: the whole server page (with its
  /// totals) when no filter is set, else only the visible rows.
  RevenuePage _statsPage(RevenuePage page, List<RevenueRecord> filtered) =>
      _status.isEmpty && _sourceType.isEmpty
          ? page
          : RevenuePage(items: filtered, count: filtered.length);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_revenueProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الإيرادات',
          subtitle: 'التحصيل والتكلفة والربح لكل عملية مالية.',
          leading: const Icon(
            Icons.monetization_on_outlined,
            color: AppTokens.brand,
          ),
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(_revenueProvider),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل الإيرادات',
            subtitle: visibleErrorMessage(error),
          ),
          data: (first) {
            final page = _paged ?? first;
            final sourceOptions = _sourceOptions(page.items);
            final filtered = page.items.where((item) {
              final statusMatch = _status.isEmpty || item.status == _status;
              final sourceMatch =
                  _sourceType.isEmpty || item.sourceType == _sourceType;
              return statusMatch && sourceMatch;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RevenueFilters(
                  status: _status,
                  sourceType: _sourceType,
                  sourceOptions: sourceOptions,
                  onStatusChanged: (value) {
                    setState(() => _status = value ?? '');
                  },
                  onSourceChanged: (value) {
                    setState(() => _sourceType = value ?? '');
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا توجد سجلات إيراد بهذه الفلترة',
                    subtitle:
                        'ستظهر هنا عمليات البيع والتحصيل بعد ترحيلها في النظام المالي.',
                  )
                else ...[
                  _RevenueStatsGrid(
                    // Unfiltered: the server's totals of ALL payments (not
                    // only the loaded rows), one figure per currency, voided
                    // rows excluded. A filter shows the visible rows only.
                    collected: _statsPage(page, filtered).collectedPerCurrency,
                    netProfit: _statsPage(page, filtered).netProfitPerCurrency,
                    companyShare:
                        _statsPage(page, filtered).companySharePerCurrency,
                    partial: _sourceType.isNotEmpty || _status.isNotEmpty,
                    visibleCount: filtered.length,
                    totalCount: page.count,
                  ),
                  const SizedBox(height: AppTokens.s12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 920) {
                        return Column(
                          children: [
                            for (final item in filtered) ...[
                              _RevenueCard(item: item),
                              const SizedBox(height: AppTokens.s8),
                            ],
                          ],
                        );
                      }
                      return _RevenueTable(items: filtered);
                    },
                  ),
                  if (page.hasMore || _moreError != null)
                    LoadMoreFooter(
                      hasMore: page.hasMore,
                      loading: _loadingMore,
                      error: _moreError,
                      shown: page.items.length,
                      onLoadMore: () => _loadMore(page),
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RevenueFilters extends StatelessWidget {
  const _RevenueFilters({
    required this.status,
    required this.sourceType,
    required this.sourceOptions,
    required this.onStatusChanged,
    required this.onSourceChanged,
  });

  final String status;
  final String sourceType;
  final List<(String, String)> sourceOptions;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: _statusOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.value,
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onStatusChanged,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: sourceType,
              decoration: const InputDecoration(labelText: 'المصدر'),
              items: sourceOptions
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.$1,
                      child: Text(
                        option.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onSourceChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueStatsGrid extends StatelessWidget {
  const _RevenueStatsGrid({
    required this.collected,
    required this.netProfit,
    required this.companyShare,
    required this.visibleCount,
    required this.totalCount,
    this.partial = false,
  });

  final List<CurrencyAmount> collected;
  final List<CurrencyAmount> netProfit;
  final List<CurrencyAmount> companyShare;

  /// A filter is on: the figures cover the visible rows only.
  final bool partial;
  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CountGrid(
          columns: constraints.maxWidth < 720 ? 2 : 4,
          items: [
            CountItem.text(
              partial ? 'المحصل (المعروض)' : 'إجمالي المحصل',
              formatCurrencyList(collected),
              tone: PillTone.green,
            ),
            CountItem.text(
              partial ? 'الربح الصافي (المعروض)' : 'الربح الصافي',
              formatCurrencyList(netProfit),
              tone: PillTone.amber,
            ),
            CountItem.text(
              partial ? 'حصة الشركة (المعروض)' : 'حصة الشركة',
              formatCurrencyList(companyShare),
              tone: PillTone.brand,
            ),
            CountItem.text(
              'السجلات المعروضة',
              '$visibleCount من $totalCount',
              tone: PillTone.blue,
            ),
          ],
        );
      },
    );
  }
}

class _RevenueTable extends StatelessWidget {
  const _RevenueTable({required this.items});

  final List<RevenueRecord> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: AppTokens.s20,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('المصدر')),
            DataColumn(label: Text('السعر الأصلي')),
            DataColumn(label: Text('المحصل')),
            DataColumn(label: Text('تكلفة الجملة')),
            DataColumn(label: Text('الربح الصافي')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('التاريخ')),
          ],
          rows: [
            for (final item in items)
              DataRow(
                cells: [
                  DataCell(Text('${item.id}')),
                  DataCell(Text(item.sourceLabel)),
                  DataCell(
                    Text(formatWithCurrency(item.originalPrice, item.currency)),
                  ),
                  DataCell(
                    Text(formatWithCurrency(item.collectedAmount, item.currency)),
                  ),
                  DataCell(
                    Text(formatWithCurrency(item.wholesaleCost, item.currency)),
                  ),
                  DataCell(
                    Text(
                      formatWithCurrency(item.netProfit, item.currency),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  DataCell(
                    StatusPill(
                      text: item.statusLabel,
                      tone: _statusTone(item.status),
                      dot: true,
                    ),
                  ),
                  DataCell(Text(_fmt(item.createdAt))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.item});

  final RevenueRecord item;

  @override
  Widget build(BuildContext context) {
    String m(num v) => formatWithCurrency(v, item.currency);
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTokens.greenSoft,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppTokens.greenInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.sourceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'سجل رقم ${item.id} · ${_fmt(item.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: item.statusLabel,
                tone: _statusTone(item.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          InfoGrid(
            columns: 2,
            items: [
              InfoItem(
                icon: Icons.savings_outlined,
                label: 'المحصل',
                value: m(item.collectedAmount),
              ),
              InfoItem(
                icon: Icons.inventory_2_outlined,
                label: 'تكلفة الجملة',
                value: m(item.wholesaleCost),
              ),
              InfoItem(
                icon: Icons.trending_up_outlined,
                label: 'الربح الصافي',
                value: m(item.netProfit),
              ),
              InfoItem(
                icon: Icons.business_outlined,
                label: 'حصة الشركة',
                value: m(item.companyShare),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<(String, String)> _sourceOptions(List<RevenueRecord> items) {
  final values = items.map((item) => item.sourceType).toSet().toList()..sort();
  return [
    ('', 'كل المصادر'),
    for (final value in values) (value, revenueSourceLabel(value)),
  ];
}

PillTone _statusTone(String status) {
  return switch (status) {
    'posted' => PillTone.green,
    'pending' => PillTone.amber,
    'voided' => PillTone.red,
    'refunded' => PillTone.blue,
    _ => PillTone.neutral,
  };
}

String _fmt(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}
