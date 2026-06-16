import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/business_ops/data/business_ops_repository.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'token';

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class _MemoryEndpointStorage implements ApiEndpointStorage {
  String baseUrl = 'http://127.0.0.1:5000';

  @override
  Future<String> readBaseUrl() async => baseUrl;

  @override
  Future<void> writeBaseUrl(String baseUrl) async => this.baseUrl = baseUrl;
}

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    final method = options.method;
    final data = switch ('$method $path') {
      'GET /api/v1/business/summary' => {
          'wallets': 3,
          'wallet_balance': '120.50',
          'ledger_entries': 9,
          'ledger_total': '880.00',
          'events': 12,
          'price_snapshots': 4,
          'revenue_records': 7,
        },
      'GET /api/v1/finance/ledger' => {
          'items': [
            {
              'id': 42,
              'entry_type': 'correction',
              'debit_account': 'cash',
              'credit_account': 'revenue',
              'amount': '15.00',
              'currency': 'JOD',
              'actor_type': 'admin',
              'actor_id': 2,
              'target_type': 'subscriber',
              'target_id': 18,
              'reference_type': 'payment',
              'reference_id': 5,
              'created_at': '2026-06-16T09:00:00',
            },
          ],
          'count': 1,
        },
      'POST /api/v1/finance/ledger/corrections' => {
          'entry': {
            'id': 43,
            'entry_type': 'correction',
            'debit_account': 'cash',
            'credit_account': 'revenue',
            'amount': '15.00',
            'currency': 'JOD',
          },
        },
      'GET /api/v1/pricing/snapshots' => {
          'items': [
            {
              'id': 7,
              'reference_type': 'package',
              'reference_id': 3,
              'package_id': 3,
              'retail_price': '20.00',
              'wholesale_price': '12.00',
              'effective_price': '18.00',
              'discount_amount': '2.00',
              'currency': 'JOD',
              'captured_at': '2026-06-16T10:00:00',
              'captured_by_type': 'admin',
              'captured_by_id': 2,
            },
          ],
          'count': 1,
        },
      _ => {
          'snapshot': {
            'id': 8,
            'reference_type': 'package',
            'package_id': 3,
            'retail_price': '20.00',
            'wholesale_price': '12.00',
            'effective_price': '20.00',
            'discount_amount': '0.00',
            'currency': 'JOD',
          },
        },
    };
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('BusinessOpsRepository wires summary, ledger, and pricing endpoints',
      () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = BusinessOpsRepository(client);

    final summary = await repo.summary();
    final ledger = await repo.listLedger(entryType: 'correction');
    final correction = await repo.createCorrection(
      debitAccount: 'cash',
      creditAccount: 'revenue',
      amount: 15,
      currency: 'JOD',
      targetType: 'subscriber',
      targetId: 18,
      referenceType: 'payment',
      referenceId: 5,
      reason: 'تصحيح دفعة مكررة',
    );
    final snapshots = await repo.listSnapshots(referenceType: 'package');
    final captured = await repo.captureSnapshot(
      referenceType: 'package',
      packageId: 3,
      retailPrice: 20,
      wholesalePrice: 12,
      discountAmount: 0,
      currency: 'JOD',
    );

    expect(summary.wallets, 3);
    expect(summary.walletBalance, '120.50');
    expect(summary.ledgerTotal, '880.00');
    expect(summary.priceSnapshots, 4);

    expect(ledger.single.id, 42);
    expect(ledger.single.isCorrection, isTrue);
    expect(ledger.single.amount, '15.00');
    expect(ledger.single.targetId, 18);

    expect(correction.id, 43);
    expect(correction.entryType, 'correction');

    expect(snapshots.single.id, 7);
    expect(snapshots.single.retailPrice, '20.00');
    expect(snapshots.single.effectivePrice, '18.00');

    expect(captured.id, 8);

    expect(
      adapter.requests.map((r) => '${r.method} ${r.path}'),
      [
        'GET /api/v1/business/summary',
        'GET /api/v1/finance/ledger',
        'POST /api/v1/finance/ledger/corrections',
        'GET /api/v1/pricing/snapshots',
        'POST /api/v1/pricing/snapshots',
      ],
    );
    expect(adapter.requests[1].queryParameters, {
      'entry_type': 'correction',
      'limit': 100,
    });
    expect(adapter.requests[2].data, {
      'debit_account': 'cash',
      'credit_account': 'revenue',
      'amount': 15,
      'currency': 'JOD',
      'target_type': 'subscriber',
      'target_id': 18,
      'reference_type': 'payment',
      'reference_id': 5,
      'metadata': {'reason': 'تصحيح دفعة مكررة', 'source': 'flutter'},
    });
    expect(adapter.requests[3].queryParameters, {
      'reference_type': 'package',
      'limit': 100,
    });
    expect(adapter.requests[4].data, {
      'reference_type': 'package',
      'package_id': 3,
      'retail_price': 20,
      'wholesale_price': 12,
      'discount_amount': 0,
      'currency': 'JOD',
      'metadata': {'source': 'flutter'},
    });
  });
}
