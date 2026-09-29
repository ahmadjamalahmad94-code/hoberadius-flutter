import '../../../core/format/currency.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hoberadius_app/core/format/server_time.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/l10n/arabic_labels.dart';
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
    .family<FinancialReportTable, String>((ref, slug) {
  return ref.watch(accountingRepositoryProvider).financialReportTable(slug);
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
      final raw = await ref
          .read(accountingRepositoryProvider)
          .exportFinancialReportCsv(_slug);
      final bytes = financialReportCsvForSave(raw, _slug);
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للتصدير')),
        );
        return;
      }
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
              // All report chips visible (wrapped): in a scrolling row the
              // selected chip could sit off-screen (A13 L4).
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  for (final entry in _reports.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _slug == entry.key,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _slug = entry.key),
                    ),
                ],
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
          data: (table) {
            final rows = table.rows;
            if (rows.isEmpty) {
              return EmptyState(
                icon: Icons.insert_chart_outlined,
                title: 'لا توجد بيانات بعد',
                subtitle: _reports[_slug],
              );
            }
            final columns = reportColumnKeys(table);
            final labels = {for (final (k, l) in table.columns) k: l};
            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The table is wider than a phone: say so (the «الإجمالي»
                  // column was clipped with no hint).
                  if (columns.length > 3)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swipe_left_outlined,
                            size: 16,
                            color: AppTokens.textMuted,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'اسحب الجدول أفقيًا لرؤية كل الأعمدة.',
                              style: TextStyle(
                                color: AppTokens.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: AppTokens.s20,
                      headingTextStyle:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTokens.sidebarBg,
                              ),
                      columns: columns
                          .map(
                            (column) => DataColumn(
                              label: Text(labels[column] ?? _label(column)),
                            ),
                          )
                          .toList(),
                      rows: rows
                          .map(
                            (row) => DataRow(
                              cells: columns
                                  .map(
                                    (column) => DataCell(
                                      Text(reportCell(row, column)),
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
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
                      '#${item['id']} · ${formatReportTimestamp(item['created_at'])}',
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

final RegExp _isoStamp = RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}');

/// A server timestamp as the panel shows it («2026-09-29 03:01»), never the
/// raw UTC ISO (`2026-09-29T00:01:08.532034Z`, 3 h off the operator clock).
String formatReportTimestamp(Object? value) => formatServerTimestamp(value);

/// Internal helper columns never shown as their own column: a row's
/// per-currency split is shown INSIDE its money cells instead.
const _hiddenReportColumns = {'mixed_currency', 'by_currency'};

/// The columns to show: the server's order (fix2 `columns`), else the keys
/// of the rows in the app's own order; helper columns hidden.
List<String> reportColumnKeys(FinancialReportTable table) {
  final keys = table.columns.isNotEmpty
      ? [
          for (final (k, _) in table.columns) k,
          for (final k in table.rows.expand((r) => r.keys).toSet())
            if (!table.columns.any((c) => c.$1 == k)) k,
        ]
      : (table.rows.expand((row) => row.keys).toSet().toList()
        ..sort(_compareColumns));
  return keys.where((k) => !_hiddenReportColumns.contains(k)).toList();
}

const _moneyColumns = {
  'total',
  'amount',
  'avg_amount',
  'outstanding',
  'credits',
  'debits',
  'net',
  'open_total',
  'owed',
};

/// One cell. A money cell of a MIXED-currency row shows one amount per
/// currency (`by_currency`) — never one sum of ILS + USD + EUR.
String reportCell(Map<String, dynamic> row, String column) {
  final split = row['by_currency'];
  if (_moneyColumns.contains(column) &&
      split is List &&
      (row['mixed_currency'] == true || split.length > 1)) {
    final parts = parseByCurrency(
      split,
      fields: [column, 'total', 'total_amount', 'amount'],
    );
    if (parts.isNotEmpty) return formatByCurrency(parts);
  }
  return _cell(row[column]);
}

String _cell(Object? value) {
  if (value == null || value.toString().isEmpty) return '—';
  if (value is String && _isoStamp.hasMatch(value.trim())) {
    return formatReportTimestamp(value);
  }
  // Amounts: grouped, 2 decimals, no float noise (117.58999999999999).
  if (value is double) {
    if (!value.isFinite) return '—';
    return NumberFormat('#,##0.##').format(value);
  }
  if (value is int && value.abs() >= 10000) {
    return NumberFormat('#,##0').format(value);
  }
  return rawTokenLabel(value.toString());
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
  'outstanding': 'المتبقّي',
  'settled_amount': 'المسدَّد',
  'paid_to_debt': 'سداد الدين',
  'paid_to_balance': 'إضافة للرصيد',
  'created_at': 'التاريخ',
  'first_entry_at': 'أول قيد',
  'owed_count': 'عدد المستحق',
  'credits': 'دائن',
  'debits': 'مدين',
  'net': 'الصافي',
  'debt_balance': 'الدين',
  'balance': 'الرصيد',
  'credit_limit': 'حد الائتمان',
  'sessions': 'الجلسات',
  // RFC 2866: input octets = the user's UPLOAD, output = DOWNLOAD.
  'bytes_in': 'الرفع',
  'bytes_out': 'التنزيل',
  'last_entry_at': 'آخر قيد',
  'source': 'المصدر',
};

String _label(String key) => financialReportColumnLabel(key);

/// The columns of a report whose empty export has nothing to take them from
/// (the server's own `_REPORT_EMPTY_COLUMNS`).
const kFinancialReportEmptyColumns = <String, List<String>>{
  'card-sales': ['batch_id', 'count', 'total'],
  'distributor-debts': [
    'distributor_id',
    'name',
    'display_name',
    'debt_balance',
    'balance',
    'credit_limit',
  ],
};

/// The CSV to save for [slug]. A server CSV that is empty or only a UTF-8
/// BOM (an empty report: 3 bytes, no header — R11 L-7) becomes a BOM + an
/// Arabic header row of the report's known columns; null when the columns
/// are not known either («لا توجد بيانات للتصدير», nothing is saved).
Uint8List? financialReportCsvForSave(Uint8List bytes, String slug) {
  var body = bytes;
  if (body.length >= 3 &&
      body[0] == 0xEF &&
      body[1] == 0xBB &&
      body[2] == 0xBF) {
    body = Uint8List.sublistView(body, 3);
  }
  if (utf8.decode(body, allowMalformed: true).trim().isNotEmpty) return bytes;
  final columns = kFinancialReportEmptyColumns[slug];
  if (columns == null || columns.isEmpty) return null;
  String cell(String v) =>
      v.contains(RegExp(r'[",\r\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
  final header = columns.map((c) => cell(financialReportColumnLabel(c)));
  return Uint8List.fromList([
    0xEF, 0xBB, 0xBF, // UTF-8 BOM: Excel opens the Arabic header correctly
    ...utf8.encode('${header.join(',')}\r\n'),
  ]);
}

/// Arabic header of a financial-report column (raw key only if unknown).
String financialReportColumnLabel(String key) => _columnLabels[key] ?? key;

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
