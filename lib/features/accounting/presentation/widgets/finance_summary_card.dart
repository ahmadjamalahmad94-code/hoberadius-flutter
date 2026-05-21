import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/accounting_model.dart';

/// Top-of-screen summary card for the finance view — sums payments,
/// loans (open vs settled), and a net "balance to the operator"
/// figure. Pure presentation; data flows in pre-computed.
class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    super.key,
    required this.payments,
    required this.loans,
    required this.currency,
  });

  final List<PaymentTransaction> payments;
  final List<LoanEntry> loans;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final paidTotal = payments
        .where((p) => p.status != 'voided')
        .fold<num>(0, (sum, p) => sum + p.amount);
    final openLoans = loans.where((l) => l.status == 'open').toList();
    final openLoansTotal = openLoans.fold<num>(0, (s, l) => s + l.amount);
    final settledLoansTotal = loans
        .where((l) => l.status != 'open')
        .fold<num>(0, (s, l) => s + l.amount);
    final net = paidTotal - openLoansTotal;
    final cur = currency.isEmpty ? '' : ' $currency';

    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        gradient: p.brandGradient,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        boxShadow: [
          BoxShadow(
            color: p.brand.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final tiles = [
            _SummaryTile(
              label: 'مدفوعات',
              value: '${paidTotal.toStringAsFixed(2)}$cur',
              icon: Icons.payments_outlined,
            ),
            _SummaryTile(
              label: 'سلف مفتوحة (${openLoans.length})',
              value: '${openLoansTotal.toStringAsFixed(2)}$cur',
              icon: Icons.handshake_outlined,
            ),
            _SummaryTile(
              label: 'سلف مسوّاة',
              value: '${settledLoansTotal.toStringAsFixed(2)}$cur',
              icon: Icons.check_circle_outline,
            ),
            _SummaryTile(
              label: 'الصافي',
              value: '${net.toStringAsFixed(2)}$cur',
              icon: Icons.account_balance_outlined,
              highlight: true,
            ),
          ];
          final cols = c.maxWidth >= 720 ? 4 : (c.maxWidth >= 420 ? 2 : 1);
          return Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s12,
            children: [
              for (final tile in tiles)
                SizedBox(
                  width: (c.maxWidth - (cols - 1) * AppTokens.s12) / cols,
                  child: tile,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.kpi.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
