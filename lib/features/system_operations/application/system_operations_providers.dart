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

final licenseFileProvider = FutureProvider.autoDispose<LicenseFileState>((ref) {
  return ref.watch(systemOperationsRepositoryProvider).licenseFile();
});

final bridgeEventsProvider =
    FutureProvider.autoDispose<BridgeEventsState>((ref) {
  return ref.watch(systemOperationsRepositoryProvider).bridgeEvents();
});

String systemStatusLabel(String value) {
  return switch (value) {
    'active' => 'نشط',
    'valid' => 'صالح',
    'healthy' => 'سليم',
    'grace' => 'فترة سماح',
    'missing' => 'غير موجود',
    'stale' => 'قديم',
    'blocked' => 'محظور',
    'config_missing' => 'الإعدادات ناقصة',
    'ok' => 'سليم',
    'queued' => 'بالانتظار',
    'syncing' => 'قيد التنفيذ',
    'retrying' => 'إعادة محاولة',
    'done' => 'منتهية',
    'failed' => 'فاشلة',
    'disabled' => 'معطل',
    'denied' => 'مرفوض',
    'expired' => 'منتهي',
    'fingerprint_denied' => 'بصمة الخادم مرفوضة',
    'https_required' => 'يتطلب HTTPS',
    'inactive' => 'غير نشط',
    'invalid_payload' => 'رد غير مكتمل',
    'invalid_request' => 'طلب غير مكتمل',
    'local_account' => 'حساب محلي',
    'not_found' => 'غير موجود',
    'rate_limited' => 'طلبات كثيرة',
    'revoked' => 'ملغي',
    'suspended' => 'موقوف',
    'timeout' => 'انتهت المهلة',
    'unavailable' => 'غير متاح',
    'unknown' => 'غير معروف',
    'tcp_failed' => 'فشل اتصال',
    'api_failed' => 'فشل واجهة الربط',
    _ => 'حالة غير معروفة',
  };
}

PillTone systemStatusTone(String value) {
  return switch (value) {
    'done' || 'ok' || 'active' || 'valid' || 'healthy' => PillTone.green,
    'failed' ||
    'tcp_failed' ||
    'api_failed' ||
    'blocked' ||
    'denied' ||
    'expired' ||
    'fingerprint_denied' ||
    'invalid_payload' ||
    'revoked' ||
    'suspended' =>
      PillTone.red,
    'queued' ||
    'retrying' ||
    'syncing' ||
    'stale' ||
    'config_missing' ||
    'https_required' ||
    'timeout' ||
    'unavailable' =>
      PillTone.orange,
    'disabled' || 'missing' || 'inactive' => PillTone.neutral,
    _ => PillTone.neutral,
  };
}
