import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/sessions_repository.dart';
import '../domain/session_model.dart';

class SessionsListScreen extends ConsumerWidget {
  const SessionsListScreen({super.key});

  String _formatBytes(int b) {
    if (b <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double v = b.toDouble();
    int i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[i]}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes.remainder(60)}د';
    if (d.inMinutes > 0) return '${d.inMinutes}د ${d.inSeconds.remainder(60)}ث';
    return '${d.inSeconds}ث';
  }

  Future<void> _disconnect(
    BuildContext context,
    WidgetRef ref,
    OnlineSession s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('قطع الجلسة'),
        content: Text('سيتمّ قطع جلسة "${s.username}". متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('قطع'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(sessionsRepositoryProvider).disconnect(
            username: s.username,
            sessionId: s.sessionId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('طُلِب قطع جلسة ${s.username}')),
      );
      ref.invalidate(onlineSessionsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر القطع: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(onlineSessionsProvider);
    final df = DateFormat('HH:mm:ss');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'الجلسات الحيّة',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTokens.navy900,
                  ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(onlineSessionsProvider),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذّر جلب الجلسات',
            subtitle: '$e',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(onlineSessionsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.signal_wifi_off_outlined,
                title: 'لا يوجد متّصلون الآن',
                subtitle: 'الجلسات النشطة ستظهر هنا فور بدء الاتصال.',
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final s = items[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTokens.cyan100,
                      child: Icon(Icons.signal_wifi_4_bar,
                          color: AppTokens.cyan500,),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.username,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const StatusPill(text: 'متّصل', tone: PillTone.green),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (s.framedIpAddress.isNotEmpty)
                            _MetaRow(icon: Icons.dns, text: s.framedIpAddress),
                          if (s.callingStationId.isNotEmpty)
                            _MetaRow(icon: Icons.devices, text: s.callingStationId),
                          if (s.nasIpAddress.isNotEmpty)
                            _MetaRow(icon: Icons.router, text: s.nasIpAddress),
                          _MetaRow(
                            icon: Icons.access_time,
                            text: _formatDuration(s.sessionTime),
                          ),
                          _MetaRow(
                            icon: Icons.cloud_download,
                            text: _formatBytes(s.bytesIn),
                          ),
                          _MetaRow(
                            icon: Icons.cloud_upload,
                            text: _formatBytes(s.bytesOut),
                          ),
                          if (s.startedAt != null)
                            _MetaRow(
                              icon: Icons.play_circle_outline,
                              text: df.format(s.startedAt!.toLocal()),
                            ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'قطع',
                      icon: const Icon(Icons.power_settings_new,
                          color: AppTokens.red,),
                      onPressed: () => _disconnect(ctx, ref, s),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
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
          style: const TextStyle(color: AppTokens.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
