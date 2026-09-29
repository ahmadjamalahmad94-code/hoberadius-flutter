import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/operational_reports_repository.dart';
import '../domain/operational_report_catalog.dart';
import '../domain/operational_report_model.dart';
import 'report_formatting.dart';

final _detailProvider = FutureProvider.autoDispose
    .family<OperationalReportSnapshot, _DetailRequest>((ref, request) {
  return ref
      .watch(operationalReportsRepositoryProvider)
      .fetch(slug: request.slug, query: request.query, limit: 300);
});

/// Bespoke detail view for a single operational report: curated column layout
/// from the catalog, server search, a client-side date-range drill-down on the
/// report's primary timestamp, and per-kind cell formatting.
class OperationalReportDetailScreen extends ConsumerStatefulWidget {
  const OperationalReportDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<OperationalReportDetailScreen> createState() =>
      _OperationalReportDetailScreenState();
}

class _OperationalReportDetailScreenState
    extends ConsumerState<OperationalReportDetailScreen> {
  final _queryController = TextEditingController();
  String _query = '';
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = operationalReportBySlug(widget.slug);
    if (def == null) {
      return _UnknownReport(slug: widget.slug);
    }
    final request = _DetailRequest(widget.slug, _query);
    final async = ref.watch(_detailProvider(request));
    final hasDate = def.dateKey != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: def.title,
          subtitle: def.subtitle,
          inlineActions: true,
          leading: IconButton(
            tooltip: 'رجوع لمركز التقارير',
            onPressed: () => context.go('/operational-reports'),
            icon: const Icon(Icons.arrow_forward),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(_detailProvider(request)),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        labelText: 'بحث',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  SizedBox(
                    width: 96,
                    child: HubActionButton(
                      item: ActionItem(
                        icon: Icons.search,
                        label: 'بحث',
                        primary: true,
                        onPressed: _search,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasDate) ...[
                const SizedBox(height: AppTokens.s8),
                // Date range on one row: من | إلى (+ clear when set).
                Row(
                  children: [
                    Expanded(
                      child: HubActionButton(
                        item: ActionItem(
                          icon: Icons.event_outlined,
                          label: _from == null ? 'من' : _fmtDay(_from!),
                          onPressed: () => _pickDate(isFrom: true),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: HubActionButton(
                        item: ActionItem(
                          icon: Icons.event_outlined,
                          label: _to == null ? 'إلى' : _fmtDay(_to!),
                          onPressed: () => _pickDate(isFrom: false),
                        ),
                      ),
                    ),
                    if (_from != null || _to != null) ...[
                      const SizedBox(width: AppTokens.s4),
                      IconButton(
                        tooltip: 'مسح التاريخ',
                        onPressed: () => setState(() {
                          _from = null;
                          _to = null;
                        }),
                        icon: const Icon(Icons.clear, size: 20),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب التقرير',
            subtitle: visibleErrorMessage(e),
          ),
          data: (snapshot) => _ReportTable(
            def: def,
            rows: _applyDateFilter(def, snapshot.items),
            totalFetched: snapshot.count,
            hasQuery: snapshot.query.isNotEmpty,
            dateFiltered: _from != null || _to != null,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _applyDateFilter(
    OperationalReportDef def,
    List<Map<String, dynamic>> items,
  ) {
    if (_from == null && _to == null) return items;
    return items.where((row) {
      final date = reportRowDate(def, row);
      if (date == null) return false;
      if (_from != null && date.isBefore(_from!)) return false;
      if (_to != null && date.isAfter(_to!)) return false;
      return true;
    }).toList();
  }

  void _search() {
    setState(() => _query = _queryController.text.trim());
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = panelNow();
    final initial = (isFrom ? _from : _to) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }
}

String _fmtDay(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.def,
    required this.rows,
    required this.totalFetched,
    required this.hasQuery,
    required this.dateFiltered,
  });

  final OperationalReportDef def;
  final List<Map<String, dynamic>> rows;
  final int totalFetched;
  final bool hasQuery;
  final bool dateFiltered;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return EmptyState(
        icon: def.icon,
        title: 'لا توجد بيانات',
        subtitle: hasQuery || dateFiltered
            ? 'لا توجد نتائج تطابق الفلترة الحالية.'
            : 'هذا التقرير لا يحتوي سجلات بعد.',
      );
    }
    final columns = def.columns;
    final countLine = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      child: Text(
        dateFiltered
            ? '${rows.length} سجل ضمن النطاق (من أصل $totalFetched)'
            : '${rows.length} سجل',
        style: const TextStyle(
          color: AppTokens.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Phones: a wide table only shows its first columns and cuts the last
        // one at the edge — render each record as a compact card instead.
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              countLine,
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: AppTokens.s8),
                _ReportRowCard(columns: columns, row: rows[i]),
              ],
            ],
          );
        }
        return _table(columns, countLine);
      },
    );
  }

  Widget _table(List<ReportColumn> columns, Widget countLine) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          countLine,
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(column.label),
                      numeric: column.numeric,
                    ),
                  )
                  .toList(),
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: columns
                          .map(
                            (column) => DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 240,
                                ),
                                child: Text(
                                  formatReportCell(column, row[column.key]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
  }
}

/// One report record as a compact phone card: the first column as the title
/// (with the status column as a coloured pill when the report has one) and
/// the remaining columns as an even two-column grid of label/value cells.
class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({required this.columns, required this.row});

  final List<ReportColumn> columns;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final head = columns.first;
    ReportColumn? status;
    for (final c in columns.skip(1)) {
      if (c.kind == ReportColumnKind.status) {
        status = c;
        break;
      }
    }
    // Empty values («—») are skipped so a card only lists the facts it has.
    final rest = [
      for (final c in columns.skip(1))
        if (c != status && formatReportCell(c, row[c.key]) != '—') c,
    ];
    const perRow = 3;
    final cells = <Widget>[];
    for (var i = 0; i < rest.length; i += perRow) {
      cells.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : AppTokens.s4 + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < perRow; j++) ...[
                if (j > 0) const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: i + j < rest.length
                      ? _cell(rest[i + j])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final statusText =
        status == null ? null : formatReportCell(status, row[status.key]);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8 + 2,
      ),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatReportCell(head, row[head.key]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (statusText != null && statusText != '—') ...[
                const SizedBox(width: AppTokens.s8),
                Flexible(
                  child: StatusPill(
                    text: statusText,
                    tone: toneForStatus(statusText),
                  ),
                ),
              ],
            ],
          ),
          if (cells.isNotEmpty) ...[
            const Divider(height: AppTokens.s12),
            ...cells,
          ],
        ],
      ),
    );
  }

  Widget _cell(ReportColumn column) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          column.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTokens.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          formatReportCell(column, row[column.key]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTokens.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UnknownReport extends StatelessWidget {
  const _UnknownReport({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'رجوع لمركز التقارير',
              onPressed: () => context.go('/operational-reports'),
              icon: const Icon(Icons.arrow_forward),
            ),
            const Expanded(
              child: Text(
                'تقرير غير معروف',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTokens.sidebarBg,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        EmptyState(
          icon: Icons.help_outline,
          title: 'هذا التقرير غير متاح',
          subtitle: 'لا يوجد تقرير بالمعرّف "$slug".',
        ),
      ],
    );
  }
}

class _DetailRequest {
  const _DetailRequest(this.slug, this.query);
  final String slug;
  final String query;

  @override
  bool operator ==(Object other) =>
      other is _DetailRequest && other.slug == slug && other.query == query;

  @override
  int get hashCode => Object.hash(slug, query);
}
