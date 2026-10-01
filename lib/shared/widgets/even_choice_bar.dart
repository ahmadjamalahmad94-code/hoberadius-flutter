import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// How the user reached the network — the `access=` filter of
/// `/sessions/online` and `/accounts`.
enum AccessKind { all, hotspot, broadband }

extension AccessKindApi on AccessKind {
  /// Query value; null = no filter (the param is not sent).
  String? get apiValue => switch (this) {
        AccessKind.all => null,
        AccessKind.hotspot => 'hotspot',
        AccessKind.broadband => 'broadband',
      };

  String get label => switch (this) {
        AccessKind.all => 'الكل',
        AccessKind.hotspot => 'هوت سبوت',
        AccessKind.broadband => 'برود باند',
      };
}

/// Reads the server's `accesses` counters ({hotspot: n, broadband: n}).
Map<String, int>? readAccessCounts(Object? raw) {
  if (raw is! Map) return null;
  return raw.map(
    (k, v) => MapEntry(
      k.toString(),
      v is num ? v.toInt() : int.tryParse('$v') ?? 0,
    ),
  );
}

/// One option of an [EvenChoiceBar].
class EvenChoice<T> {
  const EvenChoice(this.value, this.label, {this.dot, this.count});
  final T value;
  final String label;

  /// Optional colour dot before the label (ties a status filter to its pill).
  final Color? dot;

  /// Optional counter shown after the label.
  final int? count;
}

/// Filter chips laid out in EVEN rows: every cell of a row has the same
/// width and the rows fill the whole width — no ragged Wrap with uneven gaps
/// and nothing hidden off-screen. Rows are balanced (7 → 4 + 3, not 6 + 1).
class EvenChoiceBar<T> extends StatelessWidget {
  const EvenChoiceBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.minCellWidth = 72,
  });

  final List<EvenChoice<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double minCellWidth;

  static const double _gap = 6;

  /// Cells per row for [count] options in [width] (balanced rows).
  static int perRowFor(int count, double width, double minCell) {
    if (count <= 0) return 1;
    var fit = count;
    if (width.isFinite) {
      fit = ((width + _gap) / (minCell + _gap)).floor().clamp(1, count);
    }
    final rows = (count / fit).ceil();
    return (count / rows).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow =
            perRowFor(options.length, constraints.maxWidth, minCellWidth);
        final rows = <Widget>[];
        for (var i = 0; i < options.length; i += perRow) {
          final end = i + perRow > options.length ? options.length : i + perRow;
          final slice = options.sublist(i, end);
          if (rows.isNotEmpty) rows.add(const SizedBox(height: _gap));
          rows.add(
            Row(
              children: [
                for (var j = 0; j < slice.length; j++) ...[
                  if (j > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: _ChoiceCell<T>(
                      option: slice[j],
                      selected: slice[j].value == selected,
                      onTap: () => onChanged(slice[j].value),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}

class _ChoiceCell<T> extends StatelessWidget {
  const _ChoiceCell({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final EvenChoice<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppTokens.brandInk : AppTokens.textSecondary;
    final count = option.count;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppTokens.brandSoft : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppTokens.brand3 : AppTokens.borderStrong,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                // Shrinks a long label («ينتهي خلال 3 أيام») instead of
                // cutting it in a narrow cell.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (option.dot != null) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: option.dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        option.label,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: fg,
                          fontSize: 12.5,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                      if (count != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            color: selected
                                ? AppTokens.brandInk
                                : AppTokens.slate500,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «الكل · هوت سبوت · برود باند» — one even row. Counts appear when the
/// server sends `accesses` (older servers do not: labels only).
class AccessFilterBar extends StatelessWidget {
  const AccessFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.counts,
  });

  final AccessKind value;
  final ValueChanged<AccessKind> onChanged;
  final Map<String, int>? counts;

  @override
  Widget build(BuildContext context) {
    final c = counts;
    return EvenChoiceBar<AccessKind>(
      key: const ValueKey('access-filter'),
      selected: value,
      onChanged: onChanged,
      options: [
        for (final kind in AccessKind.values)
          EvenChoice(
            kind,
            kind.label,
            count: kind.apiValue == null ? null : c?[kind.apiValue],
          ),
      ],
    );
  }
}
