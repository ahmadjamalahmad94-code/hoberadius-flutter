import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/distributor_model.dart';

class DistributorsRepository {
  DistributorsRepository(this._api);

  final ApiClient _api;

  Future<List<Distributor>> list() async {
    final res = await _api.get('/api/v1/distributors');
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(Distributor.fromJson)
        .toList();
  }

  Future<Distributor> create(Distributor distributor) async {
    final res =
        await _api.post('/api/v1/distributors', body: distributor.toBody());
    final data = res['data'];
    final json = data is Map<String, dynamic> ? data['distributor'] : null;
    return Distributor.fromJson(json is Map<String, dynamic> ? json : const {});
  }

  Future<DistributorSummary> summary(int distributorId) async {
    final res = await _api.get('/api/v1/distributors/$distributorId/summary');
    final data = res['data'];
    final json = data is Map<String, dynamic> ? data['summary'] : null;
    return DistributorSummary.fromJson(
      json is Map<String, dynamic> ? json : const {},
    );
  }

  Future<List<DistributorBatch>> batches(int distributorId) async {
    final res = await _api.get('/api/v1/distributors/$distributorId/batches');
    final items = (res['data']?['items'] ?? const []) as List;
    return items
        .whereType<Map<String, dynamic>>()
        .map(DistributorBatch.fromJson)
        .toList();
  }

  Future<void> assignBatch(
    int distributorId, {
    required int batchId,
    String notes = '',
  }) {
    return _api.post(
      '/api/v1/distributors/$distributorId/assign-batch',
      body: {
        'batch_id': batchId,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<DistributorLedgerEntry> settle(
    int distributorId, {
    required num amount,
    required String direction,
    String entryType = 'settlement',
    String currency = 'JOD',
    String notes = '',
  }) async {
    final res = await _api.post(
      '/api/v1/distributors/$distributorId/settle',
      body: {
        'amount': amount,
        'direction': direction,
        'entry_type': entryType,
        'currency': currency,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = res['data'];
    final json = data is Map<String, dynamic> ? data['entry'] : null;
    return DistributorLedgerEntry.fromJson(
      json is Map<String, dynamic> ? json : const {},
    );
  }
}

final distributorsRepositoryProvider = Provider<DistributorsRepository>((ref) {
  return DistributorsRepository(ref.watch(apiClientProvider));
});
