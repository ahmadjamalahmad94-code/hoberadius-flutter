/// One tolerant reader for every timestamp the HobeRadius API returns.
///
/// The server stores and sends **UTC**, but not always in one shape:
/// `2026-09-28T12:00:00Z`, `2026-09-28T12:00:00` (no «Z»),
/// `2026-09-28 12:00:00` (space), `2026-09-28T15:00:00+03:00` (offset) and a
/// few legacy rows written as `…+03:00Z`. A naive value is UTC, never local
/// time — reading it as local shifted every screen by the phone's offset
/// (3 h in Palestine), and a later save converted that error back into the
/// data. Every model must parse through [parseServerDateTime].
library;

/// Parses an API timestamp and returns it in the device's local time, or
/// `null` for null/empty/garbage. Accepts a [DateTime] too (already parsed).
DateTime? parseServerDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
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
  return utc.toLocal();
}

/// UTC ISO-8601 with a trailing «Z» and no fractions, the shape every API
/// write expects: `2026-09-28T21:00:00Z`.
String toServerUtcIso(DateTime t) {
  final u = t.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}
