import 'package:flutter/material.dart';

import '../../../../core/format/currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/auto_height_grid.dart';
import '../../application/cards_list_providers.dart';
import '../../domain/card_model.dart';

class CardsListTotals extends StatelessWidget {
  const CardsListTotals({super.key, required this.totals});
  final CardBatchOperationsTotals totals;

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
              label: 'بطاقات اليوم',
              value: '${totals.usedToday}',
              footnote: formatMoney(totals.valueToday, cur),
            ),
            _StatCard(
              compact: compact,
              icon: Icons.calendar_month_outlined,
              label: 'بطاقات الشهر',
              value: '${totals.usedMonth}',
              footnote: formatMoney(totals.valueMonth, cur),
            ),
            _StatCard(
              compact: compact,
              icon: Icons.payments_outlined,
              label: 'قيمة تقديرية',
              value: formatMoney(totals.configuredValue, cur),
              footnote: 'ليست تقريرًا ماليًا',
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
  });

  final bool compact;

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
    return Container(
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
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
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
  }
}
