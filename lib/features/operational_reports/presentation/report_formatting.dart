import 'package:hoberadius_app/core/format/currency.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/arabic_labels.dart';
import '../domain/operational_report_catalog.dart';
import 'package:hoberadius_app/core/format/server_time.dart';

/// Renders a single report cell value according to its column [kind], giving
/// each bespoke report human-friendly dates, byte counters, durations, and
/// boolean/status text instead of raw database values.
String formatReportCell(ReportColumn column, Object? value) {
  if (value == null || value.toString().trim().isEmpty) {
    if (column.kind == ReportColumnKind.boolean) return 'لا';
    return '—';
  }
  // The «العملة» column: «₪» for ILS like the web, other codes as-is.
  if (column.key == 'currency') return currencyDisplay(value.toString());
  switch (column.kind) {
    case ReportColumnKind.date:
      return _formatDate(value);
    case ReportColumnKind.bytes:
      return _formatBytes(value);
    case ReportColumnKind.duration:
      return _formatDuration(value);
    case ReportColumnKind.boolean:
      return _formatBool(value);
    case ReportColumnKind.amount:
      return _formatAmount(value);
    case ReportColumnKind.status:
    case ReportColumnKind.text:
      // raw API tokens (posted/credit/settlement…) in Arabic
      return rawTokenLabel(value.toString());
  }
}

String _formatDate(Object? value) {
  final text = value.toString();
  final parsed = parseServerDateTime(text);
  if (parsed == null) return text;
  return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
}

String _formatBytes(Object? value) {
  final bytes = _toInt(value);
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var unit = 0;
  while (v >= 1024 && unit < units.length - 1) {
    v /= 1024;
    unit++;
  }
  return '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[unit]}';
}

String _formatDuration(Object? value) {
  final seconds = _toInt(value);
  if (seconds <= 0) return '—';
  final d = Duration(seconds: seconds);
  if (d.inDays > 0) return '${d.inDays}ي ${d.inHours.remainder(24)}س';
  if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes.remainder(60)}د';
  if (d.inMinutes > 0) return '${d.inMinutes}د ${d.inSeconds.remainder(60)}ث';
  return '${d.inSeconds}ث';
}

String _formatBool(Object? value) {
  if (value is bool) return value ? 'نعم' : 'لا';
  final text = value.toString().trim().toLowerCase();
  const truthy = {'1', 'true', 'yes', 'نعم'};
  return truthy.contains(text) ? 'نعم' : 'لا';
}

/// The app's one money format — no float noise (117.58999999999999) and no
/// 13-digit blobs.
String _formatAmount(Object? value) {
  final parsed = num.tryParse(value.toString());
  if (parsed == null || !parsed.isFinite) return value.toString();
  return formatMoneyAmount(parsed);
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Returns the row's primary timestamp (for [def.dateKey]) as a [DateTime],
/// or null if absent/unparseable. Used by the client-side date-range filter.
DateTime? reportRowDate(OperationalReportDef def, Map<String, dynamic> row) {
  final key = def.dateKey;
  if (key == null) return null;
  final raw = row[key]?.toString();
  if (raw == null || raw.isEmpty) return null;
  return parseServerDateTime(raw);
}
