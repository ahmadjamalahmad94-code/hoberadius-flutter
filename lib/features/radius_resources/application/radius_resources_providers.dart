import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/radius_resources_repository.dart';
import '../domain/radius_resources_model.dart';

enum RadiusResourcesTab { pools, shareGroups, bandwidthProfiles }

final selectedRadiusResourcesTabProvider =
    StateProvider<RadiusResourcesTab>((ref) => RadiusResourcesTab.pools);

final radiusResourcesSnapshotProvider =
    FutureProvider.autoDispose<RadiusResourcesSnapshot>((ref) {
  return ref.watch(radiusResourcesRepositoryProvider).snapshot();
});
