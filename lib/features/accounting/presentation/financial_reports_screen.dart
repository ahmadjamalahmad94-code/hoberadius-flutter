import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/accounting_repository.dart';

const _reports = <String, String>{
  'sales/daily': 'مبيعات يومية',
  'sales/monthly': 'مبيعات شهرية',
  'sales/yearly': 'مبيعات سنوية',
  'payments': 'دفعات المستفيدين',
  'loans': 'السلف',
  'activations': 'التفعيلات',
  'card-sales': 'مبيعات الكروت',
  'profit-loss': 'ربح / خسارة',
  'distributor-debts': 'ديون الموزعين',
};

final _reportProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, slug) {
  return ref.watch(accountingRepositoryProvider).financialReport(slug);
});

final _snapshotProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, slug) {
  return ref
      .watch(accountingRepositoryProvider)
      .reportSnapshots(reportType: slug);
});

class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState
    extends ConsumerState<FinancialReportsScreen> {
  String _slug = 'sales/daily';
  bool _savingSnapshot = false;
  bool _exportingCsv = false;
  bool _exportingXlsx = false;
  bool _exportingPdf = false;

  Future<void> _exportCsv() async {
    setState(() => _exportingCsv = true);
    try {
      final bytes = await ref
          .read(accountingRepositoryProvider)
          .exportFinancialReportCsv(_slug);
      await FileSaver.instance.saveFile(
        name: 'financial-report-${_slug.replaceAll('/', '-')}',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل التقرير بصيغة CSV')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  Future<void> _exportXlsx() async {
    setState(() => _exportingXlsx = true);
    try {
      final bytes = await ref
          .read(accountingRepositoryProvider)
          .exportFinancialReportXlsx(_slug);
      await FileSaver.instance.saveFile(
        name: 'financial-report-${_slug.replaceAll('/', '-')}',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل التقرير بصيغة Excel')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _exportingXlsx = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final bytes = await ref
          .read(accountingRepositoryProvider)
          .exportFinancialReportPdf(_slug);
      await FileSaver.instance.saveFile(
        name: 'financial-report-${_slug.replaceAll('/', '-')}',
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل التقرير بصيغة PDF')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _saveSnapshot() async {
    setState(() => _savingSnapshot = true);
    try {
      final snapshot = await ref
          .read(accountingRepositoryProvider)
          .createReportSnapshot(_slug);
      if (!mounted) return;
      ref.invalidate(_snapshotProvider(_slug));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ لقطة ثابتة للتقرير #${snapshot['id'] ?? ''}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _savingSnapshot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_reportProvider(_slug));
    final snapshots = ref.watch(_snapshotProvider(_slug));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'التقارير المالية',
          subtitle: 'مبنية من Ledger؛ التصحيح قيد عكسي ولا يحذف الأصل.',
          leading: const Icon(
            Icons.insert_chart_outlined,
            color: AppTokens.brand,
          ),
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () {
                ref.invalidate(_reportProvider(_slug));
                ref.invalidate(_snapshotProvider(_slug));
              },
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // One scrollable row of report types instead of a ragged
              // wrap of nine chips.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in _reports.entries) ...[
                      if (entry.key != _reports.keys.first)
                        const SizedBox(width: AppTokens.s8),
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _slug == entry.key,
                        onSelected: (_) => setState(() => _slug = entry.key),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              ActionBar(
                items: [
                  ActionItem(
                    icon: _savingSnapshot
                        ? Icons.hourglass_top
                        : Icons.lock_clock_outlined,
                    label: 'حفظ لقطة ثابتة',
                    primary: true,
                    onPressed: _savingSnapshot ? null : _saveSnapshot,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s8),
              ActionBar(
                items: [
                  ActionItem(
                    icon: _exportingCsv
                        ? Icons.hourglass_top
                        : Icons.file_download_outlined,
                    label: 'CSV',
                    onPressed: _exportingCsv ? null : _exportCsv,
                  ),
                  ActionItem(
                    icon: _exportingXlsx
                        ? Icons.hourglass_top
                        : Icons.grid_on_outlined,
                    label: 'Excel',
                    onPressed: _exportingXlsx ? null : _exportXlsx,
                  ),
                  ActionItem(
                    icon: _exportingPdf
                        ? Icons.hourglass_top
                        : Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onPressed: _exportingPdf ? null : _exportPdf,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        snapshots.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => _SnapshotStrip(message: visibleErrorMessage(e)),
          data: (items) => _SnapshotStrip(items: items),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب التقرير',
            subtitle: visibleErrorMessage(e),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return EmptyState(
                icon: Icons.insert_chart_outlined,
                title: 'لا توجد بيانات بعد',
                subtitle: _reports[_slug],
              );
            }
            final columns = rows.expand((row) => row.keys).toSet().toList()
              ..sort(_compareColumns);
            return AppCard(
              padding: EdgeInsets.zero,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: AppTokens.s20,
                  headingTextStyle:
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTokens.sidebarBg,
                          ),
                  columns: columns
                      .map((column) => DataColumn(label: Text(_label(column))))
                      .toList(),
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: columns
                              .map(
                                (column) => DataCell(
                                  Text(_cell(row[column])),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SnapshotStrip extends StatelessWidget {
  const _SnapshotStrip({this.items = const [], this.message});

  final List<Map<String, dynamic>> items;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message != null) {
      return AppCard(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Text(
          message!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
    if (items.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(AppTokens.s12),
        child: Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: AppTokens.brand, size: 20),
            SizedBox(width: AppTokens.s8),
            Expanded(
              child: Text(
                'لا توجد لقطات ثابتة لهذا التقرير بعد.',
                style: TextStyle(color: AppTokens.textMuted),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آخر اللقطات الثابتة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTokens.sidebarBg,
                ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final item in items.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.archive_outlined,
                    size: 18,
                    color: AppTokens.brand,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: Text(
                      '#${item['id']} · ${item['created_at'] ?? ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${_snapshotCount(item)} صف'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static int _snapshotCount(Map<String, dynamic> item) {
    final result = item['result'];
    if (result is Map && result['count'] is num) {
      return (result['count'] as num).toInt();
    }
    return 0;
  }
}

String _cell(Object? value) {
  if (value == null || value.toString().isEmpty) return '—';
  return value.toString();
}

const _columnLabels = {
  'period': 'الفترة',
  'status': 'الحالة',
  'username': 'اسم الدخول',
  'subscriber_id': 'رقم المستفيد',
  'distributor_id': 'رقم الموزع',
  'batch_id': 'رقم الحزمة',
  'name': 'الاسم',
  'display_name': 'الاسم الظاهر',
  'count': 'العدد',
  'transactions': 'المعاملات',
  'subscribers': 'المشتركون',
  'entries': 'القيود',
  'total': 'الإجمالي',
  'amount': 'المبلغ',
  'avg_amount': 'متوسط المبلغ',
  'currency': 'العملة',
  'minutes': 'الدقائق',
  'duration_minutes': 'الدقائق',
  'earned_minutes': 'الدقائق المستحقة',
  'activation_count': 'عدد التفعيلات',
  'still_open': 'ما زالت مفتوحة',
  'open_count': 'المفتوحة',
  'open_total': 'إجمالي المفتوح',
  'owed': 'المستحق',
  'owed_count': 'عدد المستحق',
  'credits': 'دائن',
  'debits': 'مدين',
  'net': 'الصافي',
  'debt_balance': 'الدين',
  'balance': 'الرصيد',
  'credit_limit': 'حد الائتمان',
  'sessions': 'الجلسات',
  'bytes_in': 'التحميل',
  'bytes_out': 'الرفع',
  'last_entry_at': 'آخر قيد',
  'source': 'المصدر',
};

String _label(String key) => _columnLabels[key] ?? key;

/// Known columns keep the order of [_columnLabels] (period / name first,
/// then counts and money); unknown keys follow alphabetically.
int _compareColumns(String a, String b) {
  final order = _columnLabels.keys.toList();
  final ia = order.indexOf(a);
  final ib = order.indexOf(b);
  if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
  if (ia >= 0) return -1;
  if (ib >= 0) return 1;
  return a.compareTo(b);
}
