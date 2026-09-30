import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/revenue_model.dart';

class RevenueRepository {
  RevenueRepository(this._api);

  final ApiClient _api;

  /// One page of «المركز المالي». fix2 servers page with limit/offset and
  /// answer `has_more`; older ones ignore the offset (the screen then stops
  /// when a page brings nothing new).
  Future<RevenuePage> list({int offset = 0, int limit = 200}) async {
    final res = await _api.get(
      '/api/v1/finance/revenue',
      query: {'limit': limit, if (offset > 0) 'offset': offset},
    );
    return RevenuePage.fromJson(res);
  }
}

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  return RevenueRepository(ref.watch(apiClientProvider));
});
