import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/currency.dart';
import '../data/admin_control_repository.dart';
import '../domain/admin_control_model.dart';

final settingsProvider = FutureProvider.autoDispose<SettingsSnapshot>((ref) {
  return ref.watch(adminControlRepositoryProvider).settings();
});

/// The tenant's central currency (web `default_currency()` /
/// `billing.currency`). Resolves to [kDefaultCurrency] while settings load or
/// if the key is absent, so money always renders with a sensible code.
final tenantCurrencyProvider = Provider.autoDispose<String>((ref) {
  final async = ref.watch(settingsProvider);
  return async.maybeWhen(
    data: (snapshot) =>
        normalizeCurrency(snapshot.settings[kCurrencySettingKey]),
    orElse: () => kDefaultCurrency,
  );
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
