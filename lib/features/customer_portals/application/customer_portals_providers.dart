import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customer_portals_repository.dart';
import '../domain/customer_portals_model.dart';

final customerPortalsProvider =
    FutureProvider.autoDispose<CustomerPortalsState>((ref) {
  return ref.watch(customerPortalsRepositoryProvider).overview();
});
