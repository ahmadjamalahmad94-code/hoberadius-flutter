import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';
import 'hub_time_picker_circular.dart';

/// Canonical access-schedule picker — Flutter mirror of the web
/// `_partials/access_schedule.html` macro.
///
/// JSON model matches the server's
/// `app/radius/core/access_schedule.serialize()` shape:
///
/// ```json
/// {"windows": [{"days": ["sat","sun"], "from": "08:00", "to": "16:00"}]}
/// ```
///
/// The widget operates in two modes:
///   * **simple** — one set of allowed days shared across every window.
///   * **advanced** — per-day blocks, each carrying its own list of
///     windows (used when a subscriber needs different hours per day).
///
/// Mode auto-detects on initial value: ≥ 2 windows each tied to a
/// single distinct day → advanced; otherwise simple.

// ───────────────────────────────────────────────────────────────
//  Data model
// ───────────────────────────────────────────────────────────────
const List<String> kAccessDays = [
  'sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri',
];

const Map<String, String> kAccessDayNames = {
  'sat': 'السبت',
  'sun': 'الأحد',
  'mon': 'الإثنين',
  'tue': 'الثلاثاء',
  'wed': 'الأربعاء',
  'thu': 'الخميس',
  'fri': 'الجمعة',
};

class AccessWindow {
  const AccessWindow({
    this.days = const [],
    this.from = '',
    this.to = '',
  });

  final List<String> days;
  final String from;
  final String to;

  AccessWindow copyWith({
    List<String>? days,
    String? from,
    String? to,
  }) =>
      AccessWindow(
        days: days ?? this.days,
        from: from ?? this.from,
        to: to ?? this.to,
      );

  Map<String, dynamic> toJson() => {
        'days': days,
        'from': from,
        'to': to,
      };

  factory AccessWindow.fromJson(Map<String, dynamic> j) => AccessWindow(
        days: (j['days'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        from: (j['from'] as String?) ?? '',
        to: (j['to'] as String?) ?? '',
      );
}

class AccessSchedule {
  const AccessSchedule({this.windows = const []});
  final List<AccessWindow> windows;

  bool get isEmpty => windows.isEmpty;

  Map<String, dynamic> toJson() =>
      {'windows': windows.map((w) => w.toJson()).toList()};

  factory AccessSchedule.fromJson(Map<String, dynamic>? j) => AccessSchedule(
        windows: ((j?['windows'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => AccessWindow.fromJson(m.cast<String, dynamic>()))
            .toList(),
      );

  static AccessSchedule parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const AccessSchedule();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AccessSchedule.fromJson(decoded);
      }
    } catch (_) {
      // fall through
    }
    return const AccessSchedule();
  }

  String encode() => isEmpty ? '' : jsonEncode(toJson());
}

enum AccessScheduleMode { simple, advanced }

// ───────────────────────────────────────────────────────────────
//  Widget
// ───────────────────────────────────────────────────────────────
class HubAccessSchedule extends StatefulWidget {
  const HubAccessSchedule({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = 'الأيام والأوقات المسموحة',
  });

  final AccessSchedule value;
  final ValueChanged<AccessSchedule> onChanged;
  final String title;

  @override
  State<HubAccessSchedule> createState() => _HubAccessScheduleState();
}

class _HubAccessScheduleState extends State<HubAccessSchedule> {
  late AccessScheduleMode _mode;

  // Simple-mode state.
  late Set<String> _simpleDays;
  late List<AccessWindow> _simpleWindows;

  // Advanced-mode state.
  late Map<String, List<AccessWindow>> _perDay;
  late List<String> _perDayOrder;

  @override
  void initState() {
    super.initState();
    _hydrate(widget.value);
  }

  @override
  void didUpdateWidget(covariant HubAccessSchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.value.encode();
    if (incoming != _currentSchedule().encode()) {
      _hydrate(widget.value);
    }
  }

  void _hydrate(AccessSchedule v) {
    final advanced = _detectAdvanced(v.windows);
    _mode = advanced ? AccessScheduleMode.advanced : AccessScheduleMode.simple;
    if (advanced) {
      _perDay = {};
      _perDayOrder = [];
      for (final w in v.windows) {
        if (w.days.isEmpty) continue;
        final d = w.days.first;
        _perDay.putIfAbsent(d, () {
          _perDayOrder.add(d);
          return [];
        }).add(AccessWindow(from: w.from, to: w.to));
      }
      _simpleDays = {};
      _simpleWindows = [];
    } else {
      _simpleDays = {for (final w in v.windows) ...w.days};
      _simpleWindows = v.windows
          .map((w) => AccessWindow(from: w.from, to: w.to))
          .toList();
      _perDay = {};
      _perDayOrder = [];
    }
  }

  bool _detectAdvanced(List<AccessWindow> wins) {
    if (wins.length <= 1) return false;
    final singles = wins.where((w) => w.days.length == 1).toList();
    if (singles.length != wins.length) return false;
    final distinct = singles.map((w) => w.days.first).toSet();
    return distinct.length > 1;
  }

  AccessSchedule _currentSchedule() {
    if (_mode == AccessScheduleMode.simple) {
      final days = _simpleDays.toList();
      final wins = _simpleWindows
          .where((w) => w.from.isNotEmpty || w.to.isNotEmpty)
          .map(
            (w) => AccessWindow(
              days: List.of(days),
              from: w.from,
              to: w.to,
            ),
          )
          .toList();
      if (wins.isEmpty && days.isNotEmpty) {
        return AccessSchedule(
          windows: [AccessWindow(days: days, from: '', to: '')],
        );
      }
      return AccessSchedule(windows: wins);
    }
    final out = <AccessWindow>[];
    for (final day in _perDayOrder) {
      final list = _perDay[day] ?? const [];
      for (final w in list) {
        out.add(AccessWindow(days: [day], from: w.from, to: w.to));
      }
    }
    return AccessSchedule(windows: out);
  }

  void _emit() => widget.onChanged(_currentSchedule());

  // ── Simple-mode mutators ──────────────────────────────────────
  void _toggleSimpleDay(String code) => setState(() {
        if (_simpleDays.contains(code)) {
          _simpleDays.remove(code);
        } else {
          _simpleDays.add(code);
        }
        _emit();
      });

  void _addSimpleWindow() => setState(() {
        _simpleWindows.add(const AccessWindow());
        _emit();
      });

  void _removeSimpleWindow(int i) => setState(() {
        _simpleWindows.removeAt(i);
        _emit();
      });

  void _updateSimpleWindow(int i, AccessWindow next) => setState(() {
        _simpleWindows[i] = next;
        _emit();
      });

  // ── Advanced-mode mutators ────────────────────────────────────
  void _addPerDay(String code) => setState(() {
        if (_perDay.containsKey(code)) return;
        _perDayOrder.add(code);
        _perDay[code] = [const AccessWindow()];
        _emit();
      });

  void _removePerDay(String code) => setState(() {
        _perDay.remove(code);
        _perDayOrder.remove(code);
        _emit();
      });

  void _addPerDayWindow(String code) => setState(() {
        _perDay[code]?.add(const AccessWindow());
        _emit();
      });

  void _removePerDayWindow(String code, int i) => setState(() {
        _perDay[code]?.removeAt(i);
        _emit();
      });

  void _updatePerDayWindow(String code, int i, AccessWindow next) =>
      setState(() {
        _perDay[code]?[i] = next;
        _emit();
      });

  // ── Mode switch ───────────────────────────────────────────────
  void _switchMode(AccessScheduleMode next) {
    if (next == _mode) return;
    setState(() {
      if (next == AccessScheduleMode.advanced) {
        // simple → advanced: explode chosen days × current windows
        _perDay = {};
        _perDayOrder = [];
        final wins = _simpleWindows.isEmpty
            ? [const AccessWindow()]
            : List<AccessWindow>.from(_simpleWindows);
        for (final d in _simpleDays) {
          _perDayOrder.add(d);
          _perDay[d] = wins
              .map((w) => AccessWindow(from: w.from, to: w.to))
              .toList();
        }
      } else {
        // advanced → simple: union of days + dedupe of (from,to) pairs
        final days = <String>{};
        final pairs = <String>{};
        for (final entry in _perDay.entries) {
          days.add(entry.key);
          for (final w in entry.value) {
            pairs.add('${w.from}|${w.to}');
          }
        }
        _simpleDays = days;
        _simpleWindows = pairs.map((p) {
          final parts = p.split('|');
          return AccessWindow(
            from: parts.isNotEmpty ? parts[0] : '',
            to: parts.length > 1 ? parts[1] : '',
          );
        }).toList();
        if (_simpleWindows.isEmpty) _simpleWindows = [const AccessWindow()];
      }
      _mode = next;
      _emit();
    });
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: p.border),
        boxShadow: p.shCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(title: widget.title, mode: _mode, onChange: _switchMode),
          const SizedBox(height: 18),
          if (_mode == AccessScheduleMode.simple)
            _SimpleBody(
              days: _simpleDays,
              windows: _simpleWindows,
              onToggleDay: _toggleSimpleDay,
              onAddWindow: _addSimpleWindow,
              onRemoveWindow: _removeSimpleWindow,
              onUpdateWindow: _updateSimpleWindow,
            )
          else
            _AdvancedBody(
              perDay: _perDay,
              order: _perDayOrder,
              onAddDay: _addPerDay,
              onRemoveDay: _removePerDay,
              onAddWindow: _addPerDayWindow,
              onRemoveWindow: _removePerDayWindow,
              onUpdateWindow: _updatePerDayWindow,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.mode,
    required this.onChange,
  });

  final String title;
  final AccessScheduleMode mode;
  final ValueChanged<AccessScheduleMode> onChange;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.brandSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 18,
                color: p.brandInk,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: p.textPrimary,
              ),
            ),
          ],
        ),
        _SegmentControl(mode: mode, onChange: onChange),
      ],
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({required this.mode, required this.onChange});

  final AccessScheduleMode mode;
  final ValueChanged<AccessScheduleMode> onChange;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.brandSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segBtn(p, 'بسيط', AccessScheduleMode.simple),
          const SizedBox(width: 2),
          _segBtn(p, 'متقدم', AccessScheduleMode.advanced),
        ],
      ),
    );
  }

  Widget _segBtn(AppPalette p, String label, AccessScheduleMode value) {
    final active = mode == value;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: active ? null : () => onChange(value),
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        curve: AppTokens.motionEase,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: active ? p.card : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? p.brandInk : p.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Simple body
// ───────────────────────────────────────────────────────────────
class _SimpleBody extends StatelessWidget {
  const _SimpleBody({
    required this.days,
    required this.windows,
    required this.onToggleDay,
    required this.onAddWindow,
    required this.onRemoveWindow,
    required this.onUpdateWindow,
  });

  final Set<String> days;
  final List<AccessWindow> windows;
  final ValueChanged<String> onToggleDay;
  final VoidCallback onAddWindow;
  final ValueChanged<int> onRemoveWindow;
  final void Function(int index, AccessWindow next) onUpdateWindow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BlockLabel(
          icon: Icons.calendar_today_outlined,
          label: 'أيام السماح',
          hint: 'اتركيها فاضية = كل الأيام',
        ),
        const SizedBox(height: 10),
        _DayPills(selected: days, onToggle: onToggleDay),
        const SizedBox(height: 18),
        const _BlockLabel(
          icon: Icons.schedule_outlined,
          label: 'الفترات الزمنية',
          hint: 'اتركي الأوقات فاضية = طول اليوم',
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < windows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _WindowCard(
            window: windows[i],
            onChanged: (w) => onUpdateWindow(i, w),
            onRemove: () => onRemoveWindow(i),
          ),
        ],
        if (windows.isNotEmpty) const SizedBox(height: 10),
        _AddWindowButton(onPressed: onAddWindow, label: 'إضافة فترة جديدة'),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Advanced body
// ───────────────────────────────────────────────────────────────
class _AdvancedBody extends StatelessWidget {
  const _AdvancedBody({
    required this.perDay,
    required this.order,
    required this.onAddDay,
    required this.onRemoveDay,
    required this.onAddWindow,
    required this.onRemoveWindow,
    required this.onUpdateWindow,
  });

  final Map<String, List<AccessWindow>> perDay;
  final List<String> order;
  final ValueChanged<String> onAddDay;
  final ValueChanged<String> onRemoveDay;
  final ValueChanged<String> onAddWindow;
  final void Function(String day, int i) onRemoveWindow;
  final void Function(String day, int i, AccessWindow next) onUpdateWindow;

  @override
  Widget build(BuildContext context) {
    final remaining =
        kAccessDays.where((d) => !perDay.containsKey(d)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < order.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _PerDayBlock(
            day: order[i],
            windows: perDay[order[i]] ?? const [],
            onRemoveDay: () => onRemoveDay(order[i]),
            onAddWindow: () => onAddWindow(order[i]),
            onRemoveWindow: (idx) => onRemoveWindow(order[i], idx),
            onUpdateWindow: (idx, w) => onUpdateWindow(order[i], idx, w),
          ),
        ],
        if (order.isNotEmpty) const SizedBox(height: 14),
        if (remaining.isNotEmpty)
          Center(
            child: _AddDayMenu(
              remaining: remaining,
              onPick: onAddDay,
            ),
          ),
      ],
    );
  }
}

class _PerDayBlock extends StatelessWidget {
  const _PerDayBlock({
    required this.day,
    required this.windows,
    required this.onRemoveDay,
    required this.onAddWindow,
    required this.onRemoveWindow,
    required this.onUpdateWindow,
  });

  final String day;
  final List<AccessWindow> windows;
  final VoidCallback onRemoveDay;
  final VoidCallback onAddWindow;
  final ValueChanged<int> onRemoveWindow;
  final void Function(int i, AccessWindow next) onUpdateWindow;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: p.brandGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: p.brand.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  kAccessDayNames[day] ?? day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemoveDay,
                icon: Icon(Icons.close, size: 18, color: p.dangerFg),
                tooltip: 'حذف هذا اليوم',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < windows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _WindowCard(
              window: windows[i],
              onChanged: (w) => onUpdateWindow(i, w),
              onRemove: () => onRemoveWindow(i),
            ),
          ],
          const SizedBox(height: 10),
          _AddWindowButton(
            onPressed: onAddWindow,
            label: 'إضافة فترة لـ ${kAccessDayNames[day] ?? day}',
          ),
        ],
      ),
    );
  }
}

class _AddDayMenu extends StatelessWidget {
  const _AddDayMenu({required this.remaining, required this.onPick});

  final List<String> remaining;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: onPick,
      itemBuilder: (_) => [
        for (final d in remaining)
          PopupMenuItem<String>(
            value: d,
            child: Text(
              kAccessDayNames[d] ?? d,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: p.brandSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: p.brand,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: p.brandInk),
            const SizedBox(width: 8),
            Text(
              'إضافة يوم آخر',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.brandInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Shared sub-widgets
// ───────────────────────────────────────────────────────────────
class _BlockLabel extends StatelessWidget {
  const _BlockLabel({
    required this.icon,
    required this.label,
    required this.hint,
  });

  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: p.brandInk),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          hint,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DayPills extends StatelessWidget {
  const _DayPills({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 360
            ? 3
            : (c.maxWidth < 560 ? 4 : 7);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kAccessDays.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 44,
          ),
          itemBuilder: (_, i) {
            final code = kAccessDays[i];
            return _DayPill(
              code: code,
              on: selected.contains(code),
              onTap: () => onToggle(code),
            );
          },
        );
      },
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.code,
    required this.on,
    required this.onTap,
  });

  final String code;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.motionFast,
        curve: AppTokens.motionEase,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          gradient: on ? p.brandGradient : null,
          color: on ? null : p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? Colors.transparent : p.border,
            width: 1.5,
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: p.brand.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (on) ...[
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                kAccessDayNames[code] ?? code,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : p.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.window,
    required this.onChanged,
    required this.onRemove,
  });

  final AccessWindow window;
  final ValueChanged<AccessWindow> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final duration = _formatDuration(window.from, window.to);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _LabeledTime(
                  label: 'من',
                  value: window.from,
                  onChanged: (v) => onChanged(window.copyWith(from: v)),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_back, size: 18, color: p.brandInk),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledTime(
                  label: 'إلى',
                  value: window.to,
                  onChanged: (v) => onChanged(window.copyWith(to: v)),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.close, size: 16, color: p.dangerFg),
                tooltip: 'حذف الفترة',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                ),
              ),
            ],
          ),
          if (duration.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 12, color: p.brandInk),
                const SizedBox(width: 6),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.brandInk,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledTime extends StatelessWidget {
  const _LabeledTime({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined, size: 10, color: p.brandInk),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        HubTimePickerCircular(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AddWindowButton extends StatelessWidget {
  const _AddWindowButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: p.brand,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 12, color: p.brandInk),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.brandInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
//  Helpers
// ───────────────────────────────────────────────────────────────
String _formatDuration(String from, String to) {
  if (from.isEmpty || to.isEmpty) return '';
  final f = _parseHm(from);
  final t = _parseHm(to);
  if (f == null || t == null) return '';
  var mins = (t.h * 60 + t.m) - (f.h * 60 + f.m);
  if (mins <= 0) mins += 24 * 60;
  if (mins == 24 * 60) return '24 ساعة';
  final h = mins ~/ 60;
  final m = mins % 60;
  if (h > 0 && m > 0) return '$h س $m د';
  if (h > 0) {
    if (h == 1) return 'ساعة';
    if (h == 2) return 'ساعتان';
    return '$h ساعات';
  }
  return '$m دقيقة';
}

({int h, int m})? _parseHm(String s) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s.trim());
  if (match == null) return null;
  return (h: int.parse(match.group(1)!), m: int.parse(match.group(2)!));
}
