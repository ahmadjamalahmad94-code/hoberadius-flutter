import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/system_operations_repository.dart';
import '../domain/system_operations_model.dart';

final systemStatusProvider = FutureProvider.autoDispose<SystemStatus>((ref) {
  return ref.watch(systemOperationsRepositoryProvider).status();
});

final systemDiagnosticsProvider =
    FutureProvider.autoDispose<SystemDiagnostics>((ref) {
  return ref.watch(systemOperationsRepositoryProvider).diagnostics();
});

final syncQueueProvider =
    FutureProvider.autoDispose.family<SyncQueueState, String>((ref, status) {
  return ref.watch(systemOperationsRepositoryProvider).syncQueue(
        status: status == 'all' ? null : status,
      );
});

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

  @override
  Widget build(BuildContext context) {
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
        status.when(
          loading: () => const _LoadingCard(title: 'حالة النظام'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب حالة النظام',
            subtitle: '$e',
          ),
          data: _StatusPanel.new,
        ),
        const SizedBox(height: AppTokens.s12),
        diagnostics.when(
          loading: () => const _LoadingCard(title: 'تشخيص الراوترات'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تشغيل التشخيص',
            subtitle: '$e',
          ),
          data: _DiagnosticsPanel.new,
        ),
        const SizedBox(height: AppTokens.s12),
        sync.when(
          loading: () => const _LoadingCard(title: 'طابور المزامنة'),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب طابور المزامنة',
            subtitle: '$e',
          ),
          data: (data) => _SyncPanel(
            state: data,
            selectedStatus: _syncStatus,
            onStatusChanged: (value) {
              setState(() => _syncStatus = value);
            },
            onRetry: _retryJob,
            onCancel: _cancelJob,
          ),
        ),
      ],
    );
  }

  void _refreshAll() {
    ref.invalidate(systemStatusProvider);
    ref.invalidate(systemDiagnosticsProvider);
    ref.invalidate(syncQueueProvider(_syncStatus));
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
      final result =
          await ref.read(systemOperationsRepositoryProvider).reconcile();
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت المطابقة: ${result.stats}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel(this.status);

  final SystemStatus status;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Metric(
        'المشتركين',
        status.counts['subscribers'] ?? 0,
        Icons.person_outline,
      ),
      _Metric(
        'الباقات',
        status.counts['access_plans'] ?? 0,
        Icons.workspace_premium_outlined,
      ),
      _Metric(
        'الكروت',
        status.counts['cards'] ?? 0,
        Icons.credit_card_outlined,
      ),
      _Metric(
        'الحزم',
        status.counts['card_batches'] ?? 0,
        Icons.inventory_2_outlined,
      ),
      _Metric(
        'جلسات RADIUS',
        status.counts['radacct'] ?? 0,
        Icons.online_prediction,
      ),
      _Metric('مزامنة معلقة', status.syncQueue['queued'] ?? 0, Icons.sync),
    ];
    return AppCard(
      title: 'حالة النظام',
      icon: Icons.monitor_heart_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: AppTokens.s8,
                mainAxisSpacing: AppTokens.s8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: cols == 1 ? 3.2 : 2.4,
                children: tiles.map(_MetricTile.new).toList(),
              );
            },
          ),
          if (status.routers.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              children: status.routers
                  .map(
                    (router) => StatusPill(
                      text:
                          '${router.name.isEmpty ? router.host : router.name}: ${router.enabled ? 'مفعل' : 'معطل'}',
                      tone: router.enabled ? PillTone.green : PillTone.neutral,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel(this.diagnostics);

  final SystemDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'تشخيص الراوترات',
      icon: Icons.router_outlined,
      child: diagnostics.routers.isEmpty
          ? const EmptyState(
              icon: Icons.router_outlined,
              title: 'لا توجد راوترات للتشخيص',
            )
          : Column(
              children: diagnostics.routers
                  .map((router) => _DiagnosticRow(router: router))
                  .toList(),
            ),
    );
  }
}

class _SyncPanel extends StatelessWidget {
  const _SyncPanel({
    required this.state,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onRetry,
    required this.onCancel,
  });

  final SyncQueueState state;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<SyncJob> onRetry;
  final ValueChanged<SyncJob> onCancel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'طابور المزامنة',
      icon: Icons.sync_alt,
      actions: [
        DropdownButton<String>(
          value: selectedStatus,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('الكل')),
            DropdownMenuItem(value: 'queued', child: Text('بالانتظار')),
            DropdownMenuItem(value: 'retrying', child: Text('إعادة محاولة')),
            DropdownMenuItem(value: 'failed', child: Text('فاشلة')),
            DropdownMenuItem(value: 'done', child: Text('منتهية')),
          ],
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
        ),
      ],
      padding: EdgeInsets.zero,
      child: state.items.isEmpty
          ? const EmptyState(
              icon: Icons.task_alt,
              title: 'لا توجد مهام مزامنة',
            )
          : Column(
              children: state.items
                  .map(
                    (job) => _SyncRow(
                      job: job,
                      onRetry: () => onRetry(job),
                      onCancel: () => onCancel(job),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.metric);
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceMuted,
        border: Border.all(color: AppTokens.border),
        borderRadius: BorderRadius.circular(AppTokens.r10),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: AppTokens.brand),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Text(
            '${metric.value}',
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.router});
  final DiagnosticRouter router;

  @override
  Widget build(BuildContext context) {
    final ok = router.status == 'ok';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
        color: ok ? AppTokens.green : AppTokens.amber,
      ),
      title: Text(router.name.isEmpty ? router.host : router.name),
      subtitle: Text(
        [
          if (router.host.isNotEmpty) router.host,
          if (router.verdict.isNotEmpty) router.verdict,
          if (router.hint.isNotEmpty) router.hint,
        ].join(' • '),
      ),
      trailing: StatusPill(
        text: _statusLabel(router.status),
        tone: ok ? PillTone.green : PillTone.orange,
      ),
    );
  }
}

class _SyncRow extends StatelessWidget {
  const _SyncRow({
    required this.job,
    required this.onRetry,
    required this.onCancel,
  });

  final SyncJob job;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cancellable = job.status == 'queued' || job.status == 'retrying';
    return Column(
      children: [
        ListTile(
          title: Text('#${job.id} • ${job.kind}'),
          subtitle: Text(
            [
              if (job.entityKey.isNotEmpty) job.entityKey,
              'محاولات: ${job.attempts}',
              if (job.lastError.isNotEmpty) job.lastError,
            ].join(' • '),
          ),
          leading: StatusPill(
            text: _statusLabel(job.status),
            tone: _statusTone(job.status),
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'إعادة محاولة',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'إلغاء',
                onPressed: cancellable ? onCancel : null,
                icon: const Icon(Icons.cancel_outlined),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      child: const Padding(
        padding: EdgeInsets.all(AppTokens.s20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _statusLabel(String value) {
  return switch (value) {
    'ok' => 'سليم',
    'queued' => 'بالانتظار',
    'syncing' => 'قيد التنفيذ',
    'retrying' => 'إعادة محاولة',
    'done' => 'منتهية',
    'failed' => 'فاشلة',
    'disabled' => 'معطل',
    'tcp_failed' => 'فشل اتصال',
    'api_failed' => 'فشل API',
    _ => value.isEmpty ? 'غير معروف' : value,
  };
}

PillTone _statusTone(String value) {
  return switch (value) {
    'done' || 'ok' => PillTone.green,
    'failed' || 'tcp_failed' || 'api_failed' => PillTone.red,
    'queued' || 'retrying' || 'syncing' => PillTone.orange,
    _ => PillTone.neutral,
  };
}
