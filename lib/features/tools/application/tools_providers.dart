import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tools_repository.dart';
import '../domain/tools_models.dart';

final radiusLogProvider = FutureProvider.autoDispose<RadiusLogSnapshot>((ref) {
  return ref.watch(toolsRepositoryProvider).radiusLog();
});
