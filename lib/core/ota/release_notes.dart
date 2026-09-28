import 'package:dio/dio.dart';

/// The Shorebird release this code is built for. Patches keep it; bump it
/// together with `version:` in pubspec.yaml on every full release (a test
/// pins the two together).
const kAppRelease = '0.4.3+8';

/// «ما الجديد» notes, published next to the APK. Before installing, the app
/// still runs the OLD code, so it can only learn what a patch brings from
/// outside — this file:
/// `{"0.4.3+8": [{"patch": 5, "date": "2026-09-28", "items": ["…", "…"]}]}`
const kReleaseNotesUrl =
    'https://ledger.hoberadius.com:8091/static/hoberadius-app-notes.json';

class ReleaseNote {
  const ReleaseNote({
    required this.patch,
    required this.date,
    required this.items,
  });
  final int patch;
  final String date;
  final List<String> items;

  static List<ReleaseNote> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <ReleaseNote>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final p = e['patch'];
      final patch = p is num ? p.toInt() : int.tryParse('$p') ?? 0;
      final items = e['items'] is List
          ? [
              for (final i in e['items'] as List)
                if ('$i'.trim().isNotEmpty) '$i'.trim(),
            ]
          : <String>[];
      if (patch > 0 && items.isNotEmpty) {
        out.add(
          ReleaseNote(patch: patch, date: '${e['date'] ?? ''}', items: items),
        );
      }
    }
    out.sort((a, b) => b.patch.compareTo(a.patch)); // newest first
    return out;
  }
}

/// Notes of this release's patches in (after, upTo], newest first.
List<ReleaseNote> notesBetween(
  List<ReleaseNote> all, {
  required int after,
  int? upTo,
}) =>
    [
      for (final n in all)
        if (n.patch > after && (upTo == null || n.patch <= upTo)) n,
    ];

/// Flattened, de-duplicated items (newest patch first), capped.
List<String> noteItems(List<ReleaseNote> notes, {int max = 8}) {
  final seen = <String>{};
  final out = <String>[];
  for (final n in notes) {
    for (final i in n.items) {
      if (seen.add(i)) out.add(i);
      if (out.length >= max) return out;
    }
  }
  return out;
}

Future<List<ReleaseNote>> fetchReleaseNotes({Dio? dio}) async {
  final client = dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
  final res = await client.get<dynamic>(
    kReleaseNotesUrl,
    queryParameters: {'t': DateTime.now().millisecondsSinceEpoch ~/ 60000},
  );
  final data = res.data;
  if (data is Map) return ReleaseNote.listFrom(data[kAppRelease]);
  return const [];
}
