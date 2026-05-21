import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.username,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              StatusPill(
                text: cardCheckStatusLabel(card.status),
                tone: cardCheckStatusTone(card.status),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                _Metric(
                  icon: Icons.devices_outlined,
                  label: 'أجهزة مختلفة',
                  value: '${summary.uniqueMacs}',
                ),
                _Metric(
                  icon: Icons.history,
                  label: 'عدد الجلسات',
                  value: '${summary.sessionsCount}',
                ),
                _Metric(
                  icon: Icons.wifi_tethering,
                  label: 'جلسات نشطة',
                  value: '${summary.onlineSessions}',
                ),
                _Metric(
                  icon: Icons.timer_outlined,
                  label: 'الوقت الكلي',
                  value: formatCheckDuration(summary.totalSessionSeconds),
                ),
                _Metric(
                  icon: Icons.cloud_upload_outlined,
                  label: 'رفع',
                  value: formatCheckBytes(summary.totalUploadBytes),
                ),
                _Metric(
                  icon: Icons.cloud_download_outlined,
                  label: 'تنزيل',
                  value: formatCheckBytes(summary.totalDownloadBytes),
                ),
              ];
              final cols = constraints.maxWidth >= 780 ? 3 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: AppTokens.s8,
                crossAxisSpacing: AppTokens.s8,
                childAspectRatio: constraints.maxWidth < 520 ? 2.0 : 2.5,
                children: items,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.borderNeutral),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTokens.brand, size: 20),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 11,
                    height: 1.15,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
