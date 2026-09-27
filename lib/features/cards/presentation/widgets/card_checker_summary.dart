import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/card_checker_format.dart';
import '../../domain/card_model.dart';

class CardCheckerSummary extends StatelessWidget {
  const CardCheckerSummary({super.key, required this.card});
  final CardCheckResult card;

  @override
  Widget build(BuildContext context) {
    final summary = card.accountingSummary;
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: cardCheckStatusLabel(card.status),
                tone: cardCheckStatusTone(card.status),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, c) => CountGrid(
              columns: c.maxWidth >= 620 ? 6 : 3,
              items: [
                CountItem(
                  'جلسات نشطة',
                  summary.onlineSessions,
                  tone: summary.onlineSessions > 0
                      ? PillTone.green
                      : PillTone.neutral,
                ),
                CountItem('عدد الجلسات', summary.sessionsCount),
                CountItem(
                  'أجهزة مختلفة',
                  summary.uniqueMacs,
                  tone: PillTone.blue,
                ),
                CountItem.text(
                  'الوقت الكلي',
                  formatCheckDuration(summary.totalSessionSeconds),
                  tone: PillTone.brand,
                ),
                CountItem.text(
                  'تنزيل',
                  _ltr(formatCheckBytes(summary.totalDownloadBytes)),
                ),
                CountItem.text(
                  'رفع',
                  _ltr(formatCheckBytes(summary.totalUploadBytes)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps «12.5 MB» in reading order inside an RTL cell (it rendered «MB 12.5»).
String _ltr(String v) => '\u200E$v';
