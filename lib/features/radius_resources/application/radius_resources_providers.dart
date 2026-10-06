import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/radius_resources_repository.dart';
import '../domain/radius_resources_model.dart';

// «pools» removed (owner 2026-10-06): IP pools are never read by RADIUS.
enum RadiusResourcesTab { shareGroups, bandwidthProfiles }

final selectedRadiusResourcesTabProvider =
    StateProvider<RadiusResourcesTab>((ref) => RadiusResourcesTab.shareGroups);

final radiusResourcesSnapshotProvider =
    FutureProvider.autoDispose<RadiusResourcesSnapshot>((ref) {
  return ref.watch(radiusResourcesRepositoryProvider).snapshot();
});
