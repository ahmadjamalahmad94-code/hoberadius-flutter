import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../provider_grants/application/nav_visibility.dart';

/// Sections shown only when the network actually uses them — on top of the
/// licence (provider-grant) gate. An optional feature the network never set
/// up should not sit in the menu as an empty section (owner review).
const kUsageGatedSectionIds = {'electronic-cards'};

/// Whether this network uses electronic cards: it has card-store users, store
/// packages, or wallet-recharge batches. Any one is enough.
///
/// Fails OPEN (returns true) on a read error so a transient network problem
/// never hides a feature the network relies on.
final eCardsInUseProvider = FutureProvider.autoDispose<bool>((ref) async {
  // Re-evaluate after a login/server switch (a different network).
  ref.watch(authControllerProvider.select((s) => s.admin?.id));
  final api = ref.watch(apiClientProvider);
  try {
    final r = await Future.wait([
      api.get('/api/v1/card-users', query: {'limit': 1}),
      api.get('/api/v1/card-marketplace/packages', query: {'limit': 1}),
      api.get('/api/v1/cards/recharge', query: {'page': 1, 'per_page': 1}),
    ]);
    return eCardsUsageFromResponses(r[0], r[1], r[2]);
  } catch (_) {
    return true;
  }
});

/// Pure decision over the three list responses (kept separate for tests).
bool eCardsUsageFromResponses(
  Map<String, dynamic> cardUsers,
  Map<String, dynamic> packages,
  Map<String, dynamic> recharge,
) {
  Map<String, dynamic> data(Map<String, dynamic> m) {
    final d = m['data'];
    return d is Map<String, dynamic> ? d : m;
  }

  int n(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
  int len(Object? v) => v is List ? v.length : 0;

  final u = data(cardUsers);
  final summary = u['summary'];
  final users = summary is Map ? n(summary['users']) : 0;
  final p = data(packages);
  final pkgs = n(p['count']) + len(p['items']);
  final rc = data(recharge);
  final recharges = n(rc['total']) + len(rc['items']);
  return users > 0 || len(u['items']) > 0 || pkgs > 0 || recharges > 0;
}

/// Licence-gated sections minus usage-gated ones the network doesn't use.
/// While usage is still loading those sections stay hidden (most networks
/// don't use them, so this avoids an empty section flashing in and out).
final visibleNavSectionsProvider =
    Provider.autoDispose<List<GatedNavSection>>((ref) {
  final sections = ref.watch(gatedNavSectionsProvider);
  final inUse = ref.watch(eCardsInUseProvider).valueOrNull ?? false;
  return [
    for (final s in sections)
      if (!kUsageGatedSectionIds.contains(s.section.id) || inUse) s,
  ];
});
