import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/provider_grants_repository.dart';
import '../domain/provider_grants_model.dart';
import '../domain/provider_grants_nav_map.dart';

final providerGrantsRepositoryProvider =
    Provider<ProviderGrantsRepository>((ref) {
  return ProviderGrantsRepository(ref.read(apiClientProvider));
});

/// Holds the latest provider grants with **last-known-good** fail-open: a
/// transient fetch failure keeps the previous good value, so a sync outage
/// never falsely locks the app. Only a *successful* response carrying a
/// definitive lockout (expired / never_activated / beyond_grace) blocks.
class ProviderGrantsNotifier extends AsyncNotifier<ProviderGrants?> {
  ProviderGrants? _lastKnownGood;

  @override
  Future<ProviderGrants?> build() => _fetch();

  Future<ProviderGrants?> _fetch() async {
    try {
      final grants = await ref.read(providerGrantsRepositoryProvider).fetch();
      _lastKnownGood = grants;
      return grants;
    } catch (_) {
      // Fail-open: surface last-known-good if we have one; otherwise null so
      // every gate consumer treats "no decision yet" as allowed.
      if (_lastKnownGood != null) return _lastKnownGood;
      return null;
    }
  }

  /// Re-poll the endpoint (call on resume / after license actions).
  Future<void> refresh() async {
    state = const AsyncLoading<ProviderGrants?>().copyWithPrevious(state);
    state = await AsyncValue.guard(_fetch);
  }
}

final providerGrantsProvider =
    AsyncNotifierProvider<ProviderGrantsNotifier, ProviderGrants?>(
  ProviderGrantsNotifier.new,
);

/// The effective grants to gate on: the resolved value, or the permissive
/// default while loading / when no decision is available (fail-open).
final effectiveGrantsProvider = Provider<ProviderGrants>((ref) {
  return ref.watch(providerGrantsProvider).valueOrNull ??
      ProviderGrants.permissive;
});

/// The quantity cap for a service-key (null = no cap / unknown).
final grantLimitProvider = Provider.family<GrantLimit?, String>((ref, key) {
  return ref.watch(effectiveGrantsProvider).limit(key);
});

/// Limit for the service-key that governs a given route location.
GrantLimit? grantLimitForLocation(WidgetRef ref, String location) {
  final key = serviceKeyForLocation(location);
  if (key == null) return null;
  return ref.watch(effectiveGrantsProvider).limit(key);
}
