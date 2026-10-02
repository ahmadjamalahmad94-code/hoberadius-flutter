import 'package:hoberadius_app/core/format/arabic_plural.dart';
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

/// Page size of one server request (the API caps `limit` at 1000).
const int kOperationalReportPageSize = 100;

/// Bespoke detail view for a single operational report: curated column layout
/// from the catalog and the web page's filters — search, من/إلى (local days),
/// and for the login reports النتيجة/المصدر — all applied by the SERVER, with
/// «تحميل المزيد» paging. (It used to fetch the newest 300 rows once and
/// filter the dates locally, so any older day showed nothing.)
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
  OperationalReportQuery _filters = const OperationalReportQuery();

  List<Map<String, dynamic>> _rows = const [];
  int? _matched;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (operationalReportBySlug(widget.slug) == null) return;
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await ref.read(operationalReportsRepositoryProvider).fetch(
            slug: widget.slug,
            filters: _filters,
            limit: kOperationalReportPageSize,
          );
      if (!mounted || gen != _generation) return;
      setState(() {
        _rows = snap.items;
        _matched = snap.matched;
        _hasMore = _moreAfter(snap, snap.items.length);
        _loading = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final snap = await ref.read(operationalReportsRepositoryProvider).fetch(
            slug: widget.slug,
            filters: _filters,
            limit: kOperationalReportPageSize,
            offset: _rows.length,
          );
      if (!mounted || gen != _generation) return;
      setState(() {
        _rows = [..._rows, ...snap.items];
        _matched = snap.matched ?? _matched;
        _hasMore = _moreAfter(snap, _rows.length);
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(e))),
      );
    }
  }

  static bool _moreAfter(OperationalReportSnapshot snap, int loaded) {
    final matched = snap.matched;
    if (matched != null) return loaded < matched;
    return snap.items.length >= kOperationalReportPageSize;
  }

  void _setFilters(OperationalReportQuery next) {
    if (next == _filters) return;
    _filters = next;
    _reload();
  }

  OperationalReportQuery _copy({
    String? query,
    DateTime? Function()? from,
    DateTime? Function()? to,
    String? result,
    String? source,
  }) {
    return OperationalReportQuery(
      query: query ?? _filters.query,
      dateFrom: from != null ? from() : _filters.dateFrom,
      dateTo: to != null ? to() : _filters.dateTo,
      result: result ?? _filters.result,
      source: source ?? _filters.source,
    );
  }

  @override
  Widget build(BuildContext context) {
    final def = operationalReportBySlug(widget.slug);
    if (def == null) {
      return _UnknownReport(slug: widget.slug);
    }
    final hasDate = def.dateKey != null;
    final from = _filters.dateFrom;
    final to = _filters.dateTo;

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
              onPressed: _reload,
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
                          label: from == null ? 'من' : _fmtDay(from),
                          onPressed: () => _pickDate(isFrom: true),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: HubActionButton(
                        item: ActionItem(
                          icon: Icons.event_outlined,
                          label: to == null ? 'إلى' : _fmtDay(to),
                          onPressed: () => _pickDate(isFrom: false),
                        ),
                      ),
                    ),
                    if (from != null || to != null) ...[
                      const SizedBox(width: AppTokens.s4),
                      IconButton(
                        tooltip: 'مسح التاريخ',
                        onPressed: () => _setFilters(
                          _copy(from: () => null, to: () => null),
                        ),
                        icon: const Icon(Icons.clear, size: 20),
                      ),
                    ],
                  ],
                ),
              ],
              if (def.resultFilter || def.sourceFilter) ...[
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    if (def.resultFilter)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const ValueKey('report-result-filter'),
                          isExpanded: true,
                          initialValue: _filters.result,
                          decoration: const InputDecoration(
                            labelText: 'النتيجة',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('الكل')),
                            DropdownMenuItem(
                              value: 'success',
                              child: Text('نجاح'),
                            ),
                            DropdownMenuItem(value: 'fail', child: Text('فشل')),
                          ],
                          onChanged: (v) => _setFilters(_copy(result: v ?? '')),
                        ),
                      ),
                    if (def.resultFilter && def.sourceFilter)
                      const SizedBox(width: AppTokens.s8),
                    if (def.sourceFilter)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const ValueKey('report-source-filter'),
                          isExpanded: true,
                          initialValue: _filters.source,
                          decoration: const InputDecoration(
                            labelText: 'المصدر',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('الكل')),
                            DropdownMenuItem(
                              value: 'panel',
                              child: Text('لوحة التحكم'),
                            ),
                            DropdownMenuItem(
                              value: 'portal',
                              child: Text('البوابة'),
                            ),
                            DropdownMenuItem(
                              value: 'network',
                              child: Text('الشبكة'),
                            ),
                          ],
                          onChanged: (v) => _setFilters(_copy(source: v ?? '')),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.s24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب التقرير',
            subtitle: visibleErrorMessage(_error!),
          )
        else ...[
          _ReportTable(
            def: def,
            rows: _rows,
            matched: _matched,
            filtered: _filters.hasFilters,
          ),
          if (_hasMore) ...[
            const SizedBox(height: AppTokens.s12),
            Center(
              child: OutlinedButton.icon(
                key: const ValueKey('report-load-more'),
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: const Text('تحميل المزيد'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _search() {
    _setFilters(_copy(query: _queryController.text.trim()));
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = panelNow();
    final initial = (isFrom ? _filters.dateFrom : _filters.dateTo) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    // A calendar day; the server turns it into the panel's LOCAL day bounds.
    final day = DateTime(picked.year, picked.month, picked.day);
    _setFilters(isFrom ? _copy(from: () => day) : _copy(to: () => day));
  }
}

String _fmtDay(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.def,
    required this.rows,
    required this.matched,
    required this.filtered,
  });

  final OperationalReportDef def;
  final List<Map<String, dynamic>> rows;

  /// Server total for the filters (login reports); null when not reported.
  final int? matched;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return EmptyState(
        icon: def.icon,
        title: 'لا توجد بيانات',
        subtitle: filtered
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
        matched != null && matched! > rows.length
            ? '${arCount(rows.length, arRecord, showOne: true)} معروضة من أصل $matched'
            : arCount(rows.length, arRecord, showOne: true),
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
      if (c.kind == ReportColumnKind.status ||
          c.kind == ReportColumnKind.result) {
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
                    tone: status!.kind == ReportColumnKind.result
                        ? (statusText == 'نجاح' ? PillTone.green : PillTone.red)
                        : toneForStatus(statusText),
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
