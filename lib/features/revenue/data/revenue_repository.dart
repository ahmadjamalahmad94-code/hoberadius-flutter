import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/revenue_model.dart';

class RevenueRepository {
  RevenueRepository(this._api);

  final ApiClient _api;

  Future<RevenuePage> list() async {
    final res = await _api.get(
      '/api/v1/finance/revenue',
      query: {'limit': 200},
    );
    return RevenuePage.fromJson(res);
  }
}

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  return RevenueRepository(ref.watch(apiClientProvider));
});
