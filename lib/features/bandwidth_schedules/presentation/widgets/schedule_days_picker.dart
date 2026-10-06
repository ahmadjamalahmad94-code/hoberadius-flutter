import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Schedule DAYS (`days_csv`) — same chips, codes and order as the web
/// (`_partials/schedule_days_picker.html`): sat..fri. Empty = every day.
///
/// fields-sched 2026-10-06: the owner chose «وصّله» — the server now applies
/// a schedule ONLY on its selected days (panel-local day, Asia/Gaza). A window
/// that crosses midnight belongs to the day it starts.
const kScheduleDays = <(String, String)>[
  ('sat', 'السبت'),
  ('sun', 'الأحد'),
  ('mon', 'الإثنين'),
  ('tue', 'الثلاثاء'),
  ('wed', 'الأربعاء'),
  ('thu', 'الخميس'),
  ('fri', 'الجمعة'),
];

/// Parses a stored `days_csv` into the known day codes.
Set<String> parseScheduleDays(String csv) {
  final known = {for (final d in kScheduleDays) d.$1};
  return csv
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .where(known.contains)
      .toSet();
}

/// Canonical CSV (sat..fri order) for the API.
String scheduleDaysCsv(Set<String> days) =>
    [for (final d in kScheduleDays) if (days.contains(d.$1)) d.$1].join(',');

/// «كل الأيام» or «الجمعة · السبت» — the web list's label.
String scheduleDaysLabel(String csv) {
  final days = parseScheduleDays(csv);
  if (days.isEmpty || days.length == 7) return 'كل الأيام';
  return [
    for (final d in kScheduleDays)
      if (days.contains(d.$1)) d.$2,
  ].join(' · ');
}

class ScheduleDaysPicker extends StatelessWidget {
  const ScheduleDaysPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'الأيام',
          style: TextStyle(
            color: AppTokens.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Wrap(
          spacing: AppTokens.s4,
          runSpacing: AppTokens.s4,
          children: [
            for (final d in kScheduleDays)
              FilterChip(
                key: ValueKey('sched-day-${d.$1}'),
                label: Text(d.$2),
                selected: selected.contains(d.$1),
                onSelected: (on) {
                  final next = {...selected};
                  on ? next.add(d.$1) : next.remove(d.$1);
                  onChanged(next);
                },
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s4),
        const Text(
          'اترك الأيام فارغة ليعمل الجدول كل يوم. النافذة التي تعبر منتصف الليل تتبع يوم بدايتها.',
          style: TextStyle(color: AppTokens.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
