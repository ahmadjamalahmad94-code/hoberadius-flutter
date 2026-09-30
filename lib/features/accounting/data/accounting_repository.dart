import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/idempotency.dart';
import '../../../core/api/paging.dart';
import '../../../core/format/money_limits.dart';

export '../../../core/format/money_limits.dart'
    show
        AppLimits,
        MoneyCap,
        formatNumberBound,
        kMaxMoneyAmount,
        kMaxMoneyAmountLabel,
        moneyTooLargeMessage,
        validateExtendSpan,
        validateMoneyAmount;
import '../domain/accounting_model.dart';

/// The UI slug of each financial report → the `report_type` the snapshot
/// endpoint accepts (`app/api/v1/reports.py`). Sending the slug itself made
/// «حفظ لقطة ثابتة» fail with 422 for 7 of the 9 reports.
const kReportSnapshotTypes = <String, String>{
  'sales': 'daily',
  'sales/daily': 'daily',
  'sales/monthly': 'monthly',
  'sales/yearly': 'yearly',
  'payments': 'subscriber_payments',
  'loans': 'loans',
  'activations': 'activations',
  'card-sales': 'card_sales',
  'profit-loss': 'profit_loss',
  'distributor-debts': 'distributor_debts',
};

String reportSnapshotType(String slug) =>
    kReportSnapshotTypes[slug] ??
    slug.replaceAll('/', '_').replaceAll('-', '_');

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

  /// Records a REAL payment. There is deliberately no dry-run flag here:
  /// `POST /payments` stores the payment even with `dry_run` (it only skips
  /// the RADIUS extension), so previews are computed locally and never reach
  /// this endpoint. [currency] null → the server's system currency.
  Future<PaymentTransaction> createPayment({
    required String username,
    required num amount,
    String? currency,
    String method = 'cash',
    String roundingMode = 'floor',
    num? customPrice,
    num discountAmount = 0,
    String discountReason = '',
    String notes = '',
    bool applyToRadius = false,
    String? idempotencyKey,
  }) async {
    final problem = validateMoneyAmount(amount, cap: MoneyCap.subscriberPayment);
    if (problem != null) {
      throw ApiException(code: 'validation_error', message: problem);
    }
    final res = await _api.post(
      '/api/v1/payments',
      headers: idempotencyHeaders(idempotencyKey),
      body: {
        'username': username,
        'amount': amount,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
        'method': method,
        'rounding_mode': roundingMode,
        if (customPrice != null) 'custom_price': customPrice,
        'discount_amount': discountAmount,
        'discount_reason': discountReason,
        'notes': notes,
        'apply_to_radius': applyToRadius,
        'dry_run': false,
      },
    );
    return PaymentTransaction.fromJson(_object(res, 'payment'));
  }

  Future<LedgerEntry> voidPayment({
    required int paymentId,
    required String reason,
  }) async {
    final res = await _api.post(
      '/api/v1/payments/$paymentId/void',
      body: {'reason': reason},
    );
    return LedgerEntry.fromJson(_object(res, 'entry'));
  }

  Future<List<LoanEntry>> listLoans({
    int? subscriberId,
    String status = '',
  }) async =>
      (await listLoansPage(subscriberId: subscriberId, status: status)).items;

  /// One page of `/loans` plus the server's totals for the WHOLE filter
  /// (`totals`, `total_count`, `has_more` on updated servers). Older servers
  /// send only items; the totals are then summed from what was loaded.
  Future<LoansPage> listLoansPage({
    int? subscriberId,
    String status = '',
    int limit = 100,
    int offset = 0,
  }) async {
    final res = await _api.get(
      '/api/v1/loans',
      query: {
        if (subscriberId != null) 'subscriber_id': subscriberId,
        if (status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : const <String, dynamic>{};
    final rows = _items(res);
    final info = readPageInfo(
      data,
      requestedLimit: limit,
      offset: offset,
      itemCount: rows.length,
    );
    final totals = data['totals'] is Map
        ? LoanTotals.fromJson(Map<String, dynamic>.from(data['totals'] as Map))
        : null;
    return LoansPage(
      items: rows.map(LoanEntry.fromJson).toList(),
      totals: totals,
      totalCount: info.total,
      hasMore: info.hasMore,
    );
  }

  /// Records a REAL loan (no dry-run: older servers stored a loan even for
  /// a «preview», so previews are computed locally).
  Future<LoanEntry> createLoan({
    required String username,
    int hours = 0,
    int days = 0,
    num amount = 0,
    String? currency,
    String reason = '',
    bool priceFromDays = false,
    bool applyToRadius = false,
    String? idempotencyKey,
  }) async =>
      (await createLoanWithOutcome(
        username: username,
        hours: hours,
        days: days,
        amount: amount,
        currency: currency,
        reason: reason,
        priceFromDays: priceFromDays,
        applyToRadius: applyToRadius,
        idempotencyKey: idempotencyKey,
      ))
          .loan;

  /// [createLoan] with the server's full answer: the loan as recorded (its
  /// amount computed by the server for `price_from_days`), or a 202
  /// «بانتظار موافقة المالك» with no loan yet.
  Future<LoanCreateOutcome> createLoanWithOutcome({
    required String username,
    int hours = 0,
    int days = 0,
    num amount = 0,
    String? currency,
    String reason = '',
    bool priceFromDays = false,
    bool applyToRadius = false,
    String? idempotencyKey,
  }) async {
    if (amount < 0 || amount > AppLimits.maxLoanAmount || !amount.isFinite) {
      throw ApiException(
        code: 'validation_error',
        message: 'قيمة السلفة غير صحيحة '
            '(0 إلى ${formatNumberBound(AppLimits.maxLoanAmount)}).',
      );
    }
    final res = await _api.post(
      '/api/v1/loans',
      headers: idempotencyHeaders(idempotencyKey),
      body: {
        'username': username,
        'hours': hours,
        'days': days,
        'amount': amount,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
        'reason': reason,
        if (priceFromDays) 'price_from_days': true,
        'apply_to_radius': applyToRadius,
        'dry_run': false,
      },
    );
    final data = res['data'] is Map ? res['data'] as Map : const {};
    return LoanCreateOutcome(
      loan: LoanEntry.fromJson(_object(res, 'loan')),
      pendingApproval: data['pending_approval'] == true,
      message: '${data['message'] ?? ''}'.trim(),
    );
  }

  /// Settles [amount] of the loan (partial settles keep the rest open on
  /// updated servers). [currency] null → the loan's own currency.
  Future<Map<String, dynamic>> settleLoan({
    required int loanId,
    required num amount,
    String? currency,
    String method = 'manual',
    String notes = '',
    String? idempotencyKey,
  }) async {
    final res = await _api.post(
      '/api/v1/loans/$loanId/settle',
      headers: idempotencyHeaders(idempotencyKey),
      body: {
        'amount': amount,
        if (currency != null && currency.isNotEmpty) 'currency': currency,
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

  Future<List<Map<String, dynamic>>> financialReport(String slug) async =>
      (await financialReportTable(slug)).rows;

  /// A report with the server's Arabic `columns` (fix2; `[]` on older
  /// servers — the screen then labels the keys itself).
  Future<FinancialReportTable> financialReportTable(String slug) async {
    final res = await _api.get('/api/v1/reports/$slug');
    return FinancialReportTable.fromResponse(res);
  }

  Future<Uint8List> exportFinancialReportCsv(String slug) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/reports/$slug/export.csv',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<Uint8List> exportFinancialReportXlsx(String slug) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/reports/$slug/export.xlsx',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<Uint8List> exportFinancialReportPdf(String slug) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/reports/$slug/export.pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<List<Map<String, dynamic>>> reportSnapshots({
    String reportType = '',
  }) async {
    final res = await _api.get(
      '/api/v1/reports/snapshots',
      query: {
        if (reportType.isNotEmpty)
          'report_type': reportSnapshotType(reportType),
        'limit': 20,
      },
    );
    return _items(res);
  }

  Future<Map<String, dynamic>> createReportSnapshot(String reportType) async {
    final res = await _api.post(
      '/api/v1/reports/snapshots',
      body: {
        'report_type': reportSnapshotType(reportType),
        'parameters': {'source': 'flutter'},
      },
    );
    return _object(res, 'snapshot');
  }
}

class LoansPage {
  const LoansPage({
    required this.items,
    required this.hasMore,
    this.totals,
    this.totalCount,
  });

  final List<LoanEntry> items;
  final bool hasMore;

  /// Server totals for every loan matching the filter (null on old servers).
  final LoanTotals? totals;
  final int? totalCount;
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

/// One financial report: its rows and the server's ordered column labels.
class FinancialReportTable {
  const FinancialReportTable({this.rows = const [], this.columns = const []});

  final List<Map<String, dynamic>> rows;

  /// `(key, Arabic label)` in the server's order.
  final List<(String, String)> columns;

  factory FinancialReportTable.fromResponse(Map<String, dynamic> res) {
    final data = res['data'];
    final raw = data is Map ? data['columns'] : null;
    final cols = <(String, String)>[];
    if (raw is List) {
      for (final c in raw.whereType<Map>()) {
        final key = '${c['key'] ?? ''}'.trim();
        if (key.isEmpty) continue;
        cols.add((key, '${c['label'] ?? key}'.trim()));
      }
    }
    return FinancialReportTable(rows: _items(res), columns: cols);
  }
}

/// What POST /loans answered.
class LoanCreateOutcome {
  const LoanCreateOutcome({
    required this.loan,
    this.pendingApproval = false,
    this.message = '',
  });

  /// The recorded loan (id 0 when it waits for approval).
  final LoanEntry loan;

  /// 202: the owner must approve it first — nothing was recorded yet.
  final bool pendingApproval;

  /// The server's Arabic message ('' on older servers).
  final String message;
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
