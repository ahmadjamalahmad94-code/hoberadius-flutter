import 'package:flutter_riverpod/flutter_riverpod.dart';

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

String systemStatusLabel(String value) {
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

PillTone systemStatusTone(String value) {
  return switch (value) {
    'done' || 'ok' => PillTone.green,
    'failed' || 'tcp_failed' || 'api_failed' => PillTone.red,
    'queued' || 'retrying' || 'syncing' => PillTone.orange,
    _ => PillTone.neutral,
  };
}
