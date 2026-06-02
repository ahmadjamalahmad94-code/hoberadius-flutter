import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nas/data/nas_repository.dart';
import '../../nas/domain/nas_model.dart';
import '../data/mikrotik_repository.dart';
import '../domain/mikrotik_model.dart';

final mikrotikConfigsProvider =
    FutureProvider.autoDispose<List<MikrotikConfig>>((ref) {
  return ref.watch(mikrotikRepositoryProvider).list();
});

final mikrotikRoutersProvider =
    FutureProvider.autoDispose<List<NasDevice>>((ref) {
  return ref.watch(nasRepositoryProvider).list();
});

final mikrotikRouterOverviewProvider =
    FutureProvider.autoDispose.family<MikrotikRouterOverview, int>((ref, id) {
  return ref.watch(mikrotikRepositoryProvider).routerOverview(id);
});
