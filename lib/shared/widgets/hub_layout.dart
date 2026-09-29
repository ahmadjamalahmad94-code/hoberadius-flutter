import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'status_pill.dart';

/// One counter in a [CountGrid].
class CountItem {
  const CountItem(
    this.label,
    this.value, {
    this.tone = PillTone.neutral,
    this.hideWhenZero = false,
    this.onTap,
  }) : display = null;

  /// A counter whose value is already formatted text (money «ILS 12.50»,
  /// durations «3 ي 4 س», sizes «1.2 GB»). Long values shrink to fit.
  const CountItem.text(
    this.label,
    String text, {
    this.tone = PillTone.neutral,
    this.onTap,
  })  : value = 0,
        display = text,
        hideWhenZero = false;

  final String label;
  final int value;
  final String? display;

  /// Optional: open the page behind this counter.
  final VoidCallback? onTap;

  /// Colour meaning — see [toneForStatus].
  final PillTone tone;

  /// Secondary counters (archive, pending…) only show when non-zero, so the
  /// grid stays tight instead of listing a row of zeros.
  final bool hideWhenZero;
}

/// Tight, colour-coded counter grid: equal-width cells in fixed columns,
/// value on top (bold, tone colour) and label under it. Replaces ragged grey
/// «label value» pills whose widths followed their text.
class CountGrid extends StatelessWidget {
  const CountGrid({super.key, required this.items, this.columns = 3});
  final List<CountItem> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final i in items)
        if (!(i.hideWhenZero && i.value == 0)) i,
    ];
    if (visible.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (var i = 0; i < visible.length; i += columns) {
      final slice = visible.sublist(
        i,
        i + columns > visible.length ? visible.length : i + columns,
      );
      rows.add(
        Row(
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: AppTokens.s8),
              Expanded(
                child: j < slice.length
                    ? _CountCell(item: slice[j])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.s8),
          rows[i],
        ],
      ],
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({required this.item});
  final CountItem item;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = pillToneColors(item.tone);
    final cell = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.s8 + 2),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.display ?? '${item.value}',
              maxLines: 1,
              style: TextStyle(
                color: fg,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (item.onTap == null) return cell;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.s8 + 2),
        onTap: item.onTap,
        child: cell,
      ),
    );
  }
}

/// One button in an [ActionBar].
class ActionItem {
  const ActionItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.tone,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Filled brand button (the main action of the bar).
  final bool primary;

  /// Optional colour for a secondary action (e.g. red for a destructive one).
  final PillTone? tone;
}

/// Buttons spread evenly across the full width — equal widths, one height,
/// wrapping into rows of [maxPerRow] — instead of a ragged cluster hugging one
/// edge. Secondary buttons are tinted with a border so they stand out from a
/// white card; the primary one is filled.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.items, this.maxPerRow = 3});
  final List<ActionItem> items;
  final int maxPerRow;

  /// Narrowest a button may get before its label is cut (icon + a short
  /// Arabic word or «Excel»). Below it the bar uses fewer per row.
  static const double minButtonWidth = 88;

  /// Buttons per row for [count] items in [width]: at most [maxPerRow], never
  /// narrower than [minButtonWidth], and balanced (4 → 2+2, not 3+1).
  static int perRowFor(int count, double width, int maxPerRow) {
    if (count <= 0) return 1;
    var fit = maxPerRow;
    if (width.isFinite) {
      fit = ((width + AppTokens.s8) / (minButtonWidth + AppTokens.s8)).floor();
    }
    final cap = fit.clamp(1, maxPerRow.clamp(1, count));
    final rows = (count / cap).ceil();
    return (count / rows).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => _buildRows(
        perRowFor(items.length, constraints.maxWidth, maxPerRow),
      ),
    );
  }

  Widget _buildRows(int perRow) {
    final rows = <List<ActionItem>>[];
    for (var i = 0; i < items.length; i += perRow) {
      rows.add(
        items.sublist(
          i,
          i + perRow > items.length ? items.length : i + perRow,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: AppTokens.s8),
          Row(
            children: [
              for (var i = 0; i < rows[r].length; i++) ...[
                if (i > 0) const SizedBox(width: AppTokens.s8),
                Expanded(child: HubActionButton(item: rows[r][i])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// A single [ActionItem] rendered with the bar's shared style (usable alone).
class HubActionButton extends StatelessWidget {
  const HubActionButton({super.key, required this.item});
  final ActionItem item;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.s8 + 4),
    );
    const size = Size.fromHeight(44);
    const pad = EdgeInsets.symmetric(horizontal: AppTokens.s8);
    // Shrinks rather than cuts: «…Ex» for «Excel» at 360 px (R11 L-5).
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(item.label, maxLines: 1, softWrap: false),
    );
    // Build from the theme's text style so the app font (Cairo) is kept — a
    // raw TextStyle here replaced the theme's and fell back to the device font.
    final textStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(fontWeight: FontWeight.w800);
    if (item.primary) {
      return FilledButton.icon(
        onPressed: item.onPressed,
        icon: Icon(item.icon, size: 18),
        label: label,
        style: FilledButton.styleFrom(
          backgroundColor: AppTokens.brand,
          foregroundColor: Colors.white,
          minimumSize: size,
          padding: pad,
          shape: shape,
          textStyle: textStyle,
        ),
      );
    }
    final (bg, fg, border) = pillToneColors(item.tone ?? PillTone.brand);
    return OutlinedButton.icon(
      onPressed: item.onPressed,
      icon: Icon(item.icon, size: 18),
      label: label,
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        side: BorderSide(color: border),
        minimumSize: size,
        padding: pad,
        shape: shape,
        textStyle: textStyle,
      ),
    );
  }
}

/// One value in an [InfoGrid] (a measurement or detail, not a status count).
class InfoItem {
  const InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

/// Even grid of detail values (duration, download, upload, IP, MAC…): equal
/// cells, icon + small label + value, one row height — instead of chips whose
/// widths follow their text and wrap unevenly.
class InfoGrid extends StatelessWidget {
  const InfoGrid({super.key, required this.items, this.columns = 3});
  final List<InfoItem> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      final slice = items.sublist(
        i,
        i + columns > items.length ? items.length : i + columns,
      );
      rows.add(
        Row(
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: AppTokens.s8),
              Expanded(
                child: j < slice.length
                    ? _InfoCell(item: slice[j])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.s8),
          rows[i],
        ],
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.item});
  final InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s8,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.slate100,
        borderRadius: BorderRadius.circular(AppTokens.s8 + 2),
        border: Border.all(color: AppTokens.slate200.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 13, color: AppTokens.slate500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Shrinks a long value instead of cutting it («12 دقيقة 28 ثا…»).
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              item.value,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                color: AppTokens.sidebarBg,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
