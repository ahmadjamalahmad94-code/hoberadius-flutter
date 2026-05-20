import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/operational_report_model.dart';

class OperationalReportsRepository {
  OperationalReportsRepository(this._api);

  final ApiClient _api;

  Future<OperationalReportSnapshot> fetch({
    required String slug,
    String query = '',
    int limit = 100,
  }) async {
    final res = await _api.get(
      '/api/v1/operational-reports/$slug',
      query: {
        'limit': limit,
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return OperationalReportSnapshot.fromJson(data);
    }
    if (data is Map) {
      return OperationalReportSnapshot.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return const OperationalReportSnapshot(
      slug: '',
      items: [],
      count: 0,
      query: '',
      limit: 0,
      offset: 0,
    );
  }
}

final operationalReportsRepositoryProvider =
    Provider<OperationalReportsRepository>((ref) {
  return OperationalReportsRepository(ref.watch(apiClientProvider));
});
