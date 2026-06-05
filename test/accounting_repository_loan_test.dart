import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/accounting/data/accounting_repository.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'login-token';

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
  String method = '';
  String path = '';
  Map<String, dynamic> body = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
    }
    if (chunks.isNotEmpty) {
      body = jsonDecode(utf8.decode(chunks)) as Map<String, dynamic>;
    }
    return ResponseBody.fromString(
      jsonEncode({
        'ok': true,
        'data': {
          'loan': {
            'id': 4,
            'subscriber_id': 9,
            'username': body['username'],
            'duration_minutes': 1440,
            'amount': body['amount'],
            'currency': body['currency'],
            'reason': body['reason'],
            'status': 'open',
          },
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('AccountingRepository sends debt-from-days loan contract', () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = AccountingRepository(client);

    final loan = await repo.createLoan(
      username: 'ali',
      days: 3,
      amount: 15,
      currency: 'ILS',
      reason: 'دين تمديد',
      priceFromDays: true,
      applyToRadius: false,
      dryRun: true,
    );

    expect(adapter.method, 'POST');
    expect(adapter.path, '/api/v1/loans');
    expect(adapter.body, {
      'username': 'ali',
      'hours': 0,
      'days': 3,
      'amount': 15,
      'currency': 'ILS',
      'reason': 'دين تمديد',
      'price_from_days': true,
      'apply_to_radius': false,
      'dry_run': true,
    });
    expect(loan.username, 'ali');
    expect(loan.amount, 15);
  });
}
