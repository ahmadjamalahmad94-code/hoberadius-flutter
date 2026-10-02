import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/format/server_time.dart';

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
            onConnectDrive: _openDrivePortal,
          ),
        ),
      ],
    );
  }

  /// Drive is linked in the customer portal, exactly like the web button:
  /// ask the server for the SSO link and hand it to the operator.
  Future<void> _openDrivePortal() async {
    String url;
    try {
      url = await ref.read(backupsRepositoryProvider).drivePortalLink();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
      return;
    }
    if (!mounted) return;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح بوابة العميل: لم يصل رابط الدخول.'),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => _DrivePortalDialog(url: url),
    );
    ref.invalidate(backupStatusProvider);
  }

  Future<void> _runBackup() async {
    final full = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _RunBackupDialog(),
    );
    if (full == null) return;
    setState(() => _running = true);
    try {
      final result =
          await ref.read(backupsRepositoryProvider).runAll(full: full);
      ref.invalidate(backupStatusProvider);
      if (!mounted) return;
      setState(() => _running = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => _RunStepsDialog(result: result),
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

/// The web run-all confirmation: lean core copy (default) or a full archive.
class _RunBackupDialog extends StatefulWidget {
  const _RunBackupDialog();

  @override
  State<_RunBackupDialog> createState() => _RunBackupDialogState();
}

class _RunBackupDialogState extends State<_RunBackupDialog> {
  bool _full = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تشغيل نسخة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'نسخة محلية مُتحقَّق منها، ثم رفعها إلى لوحة التراخيص (إن كانت '
            'الخدمة مفعّلة) ومنها إلى جوجل درايف المربوط — كزر الويب.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: AppTokens.s8),
          SwitchListTile(
            key: const Key('backup-full-mode'),
            contentPadding: EdgeInsets.zero,
            value: _full,
            onChanged: (v) => setState(() => _full = v),
            title: const Text('أرشيف كامل (يشمل السجلّات)'),
            subtitle: const Text(
              'أكبر حجمًا؛ الافتراضي نسخة أساسية لبيانات العمل.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          key: const Key('backup-run-confirm'),
          onPressed: () => Navigator.pop(context, _full),
          child: const Text('تشغيل'),
        ),
      ],
    );
  }
}

/// The run-all steps (local / panel / drive), each with its own outcome.
class _RunStepsDialog extends StatelessWidget {
  const _RunStepsDialog({required this.result});

  final BackupRunAllResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(result.ok ? 'تمت النسخة' : 'تعذّرت النسخة'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final step in result.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      text: step.statusLabel,
                      tone: _backupRunTone(step.status),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: Text(
                        step.message.isEmpty
                            ? step.label
                            : '${step.label}: ${step.message}',
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تم'),
        ),
      ],
    );
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
                  value: job.statusText,
                  subtitle: serverTextOrFallback(
                    job.lastMessage,
                    fallback: job.lastRunAt == null
                        ? 'لم يتم تشغيل نسخة بعد'
                        : job.statusText,
                  ),
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
                label: Text(running ? 'جاري النسخ...' : 'تشغيل نسخة'),
              ),
              // Like the web: linking and managing Drive both happen in the
              // customer portal (SSO link) — never a dead button.
              OutlinedButton.icon(
                onPressed: onConnectDrive,
                icon: const Icon(Icons.cloud_sync_outlined),
                label: Text(
                  status.googleDrive.connected
                      ? 'إدارة الربط من بوابة العميل'
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
                              DataCell(
                                Text(
                                  serverTextOrFallback(
                                    run.message,
                                    fallback: run.statusLabel,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  run.path.isEmpty ? '—' : ltrIsolate(run.path),
                                ),
                              ),
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
                        'آخر رفع: ${_fmtRaw(drive.lastUploadAt)}',
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

/// A timestamp the model keeps as a string (`last_upload_at`), on the
/// panel clock instead of raw UTC ISO.
String _fmtRaw(String value) => formatServerTimestamp(value);

/// The customer-portal SSO link (where Drive is linked) — copy it into a
/// browser. Short-lived, like the web redirect.
class _DrivePortalDialog extends StatelessWidget {
  const _DrivePortalDialog({required this.url});

  final String url;

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
              'يُربط جوجل درايف من بوابة العميل (صلاحية محدودة drive.file). '
              'افتح الرابط في المتصفح خلال دقائق — صالح لمرّة واحدة.',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: AppTokens.s12),
            _CopyRow(label: 'الرابط', value: url),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم نسخ الرابط')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('نسخ الرابط'),
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
