import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/accounting_model.dart';

class AccountingRepository {
  AccountingRepository(this._api);

  final ApiClient _api;

  Future<List<PaymentTransaction>> listPayments({int? subscriberId}) async {
    final res = await _api.get(
      '/api/v1/payments',
      query: {
        if (subscriberId != null) 'subscriber_id': subscriberId,
        'limit': 100,
      },
    );
    return _items(res).map(PaymentTransaction.fromJson).toList();
  }

  Future<PaymentTransaction> createPayment({
    required String username,
    required num amount,
    String currency = 'JOD',
    String method = 'cash',
    String roundingMode = 'floor',
    num? customPrice,
    num discountAmount = 0,
    String discountReason = '',
    String notes = '',
    bool applyToRadius = false,
    bool dryRun = true,
  }) async {
    final res = await _api.post(
      '/api/v1/payments',
      body: {
        'username': username,
        'amount': amount,
        'currency': currency,
        'method': method,
        'rounding_mode': roundingMode,
        if (customPrice != null) 'custom_price': customPrice,
        'discount_amount': discountAmount,
        'discount_reason': discountReason,
        'notes': notes,
        'apply_to_radius': applyToRadius,
        'dry_run': dryRun,
      },
    );
    return PaymentTransaction.fromJson(_object(res, 'payment'));
  }

  Future<List<LoanEntry>> listLoans({
    int? subscriberId,
    String status = '',
  }) async {
    final res = await _api.get(
      '/api/v1/loans',
      query: {
        if (subscriberId != null) 'subscriber_id': subscriberId,
        if (status.isNotEmpty) 'status': status,
        'limit': 100,
      },
    );
    return _items(res).map(LoanEntry.fromJson).toList();
  }

  Future<LoanEntry> createLoan({
    required String username,
    int hours = 0,
    int days = 0,
    num amount = 0,
    String currency = 'JOD',
    String reason = '',
    bool applyToRadius = false,
    bool dryRun = true,
  }) async {
    final res = await _api.post(
      '/api/v1/loans',
      body: {
        'username': username,
        'hours': hours,
        'days': days,
        'amount': amount,
        'currency': currency,
        'reason': reason,
        'apply_to_radius': applyToRadius,
        'dry_run': dryRun,
      },
    );
    return LoanEntry.fromJson(_object(res, 'loan'));
  }

  Future<Map<String, dynamic>> settleLoan({
    required int loanId,
    required num amount,
    String currency = 'JOD',
    String method = 'manual',
    String notes = '',
  }) async {
    final res = await _api.post(
      '/api/v1/loans/$loanId/settle',
      body: {
        'amount': amount,
        'currency': currency,
        'method': method,
        'notes': notes,
      },
    );
    return _object(res, 'settlement');
  }

  Future<List<LedgerEntry>> listLedger({
    int? subscriberId,
    String entryType = '',
  }) async {
    final res = await _api.get(
      '/api/v1/ledger',
      query: {
        if (subscriberId != null) 'subscriber_id': subscriberId,
        if (entryType.isNotEmpty) 'entry_type': entryType,
        'limit': 150,
      },
    );
    return _items(res).map(LedgerEntry.fromJson).toList();
  }

  Future<LedgerEntry> voidLedger({
    required int entryId,
    required String reason,
  }) async {
    final res = await _api.post(
      '/api/v1/ledger/void',
      body: {'entry_id': entryId, 'reason': reason},
    );
    return LedgerEntry.fromJson(_object(res, 'entry'));
  }

  Future<List<Map<String, dynamic>>> financialReport(String slug) async {
    final res = await _api.get('/api/v1/reports/$slug');
    return _items(res);
  }
}

final accountingRepositoryProvider = Provider<AccountingRepository>((ref) {
  return AccountingRepository(ref.watch(apiClientProvider));
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
