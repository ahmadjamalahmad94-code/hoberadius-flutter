import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/card_checker_format.dart';
import '../../domain/card_model.dart';

class CardCheckerMacsCard extends StatelessWidget {
  const CardCheckerMacsCard({super.key, required this.summary});
  final CardAccountingSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.macs.isEmpty) {
      return const AppCard(
        title: 'الأجهزة التي استخدمت البطاقة',
        icon: Icons.devices_outlined,
        child: Text(
          'لا توجد أجهزة مسجلة بعد. ستظهر هنا بعد أول اتصال فعلي.',
          style: TextStyle(color: AppTokens.textMuted),
        ),
      );
    }
    return AppCard(
      title: 'الأجهزة التي استخدمت البطاقة',
      icon: Icons.devices_outlined,
      child: Column(
        children: [
          for (final mac in summary.macs)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.devices, color: AppTokens.brand),
              title: Text(
                mac.mac,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: Text(
                'جلسات: ${mac.sessionsCount} • نشطة: ${mac.onlineSessions}'
                ' • آخر ظهور: ${formatCheckDate(mac.lastSeenAt)}',
              ),
            ),
        ],
      ),
    );
  }
}

class CardCheckerSessionsCard extends StatelessWidget {
  const CardCheckerSessionsCard({super.key, required this.sessions});
  final List<CardSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const AppCard(
        title: 'جلسات البطاقة',
        icon: Icons.table_rows_outlined,
        child: Text(
          'لا توجد جلسات محفوظة لهذه البطاقة بعد.',
          style: TextStyle(color: AppTokens.textMuted),
        ),
      );
    }
    return AppCard(
      title: 'جلسات البطاقة',
      icon: Icons.table_rows_outlined,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = sessions[index];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s16,
              vertical: AppTokens.s8,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    s.sessionId.isEmpty
                        ? 'جلسة #${s.id ?? '-'}'
                        : s.sessionId,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusPill(
                  text: s.online ? 'متصل' : 'منتهية',
                  tone: s.online ? PillTone.green : PillTone.neutral,
                ),
              ],
            ),
            subtitle: Wrap(
              spacing: AppTokens.s12,
              runSpacing: 4,
              children: [
                _Tiny(
                  icon: Icons.play_circle_outline,
                  text: formatCheckDate(s.startedAt),
                ),
                _Tiny(
                  icon: Icons.stop_circle_outlined,
                  text: formatCheckDate(s.stoppedAt),
                ),
                _Tiny(
                  icon: Icons.timer_outlined,
                  text: formatCheckDuration(s.durationSeconds),
                ),
                if (s.macAddress != null)
                  _Tiny(icon: Icons.devices, text: s.macAddress!),
                if (s.ipAddress != null)
                  _Tiny(icon: Icons.dns, text: s.ipAddress!),
                if (s.nasAddress != null)
                  _Tiny(icon: Icons.router_outlined, text: s.nasAddress!),
                _Tiny(
                  icon: Icons.cloud_upload_outlined,
                  text: formatCheckBytes(s.uploadBytes),
                ),
                _Tiny(
                  icon: Icons.cloud_download_outlined,
                  text: formatCheckBytes(s.downloadBytes),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tiny extends StatelessWidget {
  const _Tiny({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTokens.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style:
              const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
