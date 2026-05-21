import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_control_repository.dart';
import '../domain/admin_control_model.dart';

final settingsProvider = FutureProvider.autoDispose<SettingsSnapshot>((ref) {
  return ref.watch(adminControlRepositoryProvider).settings();
});

final apiTokensProvider =
    FutureProvider.autoDispose<List<ApiTokenRecord>>((ref) {
  return ref.watch(adminControlRepositoryProvider).tokens();
});

final tenantsProvider = FutureProvider.autoDispose<List<TenantRecord>>((ref) {
  return ref.watch(adminControlRepositoryProvider).tenants();
});

final webhookConfigProvider = FutureProvider.autoDispose<WebhookConfig>((ref) {
  return ref.watch(adminControlRepositoryProvider).webhookConfig();
});

final webhookDeliveriesProvider =
    FutureProvider.autoDispose.family<List<WebhookDelivery>, String>(
  (ref, status) => ref.watch(adminControlRepositoryProvider).webhookDeliveries(
        status: status == 'all' ? null : status,
      ),
);
