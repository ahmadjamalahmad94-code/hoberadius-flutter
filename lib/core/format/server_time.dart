/// One tolerant reader for every timestamp the HobeRadius API returns.
///
/// The server stores and sends **UTC**, but not always in one shape:
/// `2026-09-28T12:00:00Z`, `2026-09-28T12:00:00` (no «Z»),
/// `2026-09-28 12:00:00` (space), `2026-09-28T15:00:00+03:00` (offset) and a
/// few legacy rows written as `…+03:00Z`. A naive value is UTC, never local
/// time — reading it as local shifted every screen by the phone's offset
/// (3 h in Palestine), and a later save converted that error back into the
/// data. Every model must parse through [parseServerDateTime].
///
/// Times are returned on the PANEL's wall clock (see panel_time.dart): the
/// same hour the web panel shows, whatever zone the phone is in.
library;

import 'package:intl/intl.dart';

import 'panel_time.dart';

/// Parses an API timestamp and returns it on the panel's wall clock
/// ([toPanelWall]; the phone's zone until the server told us the panel's),
/// or `null` for null/empty/garbage. Accepts a [DateTime] too: a UTC one is
/// converted, a plain one is taken as already on the panel clock.
DateTime? parseServerDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.isUtc ? toPanelWall(value) : value;
  var raw = value.toString().trim();
  if (raw.isEmpty || raw == 'None' || raw == 'null') return null;
  // A bare calendar date (report day, due date) has no time zone: keep it
  // on the same local day instead of shifting it by the UTC offset.
  final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (dateOnly != null) {
    return DateTime(
      int.parse(dateOnly.group(1)!),
      int.parse(dateOnly.group(2)!),
      int.parse(dateOnly.group(3)!),
    );
  }
  // Legacy double suffix «…+03:00Z» / «…+0300Z»: the offset is the truth.
  final doubleSuffix = RegExp(r'([+-]\d{2}:?\d{2})Z$');
  if (doubleSuffix.hasMatch(raw)) raw = raw.substring(0, raw.length - 1);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  final utc = parsed.isUtc
      ? parsed
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return toPanelWall(utc);
}

/// UTC ISO-8601 with a trailing «Z» and no fractions, the shape every API
/// write expects: `2026-09-28T21:00:00Z`. A plain (non-UTC) [t] is a panel
/// wall-clock time (what the operator picked / what was parsed).
String toServerUtcIso(DateTime t) {
  final u = panelWallToInstant(t);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}

/// `true` for a string that looks like an API date-time
/// (`2026-09-29T01:35:23.057631Z`, `2026-09-29 01:35:23`).
bool looksLikeServerTimestamp(Object? value) =>
    value is String &&
    RegExp(r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}').hasMatch(value.trim());

/// An API timestamp (`created_at`, `linked_at`, `*_at`) for display:
/// «yyyy-MM-dd HH:mm» on the panel clock — never the raw UTC ISO string.
/// Empty → [empty]; a value that does not parse is shown as it came.
String formatServerTimestamp(Object? value, {String empty = '—'}) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty || text == 'null' || text == 'None') return empty;
  final t = parseServerDateTime(value is DateTime ? value : text);
  if (t == null) return text;
  return DateFormat('yyyy-MM-dd HH:mm').format(t);
}
