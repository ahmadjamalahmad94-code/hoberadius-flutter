import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/system_operations_providers.dart';
import '../../domain/system_operations_model.dart';

class SystemSyncPanel extends StatelessWidget {
  const SystemSyncPanel({
    super.key,
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
            text: systemStatusLabel(job.status),
            tone: systemStatusTone(job.status),
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
