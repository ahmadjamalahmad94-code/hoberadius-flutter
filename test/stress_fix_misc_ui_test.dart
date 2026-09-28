import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/l10n/arabic_labels.dart';
import 'package:hoberadius_app/features/communications/data/communications_repository.dart';
import 'package:hoberadius_app/features/events/data/events_repository.dart';
import 'package:hoberadius_app/features/mikrotik/presentation/router_operations_screen.dart';
import 'package:hoberadius_app/features/operational_reports/domain/operational_report_catalog.dart';
import 'package:hoberadius_app/features/operational_reports/presentation/report_formatting.dart';
import 'package:hoberadius_app/features/revenue/domain/revenue_model.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';
import 'package:hoberadius_app/features/store_admin/data/store_admin_repository.dart';

import 'support/fake_api.dart';

/// Answers with a raw body (for invalid JSON such as Python's Infinity).
class _RawAdapter implements HttpClientAdapter {
  _RawAdapter(this.body);
  final String body;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        body,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
}

void main() {
  group('M1 — Infinity/NaN in JSON', () {
    test('decodeJsonTolerant reads non-finite numbers as null', () {
      final v = decodeJsonTolerant(
        '{"credits": Infinity, "debits": -Infinity, "net": NaN, '
        '"items": [1, NaN], "name": "Infinity"}',
      )! as Map;
      expect(v['credits'], isNull);
      expect(v['debits'], isNull);
      expect(v['net'], isNull);
      expect(v['items'], [1, null]);
      expect(v['name'], 'Infinity'); // strings untouched
    });

    test('a 200 with Infinity no longer looks like a network failure',
        () async {
      final api = fakeApiClient(RecordingAdapter((_) => FakeResponse.ok({})));
      api.dio.httpClientAdapter = _RawAdapter(
        jsonEncode({
          'ok': true,
          'data': {'rows': []},
        }).replaceFirst('[]', '[{"net": NaN}]'),
      );
      final res = await api.get('/api/v1/reports/profit-loss');
      expect(((res['data'] as Map)['rows'] as List).first['net'], isNull);
    });

    test('a truly broken body says «ردّ غير صالح», not «تعذّر الاتصال»',
        () async {
      final api = fakeApiClient(RecordingAdapter((_) => FakeResponse.ok({})));
      api.dio.httpClientAdapter = _RawAdapter('{"ok": true, "data": {');
      try {
        await api.get('/api/v1/reports/profit-loss');
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.message, contains('ردّ غير صالح'));
        expect(e.message, isNot(contains('الاتصال')));
      }
    });
  });

  test('L2 — router diagnostics are readable text, not a Dart map', () {
    final ok = formatRouterDiagnostics({
      'ok': true,
      'dialed_address': '10.10.0.1',
      'result': [
        {'host': '8.8.8.8', 'time': '12ms', 'status': null},
      ],
    });
    expect(ok, contains('الهدف: 10.10.0.1'));
    expect(ok, contains('host: 8.8.8.8'));
    expect(ok, isNot(contains('{')));
    final failed = formatRouterDiagnostics({
      'ok': false,
      'error': {'message': 'لا يستجيب الراوتر'},
    });
    expect(failed, 'فشل التشخيص: لا يستجيب الراوتر');
    expect(riskLevelLabel('ok'), 'سليم');
  });

  test('L3 — raw tokens and amounts are shown in Arabic / grouped', () {
    expect(rawTokenLabel('posted'), 'مرحّل');
    expect(rawTokenLabel('password_wrong'), 'كلمة مرور خاطئة');
    expect(rawTokenLabel('credit'), contains('دائن'));
    const amount = ReportColumn('a', 'x', kind: ReportColumnKind.amount);
    expect(formatReportCell(amount, 117.58999999999999), '117.59');
    expect(formatReportCell(amount, 2101001324598.793), '2,101,001,324,598.79');
    const text = ReportColumn('t', 'x');
    expect(formatReportCell(text, 'settlement'), 'تسوية');
  });

  test('L13 — a wallet created «غير مفعّلة» ends up inactive', () async {
    final adapter = RecordingAdapter((r) {
      final active = r.method == 'POST' ? 1 : r.jsonBody['active'];
      return FakeResponse.ok(
        {
          'payment_method': {
            'id': 7,
            'method': 'wallet',
            'label': 'x',
            'active': active,
          },
        },
        status: r.method == 'POST' ? 201 : 200,
      );
    });
    final repo = StoreAdminRepository(fakeApiClient(adapter));
    final m = await repo.createPaymentMethod(
      method: 'wallet',
      label: 'x',
      active: false,
    );
    expect(adapter.requests.first.jsonBody['active'], 0);
    expect(adapter.requests.last.method, 'PATCH');
    expect(m.active, isFalse);
  });

  test('misc — events «تحميل المزيد» uses before_id and de-duplicates',
      () async {
    final adapter = RecordingAdapter((r) {
      final before = r.query['before_id'];
      final start = before == null ? 200 : int.parse('$before') - 1;
      return FakeResponse.ok({
        'items': [
          for (var i = 0; i < 100; i++)
            {'id': start - i, 'category': 'system', 'severity': 'info'},
        ],
        'count': 100,
        'has_more': before == null,
        'next_before_id': start - 99,
      });
    });
    final repo = EventsRepository(fakeApiClient(adapter));
    final first = await repo.list();
    expect(first.hasMore, isTrue);
    final more = await repo.loadMore(first);
    expect('${adapter.requests.last.query['before_id']}', '101');
    expect(more.items, hasLength(200));
    expect(more.hasMore, isFalse);
  });

  test('misc — duplicate template key: overwrite only on purpose', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.ok(
        {
          'template': {'id': 1},
        },
        status: 201,
      ),
    );
    final repo = CommunicationsRepository(fakeApiClient(adapter));
    await repo.createTemplate(
      title: 't',
      channel: 'sms',
      subject: '',
      body: 'b',
    );
    await repo.createTemplate(
      title: 't',
      channel: 'sms',
      subject: '',
      body: 'b',
      overwrite: true,
    );
    expect(adapter.requests.first.jsonBody.containsKey('overwrite'), isFalse);
    expect(adapter.requests.last.jsonBody['overwrite'], isTrue);
  });

  test('M8 — «المركز المالي» reads the fixed revenue shape and totals', () {
    final page = RevenuePage.fromJson({
      'ok': true,
      'data': {
        'items': [
          {
            'id': 9,
            'source_type': 'subscriber_payment',
            'collected_amount': 5,
            'status': 'posted',
          },
          {
            'id': 3,
            'source_type': 'card_batch',
            'collected_amount': 20,
            'status': 'posted',
          },
        ],
        'count': 2,
        'totals': {'collected': 1553.3},
      },
    });
    expect(page.items, hasLength(2));
    expect(page.items.first.sourceLabel, startsWith('دفعة مشترك'));
    expect(page.summary.totalCollected, closeTo(1573.3, 0.001));
  });

  test('L9 — the mobile app bar names the page, not «لوحة التحكم»', () {
    expect(mobileTitleForLocation('/notifications', 0), 'الإشعارات');
    expect(mobileTitleForLocation('/', 0), mobileNavDestinations[0].label);
  });
}
