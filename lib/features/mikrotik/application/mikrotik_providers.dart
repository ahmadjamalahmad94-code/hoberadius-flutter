import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mikrotik_repository.dart';
import '../domain/mikrotik_model.dart';

final mikrotikConfigsProvider =
    FutureProvider.autoDispose<List<MikrotikConfig>>((ref) {
  return ref.watch(mikrotikRepositoryProvider).list();
});
