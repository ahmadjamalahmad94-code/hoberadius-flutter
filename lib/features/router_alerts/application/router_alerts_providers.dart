import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/router_alerts_repository.dart';
import '../domain/router_alerts_model.dart';

final routerAlertsProvider =
    FutureProvider.autoDispose<RouterAlertsState>((ref) {
  return ref.watch(routerAlertsRepositoryProvider).load();
});
