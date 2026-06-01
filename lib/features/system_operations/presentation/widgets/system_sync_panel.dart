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
          title: Text('#${job.id} • ${_syncKindLabel(job.kind)}'),
          subtitle: Text(
            [
              if (job.entityKey.isNotEmpty) job.entityKey,
              'عدد المحاولات: ${job.attempts}',
              if (job.nextAttemptAt.isNotEmpty)
                'المحاولة التالية: ${job.nextAttemptAt}',
              if (job.lastError.isNotEmpty)
                'سبب التعثر: ${_syncErrorLabel(job.lastError)}',
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

String _syncKindLabel(String value) {
  final key = value.trim().toLowerCase();
  return switch (key) {
    'license' || 'license.sync' || 'license_contract' || 'license_contract.sync' =>
      'تحديث عقد الترخيص',
    'runtime_contract' || 'runtime_contract.sync' =>
      'تحديث عقد التشغيل',
    'identity' || 'identity_sync' || 'identity.sync' =>
      'مزامنة الهوية وكلمات المرور',
    'heartbeat' || 'heartbeat.probe' || 'heartbeat.sent' =>
      'فحص نبض الربط',
    'subscriber.update' || 'subscriber_sync' =>
      'مزامنة بيانات مشترك',
    'card.update' || 'card_sync' => 'مزامنة بيانات بطاقة',
    'payment.update' || 'payment_sync' => 'مزامنة دفعة مالية',
    'service.update' || 'service_sync' => 'مزامنة خدمة مفعلة',
    _ => 'مهمة مزامنة',
  };
}

String _syncErrorLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'غير محدد';
  if (_containsArabic(text)) return text;
  final lower = text.toLowerCase();
  if (lower.contains('invalid_payload')) return 'رد الربط غير مكتمل';
  if (lower.contains('https_required')) return 'يلزم تشغيل الربط عبر HTTPS';
  if (lower.contains('timeout')) return 'انتهت مهلة الاتصال';
  if (lower.contains('connection') || lower.contains('connect')) {
    return 'تعذر الاتصال بلوحة التراخيص';
  }
  if (lower.contains('unauthorized') || lower.contains('forbidden')) {
    return 'التوقيع أو صلاحية الربط غير مقبولة';
  }
  if (lower.contains('not_found')) return 'العنصر المطلوب غير موجود';
  if (lower.contains('csrf')) return 'انتهت صلاحية نموذج الحماية';
  if (lower.contains('request_failed') || lower.contains('bad request')) {
    return 'تعذر تنفيذ الطلب';
  }
  return 'تعذر تنفيذ مهمة المزامنة';
}

bool _containsArabic(String value) {
  return value.runes.any(
    (r) =>
        (r >= 0x0600 && r <= 0x06FF) ||
        (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0x08A0 && r <= 0x08FF) ||
        (r >= 0xFB50 && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF),
  );
}
