/// Bidi helpers: Latin runs (usernames, plan names, «12.5 ILS», @handles,
/// IPs) inside Arabic text get reordered by the Unicode bidi algorithm —
/// «r04_meta — 302.35 · 30 يوم» rendered as «30 · 302.35 — r04_meta يوم» and
/// «@r11_dist» as «r11_dist@». Wrapping each run in an isolate keeps it intact.
library;

/// Left-to-right isolate (U+2066).
final String kLtrIsolate = String.fromCharCode(0x2066);

/// First-strong isolate (U+2068).
final String kFirstStrongIsolate = String.fromCharCode(0x2068);

/// Pop directional isolate (U+2069).
final String kPopIsolate = String.fromCharCode(0x2069);

/// [s] as one left-to-right unit inside RTL text. Idempotent: a string that
/// already IS one LTR isolate (its first LRI closes at its last PDI) is
/// returned unchanged, so a money text built by `formatWithCurrency` can be
/// isolated again without nesting.
String ltrIsolate(String s) {
  if (s.isEmpty || _isWholeLtrIsolate(s)) return s;
  return '$kLtrIsolate$s$kPopIsolate';
}

bool _isWholeLtrIsolate(String s) {
  if (!s.startsWith(kLtrIsolate) || !s.endsWith(kPopIsolate)) return false;
  var depth = 0;
  final units = s.runes.toList();
  for (var i = 0; i < units.length; i++) {
    final r = units[i];
    if (r >= 0x2066 && r <= 0x2068) depth++;
    if (r == 0x2069) {
      depth--;
      // The opening LRI closed before the end: two isolates side by side.
      if (depth == 0 && i != units.length - 1) return false;
    }
  }
  return depth == 0;
}

/// [s] isolated with its own direction taken from its first strong letter
/// (an Arabic plan name stays RTL, a Latin one LTR) — the surrounding text is
/// never reordered by it.
String autoIsolate(String s) =>
    s.isEmpty ? s : '$kFirstStrongIsolate$s$kPopIsolate';

/// Removes isolate / embedding marks (for comparisons in tests and search).
String stripBidiMarks(String s) => String.fromCharCodes(
      s.runes.where(
        (r) => !(r == 0x200E ||
            r == 0x200F ||
            (r >= 0x202A && r <= 0x202E) ||
            (r >= 0x2066 && r <= 0x2069)),
      ),
    );
