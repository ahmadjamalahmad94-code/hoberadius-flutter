import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
            onConnectDrive: _connectDrive,
          ),
        ),
      ],
    );
  }

  Future<void> _connectDrive() async {
    final repo = ref.read(backupsRepositoryProvider);
    Map<String, dynamic> info;
    try {
      info = await repo.connectGoogleDrive();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
      return;
    }
    if (!mounted) return;
    final code = (info['user_code'] ?? '').toString();
    final url = (info['verification_url'] ?? '').toString();
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DriveConnectDialog(
        userCode: code,
        verificationUrl: url,
        onPoll: () => repo.pollGoogleDrive(),
      ),
    );
    if (done == true && mounted) {
      ref.invalidate(backupStatusProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ربط جوجل درايف')),
      );
    }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
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
    required this.onConnectDrive,
  });

  final BackupStatus status;
  final bool running;
  final VoidCallback onRun;
  final VoidCallback onConnectDrive;

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
              childAspectRatio: cols == 1 ? 2.3 : 1.4,
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
                onPressed: status.googleDrive.connected ? null : onConnectDrive,
                icon: const Icon(Icons.cloud_sync_outlined),
                label: Text(
                  status.googleDrive.connected
                      ? 'جوجل درايف مربوط'
                      : 'ربط جوجل درايف',
                ),
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
                                  text: run.statusLabel,
                                  tone: _backupRunTone(run.status),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                if (drive.email.isNotEmpty ||
                    drive.lastUploadAt.isNotEmpty) ...[
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

PillTone _backupRunTone(String status) => switch (status) {
      'success' => PillTone.green,
      'failed' => PillTone.red,
      'running' || 'pending' => PillTone.amber,
      _ => PillTone.neutral,
    };

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

/// Google Drive limited-input device-flow dialog: shows the user_code +
/// verification URL, and polls until the operator authorises (or cancels).
class _DriveConnectDialog extends StatefulWidget {
  const _DriveConnectDialog({
    required this.userCode,
    required this.verificationUrl,
    required this.onPoll,
  });

  final String userCode;
  final String verificationUrl;
  final Future<Map<String, dynamic>> Function() onPoll;

  @override
  State<_DriveConnectDialog> createState() => _DriveConnectDialogState();
}

class _DriveConnectDialogState extends State<_DriveConnectDialog> {
  bool _polling = false;
  String _message = '';

  Future<void> _poll() async {
    setState(() {
      _polling = true;
      _message = '';
    });
    try {
      final res = await widget.onPoll();
      if (res['connected'] == true) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      setState(
        () => _message = (res['pending'] == true)
            ? 'بانتظار موافقتك على جوجل... أكمل في المتصفح ثم تحقق مجددًا.'
            : (res['detail'] ?? 'لم يكتمل الربط بعد.').toString(),
      );
    } catch (e) {
      setState(() => _message = visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _polling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ربط جوجل درايف'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'افتح الرابط التالي على أي جهاز وأدخل الرمز للموافقة، ثم اضغط '
              '«تحقّق من الربط».',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: AppTokens.s12),
            _CopyRow(label: 'الرابط', value: widget.verificationUrl),
            const SizedBox(height: AppTokens.s8),
            _CopyRow(label: 'الرمز', value: widget.userCode),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s12),
              Text(
                _message,
                style: const TextStyle(color: AppTokens.textSecondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _polling ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _polling ? null : _poll,
          icon: _polling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_outlined),
          label: const Text('تحقّق من الربط'),
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AppTokens.textMuted)),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '—' : value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
