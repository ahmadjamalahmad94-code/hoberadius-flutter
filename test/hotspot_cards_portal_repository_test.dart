import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/features/hotspot_cards_portal/data/hotspot_cards_portal_repository.dart';

class _MemoryEndpointStorage implements ApiEndpointStorage {
  _MemoryEndpointStorage(this.baseUrl);

  String baseUrl;

  @override
  Future<String> readBaseUrl() async => baseUrl;

  @override
  Future<void> writeBaseUrl(String baseUrl) async => this.baseUrl = baseUrl;
}

class _RecordedRequest {
  const _RecordedRequest({
    required this.path,
    required this.headers,
    required this.body,
  });

  final String path;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> body;
}

class _PortalAdapter implements HttpClientAdapter {
  _PortalAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions, Map<String, dynamic>)
      handler;
  final requests = <_RecordedRequest>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final rawBody = requestStream == null
        ? ''
        : await utf8.decoder.bind(requestStream).join();
    final body = rawBody.trim().isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(rawBody) as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          );
    requests.add(
      _RecordedRequest(
        path: options.path,
        headers: Map<String, dynamic>.from(options.headers),
        body: body,
      ),
    );
    return handler(options, body);
  }
}

ResponseBody _json(Map<String, dynamic> body, int status) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test('login uses public hotspot portal API without admin token', () async {
    final storage = _MemoryEndpointStorage('http://old.local');
    late _PortalAdapter adapter;
    adapter = _PortalAdapter((options, body) {
      expect(options.path, '/api/v1/hotspot/cards/login');
      expect(body['username'], 'card-user');
      expect(body['password'], 'secret');
      return _json(
        {
          'ok': true,
          'token': 'portal-token',
          'expires_in': 900,
          'user': {
            'id': 'card_user:1',
            'username': 'card-user',
            'display_name': 'مستخدم الكروت',
            'wallet_balance': '15.00',
            'currency': 'ILS',
          },
        },
        200,
      );
    });
    final dio = Dio(BaseOptions(validateStatus: (status) => true));
    dio.httpClientAdapter = adapter;

    final repo = HotspotCardsPortalRepository(storage, dio: dio);
    final result = await repo.login(
      baseUrl: 'https://hoberadius.com',
      username: 'card-user',
      password: 'secret',
      tenantId: 3,
    );

    expect(storage.baseUrl, 'https://hoberadius.com');
    expect(result.token, 'portal-token');
    expect(adapter.requests.single.headers['X-Tenant-Id'], '3');
    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });

  test('flat portal errors are translated to Arabic messages', () async {
    final storage = _MemoryEndpointStorage('https://hoberadius.com');
    final adapter = _PortalAdapter((options, body) {
      return _json(
        {
          'ok': false,
          'error': 'insufficient_balance',
          'message': 'insufficient_balance',
        },
        402,
      );
    });
    final dio = Dio(BaseOptions(validateStatus: (status) => true));
    dio.httpClientAdapter = adapter;

    final repo = HotspotCardsPortalRepository(storage, dio: dio);

    try {
      await repo.purchase(
        token: 'portal-token',
        catalogItemId: '10',
        clientRequestId: 'req-1',
      );
      fail('purchase should fail');
    } on ApiException catch (error) {
      expect(error.code, 'insufficient_balance');
      expect(error.message, 'رصيد المحفظة غير كافٍ لإتمام الشراء.');
      expect(error.message, isNot(contains('insufficient_balance')));
    }

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer portal-token',
    );
  });

  test('catalog and my-cards parse direct portal payloads', () async {
    final storage = _MemoryEndpointStorage('https://hoberadius.com');
    final adapter = _PortalAdapter((options, body) {
      if (options.path.endsWith('/catalog')) {
        return _json(
          {
            'ok': true,
            'items': [
              {
                'id': '8',
                'name': 'كرت يوم',
                'price': '10.00',
                'currency': 'ILS',
                'available': true,
              },
            ],
          },
          200,
        );
      }
      return _json(
        {
          'ok': true,
          'items': [
            {
              'purchase_id': '77',
              'package_id': '8',
              'package_name': 'كرت يوم',
              'amount': '10.00',
              'currency': 'ILS',
              'card': {
                'username': 'HP-77',
                'password': '9999',
              },
            },
          ],
        },
        200,
      );
    });
    final dio = Dio(BaseOptions(validateStatus: (status) => true));
    dio.httpClientAdapter = adapter;

    final repo = HotspotCardsPortalRepository(storage, dio: dio);

    final catalog = await repo.catalog(token: 'portal-token');
    final cards = await repo.myCards(token: 'portal-token');

    expect(catalog.single.title, 'كرت يوم');
    expect(cards.single.card.password, '9999');
    expect(adapter.requests, hasLength(2));
  });
}
