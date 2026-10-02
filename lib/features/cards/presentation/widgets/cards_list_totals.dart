import 'package:flutter/material.dart';

import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/auto_height_grid.dart';
import '../../application/cards_list_providers.dart';
import '../../domain/card_model.dart';

class CardsListTotals extends StatelessWidget {
  const CardsListTotals({
    super.key,
    required this.totals,
    this.onPickDay,
    this.onPickMonth,
    this.onPickRange,
  });
  final CardBatchOperationsTotals totals;

  /// Owner 2026-10-02: «بطاقات اليوم/الشهر» for ANY day / month — tapping the
  /// tile opens a picker; the value is YYYY-MM-DD / YYYY-MM.
  final ValueChanged<String>? onPickDay;
  final ValueChanged<String>? onPickMonth;

  /// «المبيعات» period: (from, to) as YYYY-MM-DD, both inclusive.
  final void Function(String from, String to)? onPickRange;

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _rangeLabel() {
    final now = DateTime.now();
    final today = _ymd(now);
    final from = totals.rangeFrom;
    final to = totals.rangeTo;
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    if (from.isEmpty || (from == monthStart && (to.isEmpty || to == today))) {
      return 'مبيعات هذا الشهر';
    }
    if (from == today && to == today) return 'مبيعات اليوم';
    final weekStart = _ymd(now.subtract(Duration(days: (now.weekday + 1) % 7)));
    if (from == weekStart && to == today) return 'مبيعات هذا الأسبوع';
    if (from == to) return 'مبيعات $from';
    return 'مبيعات ${from.substring(5)} ← ${to.isEmpty ? '…' : to.substring(5)}';
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final today = _ymd(now);
    // the week starts on Saturday (Palestine)
    final weekStart = _ymd(now.subtract(Duration(days: (now.weekday + 1) % 7)));
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final choice = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, label, icon) in const [
              ('day', 'اليوم', Icons.today_outlined),
              ('week', 'هذا الأسبوع', Icons.view_week_outlined),
              ('month', 'هذا الشهر', Icons.calendar_month_outlined),
              ('custom', 'فترة من – إلى…', Icons.date_range_outlined),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(ctx, key),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'day':
        onPickRange?.call(today, today);
      case 'week':
        onPickRange?.call(weekStart, today);
      case 'month':
        onPickRange?.call(monthStart, today);
      case 'custom':
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
          initialDateRange: DateTimeRange(
            start: DateTime.tryParse(totals.rangeFrom) ??
                DateTime(now.year, now.month),
            end: DateTime.tryParse(totals.rangeTo) ?? now,
          ),
          helpText: 'اختر الفترة',
        );
        if (picked != null) {
          onPickRange?.call(_ymd(picked.start), _ymd(picked.end));
        }
    }
  }

  static const _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  String _dayLabel() {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (totals.day.isEmpty || totals.day == today) return 'بطاقات اليوم';
    return 'بطاقات ${totals.day}';
  }

  String _monthLabel() {
    final now = DateTime.now();
    final cur = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (totals.month.isEmpty || totals.month == cur) return 'بطاقات الشهر';
    final m = int.tryParse(totals.month.substring(5)) ?? 0;
    final name = (m >= 1 && m <= 12) ? _months[m - 1] : totals.month;
    return 'بطاقات $name ${totals.month.substring(0, 4)}';
  }

  Future<void> _pickDay(BuildContext context) async {
    final initial = DateTime.tryParse(totals.day) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'اختر اليوم',
    );
    if (picked == null) return;
    onPickDay?.call(
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    var year = int.tryParse(
          totals.month.isNotEmpty ? totals.month.substring(0, 4) : '',
        ) ??
        now.year;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('اختر الشهر')),
              IconButton(
                tooltip: 'السنة السابقة',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => year--),
              ),
              Text(
                '$year',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: 'السنة التالية',
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    year >= now.year ? null : () => setState(() => year++),
              ),
            ],
          ),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var m = 1; m <= 12; m++)
                ChoiceChip(
                  label: Text(_months[m - 1]),
                  selected:
                      totals.month == '$year-${m.toString().padLeft(2, '0')}',
                  onSelected: (year == now.year && m > now.month)
                      ? null
                      : (_) => Navigator.pop(
                            ctx,
                            '$year-${m.toString().padLeft(2, '0')}',
                          ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
    if (picked != null) onPickMonth?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cur = TenantCurrencyScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 640
                ? 3
                : 2;
        // Tile width decides the compact (stacked) layout; the tile height
        // then follows its content (the fixed aspect ratio overflowed the
        // stacked tiles by 33–51 px at 360×640).
        final tileWidth =
            (constraints.maxWidth - AppTokens.s12 * (cols - 1)) / cols;
        final compact = tileWidth - 28 < 145;
        return AutoHeightGrid(
          columns: cols,
          spacing: AppTokens.s12,
          children: [
            _StatCard(
              compact: compact,
              icon: Icons.inventory_2_outlined,
              label: 'الحزم المعروضة',
              value: '${totals.batchCount}',
              primary: true,
            ),
            _StatCard(
              compact: compact,
              icon: Icons.today_outlined,
              label: _dayLabel(),
              value: '${totals.usedToday}',
              footnote: formatMoney(totals.valueToday, cur),
              onTap: onPickDay == null ? null : () => _pickDay(context),
            ),
            _StatCard(
              compact: compact,
              icon: Icons.calendar_month_outlined,
              label: _monthLabel(),
              value: '${totals.usedMonth}',
              footnote: formatMoney(totals.valueMonth, cur),
              onTap: onPickMonth == null ? null : () => _pickMonth(context),
            ),
            // Owner 2026-10-02: sales for a period he picks (day / week /
            // month / from–to) instead of one fixed «all cards» value.
            // Older servers (no used_range) keep the old total tile.
            if (totals.usedRange != null)
              _StatCard(
                compact: compact,
                icon: Icons.payments_outlined,
                label: _rangeLabel(),
                value: formatMoney(totals.valueRange ?? 0, cur),
                footnote: '${totals.usedRange} بطاقة',
                onTap: onPickRange == null ? null : () => _pickRange(context),
              )
            else
              _StatCard(
                compact: compact,
                icon: Icons.payments_outlined,
                label: 'قيمة كل كروت الحزم',
                value: formatMoney(totals.configuredValue, cur),
                footnote: 'بسعر البيع، المباع وغير المباع',
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.footnote = '',
    this.primary = false,
    this.compact = false,
    this.onTap,
  });

  final bool compact;

  /// Tappable tile (day / month picker) — shows a small calendar hint.
  final VoidCallback? onTap;

  final IconData icon;
  final String label;
  final String value;
  final String footnote;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final mutedColor =
        primary ? Colors.white.withValues(alpha: 0.85) : p.textMuted;
    final valueColor = primary ? Colors.white : p.textPrimary;
    final tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary ? null : p.card,
        gradient: primary ? p.brandGradient : null,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: primary ? null : Border.all(color: p.border),
        boxShadow: primary
            ? [
                BoxShadow(
                  color: p.brand.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : p.shCard,
      ),
      child: Builder(
        builder: (context) {
          final iconWidget = CircleAvatar(
            radius: compact ? 18 : 20,
            backgroundColor:
                primary ? Colors.white.withValues(alpha: 0.18) : p.brandSoft,
            child: Icon(
              icon,
              color: primary ? Colors.white : p.brand,
              size: compact ? 18 : 20,
            ),
          );
          final textWidget = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
              // Never cut a number: shrink to fit instead of «...».
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              if (footnote.isNotEmpty)
                Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: mutedColor, fontSize: 11),
                ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconWidget,
                const SizedBox(height: AppTokens.s8),
                textWidget,
              ],
            );
          }
          return Row(
            children: [
              iconWidget,
              const SizedBox(width: AppTokens.s12),
              Expanded(child: textWidget),
            ],
          );
        },
      ),
    );
    if (onTap == null) return tile;
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r14),
            onTap: onTap,
            child: tile,
          ),
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: IgnorePointer(
            child: Icon(
              Icons.edit_calendar_outlined,
              size: 16,
              color: AppPalette.of(context).brand,
            ),
          ),
        ),
      ],
    );
  }
}
