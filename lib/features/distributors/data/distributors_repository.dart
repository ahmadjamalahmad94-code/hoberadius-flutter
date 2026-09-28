import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/idempotency.dart';
import '../domain/distributor_model.dart';

class DistributorsRepository {
  DistributorsRepository(this._api);

  final ApiClient _api;

  /// Every distributor (the endpoint's default page was 200 and the app
  /// never asked for more): pages until a short page / no new rows.
  Future<List<Distributor>> list({
    int pageSize = 200,
    int maxPages = 50,
  }) async {
    final out = <Distributor>[];
    final seen = <Object?>{};
    for (var page = 0; page < maxPages; page++) {
      final res = await _api.get(
        '/api/v1/distributors',
        query: {'limit': pageSize, 'offset': page * pageSize},
      );
      final items = (res['data']?['items'] ?? const []) as List;
      var added = 0;
      for (final d in items
          .whereType<Map<String, dynamic>>()
          .map(Distributor.fromJson)) {
        if (seen.add(d.id ?? d.name)) {
          out.add(d);
          added++;
        }
      }
      final hasMore = res['data']?['has_more'];
      final more = hasMore is bool ? hasMore : items.length >= pageSize;
      if (!more || added == 0) break;
    }
    return out;
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

  /// A manual distributor movement. For a payment (`direction: credit`) the
  /// owner's rule is ONE effect, chosen by the admin: [applyTo] `balance`
  /// («إضافة للرصيد») or `debt` («خصم من الدين»); older servers ignore it.
  /// [currency] null → the server's system currency (was a hardcoded JOD).
  Future<DistributorLedgerEntry> settle(
    int distributorId, {
    required num amount,
    required String direction,
    String? applyTo,
    String entryType = 'settlement',
    String? currency,
    String notes = '',
    String? idempotencyKey,
  }) async {
    final res = await _api.post(
      '/api/v1/distributors/$distributorId/settle',
      headers: idempotencyHeaders(idempotencyKey),
      body: {
        'amount': amount,
        'direction': direction,
        if (direction == 'credit' && applyTo != null) 'apply_to': applyTo,
        'entry_type': entryType,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
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
