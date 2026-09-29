import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/permissions.dart';
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
  // 1) /api/admin/me `system.currency` (known right after session restore)
  final fromSession = ref.watch(sessionCurrencyProvider);
  // Without «عرض الإعدادات» /api/v1/settings answers 403 — never ask it;
  // the session payload (/api/admin/me system.currency) is enough.
  final canSettings =
      ref.watch(permissionsProvider.select((p) => p.can('settings.view')));
  if (!canSettings) {
    return fromSession.isNotEmpty ? fromSession : kDefaultCurrency;
  }
  final async = ref.watch(settingsProvider);
  return async.maybeWhen(
    // 2) settings `system.currency`, 3) settings `billing.currency`
    data: (snapshot) => snapshot.systemCurrency.isNotEmpty
        ? snapshot.systemCurrency
        : (fromSession.isNotEmpty
            ? fromSession
            : normalizeCurrency(snapshot.settings[kCurrencySettingKey])),
    orElse: () => fromSession.isNotEmpty ? fromSession : kDefaultCurrency,
  );
});
