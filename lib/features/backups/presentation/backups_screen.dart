import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/backups_repository.dart';
import '../domain/backup_model.dart';

final backupStatusProvider = FutureProvider.autoDispose<BackupStatus>((ref) {
  return ref.watch(backupsRepositoryProvider).status();
});

class BackupsScreen extends ConsumerStatefulWidget {
  const BackupsScreen({super.key});

  @override
  ConsumerState<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends ConsumerState<BackupsScreen> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(backupStatusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'النسخ الاحتياطي',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(backupStatusProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب حالة النسخ',
            subtitle: visibleErrorMessage(e),
          ),
          data: (status) => _Body(
            status: status,
            running: _running,
            onRun: _runBackup,
          ),
        ),
      ],
    );
  }

  Future<void> _runBackup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تشغيل نسخة محلية'),
        content: const Text(
          'سيتم إنشاء نسخة محلية من قاعدة SQLite والتحقق من وجود الملف. تبقى الاستعادة والحذف ضمن إجراءات مستقلة تحتاج تأكيدًا منفصلًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تشغيل'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _running = true);
    try {
      final run = await ref.read(backupsRepositoryProvider).runLocalBackup();
      ref.invalidate(backupStatusProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(run?.message ?? 'تم تشغيل النسخة المحلية')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.status,
    required this.running,
    required this.onRun,
  });

  final BackupStatus status;
  final bool running;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final job = status.job;
    final drive = status.googleDrive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GoogleDriveCard(drive: drive),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 780 ? 3 : 1;
            return GridView.count(
              crossAxisCount: cols,
              crossAxisSpacing: AppTokens.s12,
              mainAxisSpacing: AppTokens.s12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: cols == 1 ? 3.1 : 1.8,
              children: [
                _StatCard(
                  title: 'الحالة الأخيرة',
                  value: job.lastStatus,
                  subtitle: job.lastMessage.isEmpty
                      ? 'لم يتم تشغيل نسخة بعد'
                      : job.lastMessage,
                  icon: Icons.verified_outlined,
                ),
                _StatCard(
                  title: 'آخر تشغيل',
                  value: _fmt(job.lastRunAt),
                  subtitle: 'تحقق من النسخة خارج التطبيق قبل الإنتاج',
                  icon: Icons.schedule,
                ),
                _StatCard(
                  title: 'جوجل درايف',
                  value: _driveStatusLabel(drive),
                  subtitle: drive.messageAr,
                  icon: Icons.cloud_off_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(running ? 'جاري النسخ...' : 'تشغيل نسخة محلية'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('جوجل درايف غير مفعل'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: EdgeInsets.zero,
          child: status.recentRuns.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppTokens.s20),
                  child: EmptyState(
                    icon: Icons.storage_outlined,
                    title: 'لا توجد محاولات نسخ بعد',
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('الحالة')),
                      DataColumn(label: Text('الرسالة')),
                      DataColumn(label: Text('المسار')),
                      DataColumn(label: Text('الوقت')),
                    ],
                    rows: status.recentRuns
                        .map(
                          (run) => DataRow(
                            cells: [
                              DataCell(
                                StatusPill(
                                  text: run.status,
                                  tone: run.status == 'success'
                                      ? PillTone.green
                                      : PillTone.orange,
                                ),
                              ),
                              DataCell(Text(run.message)),
                              DataCell(Text(run.path.isEmpty ? '—' : run.path)),
                              DataCell(Text(_fmt(run.createdAt))),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _GoogleDriveCard extends StatelessWidget {
  const _GoogleDriveCard({required this.drive});

  final BackupGoogleDriveStatus drive;

  @override
  Widget build(BuildContext context) {
    final tone = drive.connected
        ? PillTone.green
        : drive.pending
            ? PillTone.amber
            : PillTone.neutral;
    return AppCard(
      child: Row(
        children: [
          Icon(
            drive.connected
                ? Icons.cloud_done_outlined
                : drive.pending
                    ? Icons.cloud_sync_outlined
                    : Icons.cloud_off_outlined,
            color: drive.connected ? AppTokens.successFg : AppTokens.textMuted,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'حالة جوجل درايف',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    StatusPill(text: _driveStatusLabel(drive), tone: tone),
                  ],
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  drive.messageAr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                        height: 1.6,
                      ),
                ),
                if (drive.email.isNotEmpty || drive.lastUploadAt.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    [
                      if (drive.email.isNotEmpty) 'الحساب: ${drive.email}',
                      if (drive.lastUploadAt.isNotEmpty)
                        'آخر رفع: ${drive.lastUploadAt}',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _driveStatusLabel(BackupGoogleDriveStatus drive) {
  if (drive.connected) return 'مربوط';
  if (drive.pending) return 'بانتظار التحقق';
  if (drive.configured) return 'غير مربوط';
  return 'غير مفعل';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 2,
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

String _fmt(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}
