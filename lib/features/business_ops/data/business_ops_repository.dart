import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/business_ops_model.dart';

/// Repository for the Business-OS operators console. Wraps the admin-authed
/// `/api/v1/business/summary`, `/api/v1/finance/ledger(+/corrections)`, and
/// `/api/v1/pricing/snapshots` endpoints (all `require_api_token`).
class BusinessOpsRepository {
  BusinessOpsRepository(this._api);

  final ApiClient _api;

  Future<BusinessSummary> summary() async {
    final res = await _api.get('/api/v1/business/summary');
    final data = res['data'];
    if (data is Map) {
      return BusinessSummary.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return BusinessSummary.empty;
  }

  Future<List<BusinessLedgerEntry>> listLedger({
    String entryType = '',
    String referenceType = '',
    int limit = 100,
  }) async {
    final res = await _api.get(
      '/api/v1/finance/ledger',
      query: {
        if (entryType.trim().isNotEmpty) 'entry_type': entryType.trim(),
        if (referenceType.trim().isNotEmpty)
          'reference_type': referenceType.trim(),
        'limit': limit,
      },
    );
    return _items(res).map(BusinessLedgerEntry.fromJson).toList();
  }

  Future<BusinessLedgerEntry> createCorrection({
    required String debitAccount,
    required String creditAccount,
    required num amount,
    String currency = 'JOD',
    String targetType = '',
    int? targetId,
    String referenceType = '',
    int? referenceId,
    String reason = '',
  }) async {
    final res = await _api.post(
      '/api/v1/finance/ledger/corrections',
      body: {
        'debit_account': debitAccount,
        'credit_account': creditAccount,
        'amount': amount,
        'currency': currency,
        if (targetType.trim().isNotEmpty) 'target_type': targetType.trim(),
        if (targetId != null) 'target_id': targetId,
        if (referenceType.trim().isNotEmpty)
          'reference_type': referenceType.trim(),
        if (referenceId != null) 'reference_id': referenceId,
        if (reason.trim().isNotEmpty)
          'metadata': {'reason': reason.trim(), 'source': 'flutter'},
      },
    );
    return BusinessLedgerEntry.fromJson(_object(res, 'entry'));
  }

  Future<List<PriceSnapshot>> listSnapshots({
    String referenceType = '',
    int? packageId,
    int limit = 100,
  }) async {
    final res = await _api.get(
      '/api/v1/pricing/snapshots',
      query: {
        if (referenceType.trim().isNotEmpty)
          'reference_type': referenceType.trim(),
        if (packageId != null) 'package_id': packageId,
        'limit': limit,
      },
    );
    return _items(res).map(PriceSnapshot.fromJson).toList();
  }

  Future<PriceSnapshot> captureSnapshot({
    required String referenceType,
    int? referenceId,
    int? packageId,
    required num retailPrice,
    required num wholesalePrice,
    num? effectivePrice,
    num discountAmount = 0,
    String currency = 'JOD',
  }) async {
    final res = await _api.post(
      '/api/v1/pricing/snapshots',
      body: {
        'reference_type': referenceType.trim(),
        if (referenceId != null) 'reference_id': referenceId,
        if (packageId != null) 'package_id': packageId,
        'retail_price': retailPrice,
        'wholesale_price': wholesalePrice,
        if (effectivePrice != null) 'effective_price': effectivePrice,
        'discount_amount': discountAmount,
        'currency': currency,
        'metadata': {'source': 'flutter'},
      },
    );
    return PriceSnapshot.fromJson(_object(res, 'snapshot'));
  }
}

final businessOpsRepositoryProvider = Provider<BusinessOpsRepository>((ref) {
  return BusinessOpsRepository(ref.watch(apiClientProvider));
});

List<Map<String, dynamic>> _items(Map<String, dynamic> res) {
  final data = res['data'];
  final items = data is Map ? data['items'] : null;
  if (items is! List) return const [];
  return items
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}

Map<String, dynamic> _object(Map<String, dynamic> res, String key) {
  final data = res['data'];
  final value = data is Map ? data[key] : null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return const {};
}
