import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/system_operations_providers.dart';
import '../data/system_operations_repository.dart';
import '../domain/system_operations_model.dart';
import 'widgets/system_diagnostics_panel.dart';
import 'widgets/system_license_file_panel.dart';
import 'widgets/system_loading_card.dart';
import 'widgets/system_status_panel.dart';
import 'widgets/system_sync_panel.dart';

class SystemOperationsScreen extends ConsumerStatefulWidget {
  const SystemOperationsScreen({super.key});

  @override
  ConsumerState<SystemOperationsScreen> createState() =>
      _SystemOperationsScreenState();
}

class _SystemOperationsScreenState
    extends ConsumerState<SystemOperationsScreen> {
  String _syncStatus = 'all';
  bool _busy = false;
  String? _bridgeBusyAction;

  @override
  Widget build(BuildContext context) {
    final licenseFile = ref.watch(licenseFileProvider);
    final status = ref.watch(systemStatusProvider);
    final diagnostics = ref.watch(systemDiagnosticsProvider);
    final sync = ref.watch(syncQueueProvider(_syncStatus));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'عمليات النظام',
          subtitle:
              'حالة الخادم، التشخيص، طابور المزامنة، وإعادة المطابقة من API حقيقي.',
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
            ElevatedButton.icon(
              onPressed: _busy ? null : _runReconcile,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('مطابقة الآن'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        licenseFile.when(
          loading: () =>
              const SystemLoadingCard(title: 'ملف الترخيص والمزامنة'),
          error: (_, __) => HubErrorState(
            title: 'تعذر جلب ملف الترخيص',
            subtitle: 'تحقق من اتصال التطبيق بالريدياس ثم أعد المحاولة.',
            onRetry: () => ref.invalidate(licenseFileProvider),
          ),
          data: (data) => SystemLicenseFilePanel(
            state: data,
            busyAction: _bridgeBusyAction,
            onSyncLicense: () => _runBridgeAction('license'),
            onSyncIdentity: () => _runBridgeAction('identity'),
            onHeartbeat: () => _runBridgeAction('heartbeat'),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        status.when(
          loading: () => const SystemLoadingCard(title: 'حالة النظام'),
          error: (_, __) => HubErrorState(
            title: 'تعذر جلب حالة النظام',
            subtitle: 'لم يتمكن التطبيق من قراءة حالة الخادم الآن.',
            onRetry: () => ref.invalidate(systemStatusProvider),
          ),
          data: (data) => SystemStatusPanel(status: data),
        ),
        const SizedBox(height: AppTokens.s12),
        diagnostics.when(
          loading: () => const SystemLoadingCard(title: 'تشخيص الراوترات'),
          error: (_, __) => HubErrorState(
            title: 'تعذر تشغيل التشخيص',
            subtitle: 'لم يتمكن التطبيق من قراءة تشخيص الراوترات.',
            onRetry: () => ref.invalidate(systemDiagnosticsProvider),
          ),
          data: (data) => SystemDiagnosticsPanel(diagnostics: data),
        ),
        const SizedBox(height: AppTokens.s12),
        sync.when(
          loading: () => const SystemLoadingCard(title: 'طابور المزامنة'),
          error: (_, __) => HubErrorState(
            title: 'تعذر جلب طابور المزامنة',
            subtitle: 'لم يتمكن التطبيق من قراءة مهام المزامنة.',
            onRetry: () => ref.invalidate(syncQueueProvider(_syncStatus)),
          ),
          data: (data) => SystemSyncPanel(
            state: data,
            selectedStatus: _syncStatus,
            onStatusChanged: (value) => setState(() => _syncStatus = value),
            onRetry: _retryJob,
            onCancel: _cancelJob,
          ),
        ),
      ],
    );
  }

  void _refreshAll() {
    ref.invalidate(licenseFileProvider);
    ref.invalidate(systemStatusProvider);
    ref.invalidate(systemDiagnosticsProvider);
    ref.invalidate(syncQueueProvider(_syncStatus));
  }

  Future<void> _runBridgeAction(String action) async {
    if (_bridgeBusyAction != null) return;
    setState(() => _bridgeBusyAction = action);
    try {
      final repo = ref.read(systemOperationsRepositoryProvider);
      final result = switch (action) {
        'license' => await repo.syncLicenseContract(),
        'identity' => await repo.syncIdentity(),
        'heartbeat' => await repo.sendHeartbeatProbe(),
        _ => <String, dynamic>{'ok': false, 'status': 'unknown'},
      };
      _refreshAll();
      if (!mounted) return;
      final status = (result['status'] ?? '').toString();
      final success = result['ok'] == true;
      final label = systemStatusLabel(status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'تمت العملية: $label' : 'تعذرت العملية: $label'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذرت العملية. تحقق من الاتصال ثم أعد المحاولة.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _bridgeBusyAction = null);
    }
  }

  Future<void> _runReconcile() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تشغيل المطابقة الآن'),
        content: const Text(
          'سيطلب التطبيق من الخادم تشغيل مطابقة الجلسات مع الراوترات. التنفيذ يتم في Flask وليس من التطبيق مباشرة.',
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
    setState(() => _busy = true);
    try {
      await ref.read(systemOperationsRepositoryProvider).reconcile();
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت المطابقة بنجاح')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذرت المطابقة. تحقق من الاتصال ثم أعد المحاولة.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retryJob(SyncJob job) async {
    try {
      await ref.read(systemOperationsRepositoryProvider).retrySyncJob(job.id);
      ref.invalidate(syncQueueProvider(_syncStatus));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أُعيدت المهمة #${job.id} إلى الطابور')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذرت إعادة المحاولة.')),
      );
    }
  }

  Future<void> _cancelJob(SyncJob job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء مهمة مزامنة'),
        content: Text('هل تريد إلغاء المهمة #${job.id}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إلغاء المهمة'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(systemOperationsRepositoryProvider).cancelSyncJob(job.id);
      ref.invalidate(syncQueueProvider(_syncStatus));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إلغاء المهمة #${job.id}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إلغاء المهمة.')),
      );
    }
  }
}
