/// The PANEL time zone — every time the operator reads or picks in the app.
///
/// The web panel shows and parses times in the tenant's configured zone
/// (`billing.timezone`, default Asia/Damascus, UTC+3 all year). The app used
/// the PHONE's zone, so a Palestine phone in winter (UTC+2) saw 14:30 where
/// the web said 15:30, and a time picked in the app landed an hour off on the
/// web (r01 N6). Now:
/// - the zone comes from the server (`system.tz_name` / `system.tz_offset`
///   of /api/admin/me, or `billing.timezone` of /api/v1/settings);
/// - [toPanelWall] turns a server instant into the panel's wall-clock time
///   (a plain `DateTime` whose fields ARE the panel time, so every formatter
///   shows panel time), and [panelWallToInstant] turns a picked wall time back
///   into the real UTC instant;
/// - until a zone is known (old server, before login) the phone's zone is
///   used, exactly as before.
library;

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'bidi.dart';

/// Process-wide panel zone (models parse timestamps without a `ref`).
class PanelTimeZone {
  PanelTimeZone._();

  static String _name = '';
  static String _label = '';
  static Duration? _fixedOffset;
  static tz.Location? _location;
  static List<PanelTzTransition> _transitions = const [];

  /// `system.local_time_rule.ambiguous`: «earlier» (the server's rule,
  /// fold=0 — the default) or «later».
  static bool ambiguousLater = false;
  static bool _dbLoaded = false;

  /// Bumped on every change (widgets/tests can compare).
  static int revision = 0;

  /// The IANA name in use ('' when only an offset — or nothing — is known).
  static String get name => _location != null ? _name : '';

  /// A zone (name, offset or transition table) came from the server.
  static bool get isConfigured =>
      _location != null || _fixedOffset != null || _transitions.isNotEmpty;

  /// Sets the panel zone from the server's values. An unknown [name] falls
  /// back to [offsetHours] (the server's legacy `billing.timezone_offset`);
  /// neither → the phone's zone.
  static void configure({
    String? name,
    num? offsetHours,
    String? label,
    List<PanelTzTransition>? transitions,
    String? ambiguousRule,
  }) {
    ambiguousLater = (ambiguousRule ?? '').trim().toLowerCase() == 'later';
    _transitions = [...?transitions]..sort((a, b) => a.at.compareTo(b.at));
    _label = (label ?? '').trim();
    final n = (name ?? '').trim();
    tz.Location? loc;
    if (n.isNotEmpty) {
      if (n.toUpperCase() == 'UTC') {
        _ensureDb();
        loc = tz.UTC;
      } else {
        try {
          _ensureDb();
          loc = tz.getLocation(n);
        } catch (_) {
          loc = null;
        }
      }
    }
    _location = loc;
    _name = loc == null ? '' : n;
    _fixedOffset = loc == null && offsetHours != null && offsetHours.isFinite
        ? Duration(minutes: (offsetHours * 60).round())
        : null;
    revision++;
  }

  /// Back to the phone's zone (sign-out, tests).
  static void reset() {
    ambiguousLater = false;
    _transitions = const [];
    _location = null;
    _name = '';
    _label = '';
    _fixedOffset = null;
    revision++;
  }

  static void _ensureDb() {
    if (_dbLoaded) return;
    tzdata.initializeTimeZones();
    _dbLoaded = true;
  }

  /// The panel's UTC offset at [instant].
  static Duration offsetAt(DateTime instant) {
    final loc = _location;
    if (loc != null) {
      return Duration(
        milliseconds: loc.timeZone(instant.millisecondsSinceEpoch).offset,
      );
    }
    // No zone database entry: the server's own transition table
    // (`system.tz_transitions`) still gives DST right.
    final t = _transitions;
    if (t.isNotEmpty) {
      final at = instant.toUtc();
      if (at.isBefore(t.first.at)) return t.first.offsetBefore;
      var off = t.first.offsetAfter;
      for (final x in t) {
        if (x.at.isAfter(at)) break;
        off = x.offsetAfter;
      }
      return off;
    }
    return _fixedOffset ?? instant.toLocal().timeZoneOffset;
  }

  /// «UTC+03:00» at [at] (now by default). A non-UTC [at] is a PANEL wall
  /// time (the pickers pass the chosen time): it is resolved to its instant
  /// first — «01:30 on 24 Oct» is +03:00 (first occurrence), not +02:00.
  static String offsetLabel([DateTime? at]) {
    final instant =
        at == null ? DateTime.now() : (at.isUtc ? at : panelWallToInstant(at));
    final off = offsetAt(instant);
    final sign = off.isNegative ? '-' : '+';
    final m = off.inMinutes.abs();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'UTC$sign${two(m ~/ 60)}:${two(m % 60)}';
  }

  /// Short Arabic caption for pickers and expiry fields, e.g.
  /// «بتوقيت اللوحة: Asia/Damascus (UTC+03:00)».
  static String label([DateTime? at]) {
    if (!isConfigured) return 'بتوقيت الجهاز (${offsetLabel(at)})';
    final zone = name.isEmpty ? offsetLabel(at) : '$name (${offsetLabel(at)})';
    // The server's Arabic name («غزة (فلسطين)») when it sends one.
    if (_label.isNotEmpty) {
      return 'بتوقيت اللوحة: $_label ${ltrIsolate(offsetLabel(at))}';
    }
    // LTR isolate so the zone name and sign are not reordered in RTL.
    return 'بتوقيت اللوحة: ${ltrIsolate(zone)}';
  }
}

/// The panel wall-clock time of [instant] as a plain (non-UTC) `DateTime`
/// whose fields are what the web panel shows.
DateTime toPanelWall(DateTime instant) {
  if (!PanelTimeZone.isConfigured) return instant.toLocal();
  final utc = instant.toUtc();
  final w = utc.add(PanelTimeZone.offsetAt(utc));
  return DateTime(
    w.year,
    w.month,
    w.day,
    w.hour,
    w.minute,
    w.second,
    w.millisecond,
    w.microsecond,
  );
}

/// The UTC instant of a panel wall-clock time (a picked date/time). A value
/// that is already UTC is returned unchanged.
DateTime panelWallToInstant(DateTime wall) {
  if (wall.isUtc) return wall;
  if (!PanelTimeZone.isConfigured) return wall.toUtc();
  final asUtc = DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
    wall.millisecond,
    wall.microsecond,
  );
  // The server's rule (`system.local_time_rule`, zoneinfo fold=0): a
  // REPEATED wall time (the autumn hour) is its FIRST occurrence — the
  // pre-transition offset; a SKIPPED one (the spring gap) is read with the
  // pre-transition offset too, landing after the jump. Candidates are the
  // offsets around that day; the earliest instant that really shows [wall]
  // wins. (The app used to take the second occurrence: 2026-10-24 01:30 →
  // 23:30Z where the web wrote 22:30Z — f03 N7.)
  const day = Duration(hours: 26);
  final before = PanelTimeZone.offsetAt(asUtc.subtract(day));
  final after = PanelTimeZone.offsetAt(asUtc.add(day));
  final offsets = {before, PanelTimeZone.offsetAt(asUtc), after};
  DateTime? best;
  for (final off in offsets) {
    final candidate = asUtc.subtract(off);
    if (PanelTimeZone.offsetAt(candidate) != off) continue;
    if (best == null ||
        (PanelTimeZone.ambiguousLater
            ? candidate.isAfter(best)
            : candidate.isBefore(best))) {
      best = candidate;
    }
  }
  return best ?? asUtc.subtract(before);
}

/// One DST switch of the panel zone (`system.tz_transitions`).
class PanelTzTransition {
  const PanelTzTransition({
    required this.at,
    required this.offsetBefore,
    required this.offsetAfter,
  });

  /// The UTC instant of the switch.
  final DateTime at;
  final Duration offsetBefore;
  final Duration offsetAfter;

  static List<PanelTzTransition> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <PanelTzTransition>[];
    for (final m in raw.whereType<Map>()) {
      final at = DateTime.tryParse('${m['at'] ?? ''}');
      num? n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');
      final b = n(m['offset_before_minutes']);
      final a = n(m['offset_after_minutes']);
      if (at == null || b == null || a == null) continue;
      out.add(
        PanelTzTransition(
          at: at.toUtc(),
          offsetBefore: Duration(minutes: b.round()),
          offsetAfter: Duration(minutes: a.round()),
        ),
      );
    }
    return out;
  }
}

/// «Now» on the panel's wall clock — compare it with parsed server times.
DateTime panelNow([DateTime? clock]) => toPanelWall(clock ?? DateTime.now());
