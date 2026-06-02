import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/customer_portals_model.dart';

class CustomerPortalsRepository {
  CustomerPortalsRepository(this._api);

  final ApiClient _api;

  Future<CustomerPortalsState> overview() async {
    final res = await _api.get('/api/v1/customer-portals');
    final data = res['data'];
    return CustomerPortalsState.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }
}

final customerPortalsRepositoryProvider =
    Provider<CustomerPortalsRepository>((ref) {
  return CustomerPortalsRepository(ref.watch(apiClientProvider));
});
