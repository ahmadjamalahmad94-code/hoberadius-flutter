import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/cards_list_providers.dart';
import '../../domain/card_model.dart';

class CardsListTotals extends StatelessWidget {
  const CardsListTotals({super.key, required this.totals});
  final CardBatchOperationsTotals totals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 640
                ? 3
                : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: AppTokens.s12,
          mainAxisSpacing: AppTokens.s12,
          childAspectRatio: constraints.maxWidth < 520 ? 2.05 : 2.8,
          children: [
            _StatCard(
              icon: Icons.inventory_2_outlined,
              label: 'الحزم المعروضة',
              value: '${totals.batchCount}',
            ),
            _StatCard(
              icon: Icons.today_outlined,
              label: 'بطاقات اليوم',
              value: '${totals.usedToday}',
              footnote: formatMoney(totals.valueToday),
            ),
            _StatCard(
              icon: Icons.calendar_month_outlined,
              label: 'بطاقات الشهر',
              value: '${totals.usedMonth}',
              footnote: formatMoney(totals.valueMonth),
            ),
            _StatCard(
              icon: Icons.payments_outlined,
              label: 'قيمة تقديرية',
              value: formatMoney(totals.configuredValue),
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
  });

  final IconData icon;
  final String label;
  final String value;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 145;
          final iconWidget = CircleAvatar(
            radius: compact ? 18 : 20,
            backgroundColor: AppTokens.brandSoft,
            child:
                Icon(icon, color: AppTokens.brand, size: compact ? 18 : 20),
          );
          final textWidget = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              if (footnote.isNotEmpty)
                Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 11,
                  ),
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
