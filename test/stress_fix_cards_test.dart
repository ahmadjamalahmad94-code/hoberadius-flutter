import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/idempotency.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/features/cards/application/cards_list_providers.dart';
import 'package:hoberadius_app/features/cards/data/cards_repository.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('H1: count cap 10,000 with an Arabic message', () {
    expect(validateCardCount(null), isNotNull);
    expect(validateCardCount(0), isNotNull);
    expect(validateCardCount(10000), isNull);
    expect(validateCardCount(1000000), contains('10000'));
  });

  test('cards stream: prefix/suffix rule mirrors the server', () {
    expect(normalizeCardAffix(' QA-٣ '), 'qa-3');
    expect(validateCardAffix('qa-'), isNull);
    expect(validateCardAffix('a.b@c_d'), isNull);
    expect(validateCardAffix('بادئة'), isNotNull);
    expect(validateCardAffix('😀'), isNotNull);
    expect(validateCardAffix('a/b'), isNotNull);
    expect(validateCardAffix('x' * 17), isNotNull);
  });

  test('«رقم فقط» sends login_without_password with password_length 0', () {
    final body = GenerateBatchRequest(
      planId: 3,
      count: 5,
      loginWithoutPassword: true,
    ).toBody();
    expect(body['login_without_password'], isTrue);
    expect(body['password_length'], 0);
    final normal = GenerateBatchRequest(planId: 3, count: 5).toBody();
    expect(normal.containsKey('login_without_password'), isFalse);
  });

  test('generate carries an Idempotency-Key', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.ok(
        {
          'batch': {'id': 1},
          'cards': [],
        },
        status: 201,
      ),
    );
    final repo = CardsRepository(fakeApiClient(adapter));
    await repo.generate(
      GenerateBatchRequest(planId: 3, count: 5),
      idempotencyKey: 'k-9',
    );
    expect(adapter.requests.single.headers[kIdempotencyHeader], 'k-9');
  });

  test('H1b: export pages through EVERY card of the batch', () async {
    final adapter = RecordingAdapter((r) {
      final offset = int.parse('${r.query['offset']}');
      final limit = int.parse('${r.query['limit']}');
      const total = 4500;
      final end = (offset + limit) > total ? total : offset + limit;
      return FakeResponse.ok({
        'items': [
          for (var i = offset; i < end; i++) {'id': i + 1, 'username': 'c$i'},
        ],
      });
    });
    final repo = CardsRepository(fakeApiClient(adapter));
    final all = await repo.allCardsOfBatch(138);
    expect(all, hasLength(4500));
    expect(
      adapter.requests.map((r) => '${r.query['offset']}'),
      ['0', '2000', '4000'],
    );
  });

  test('H1b: a server ignoring offset does not loop', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.ok({
        'items': [
          for (var i = 0; i < 2000; i++) {'id': i + 1, 'username': 'c$i'},
        ],
      }),
    );
    final repo = CardsRepository(fakeApiClient(adapter));
    final all = await repo.allCardsOfBatch(1);
    expect(all, hasLength(2000));
    expect(adapter.requests, hasLength(2));
  });

  test('M4: money shows the tenant currency, never a hardcoded ₪', () {
    expect(formatMoney(1234.5, 'JOD'), '1,234.5 JOD');
    expect(formatMoney(10), '10');
    expect(formatMoney(10, 'ILS').contains('₪'), isFalse);
    expect(formatWithCurrency(1234567.891, 'USD'), '1,234,567.89 USD');
  });

  testWidgets('H1: more than 1,000 cards asks for confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = RecordingAdapter(
      (_) => FakeResponse.ok(
        {
          'batch': {'id': 1},
          'cards': [],
        },
        status: 201,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CardBatchFormScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    // plan id, then count (see the form order)
    await tester.enterText(fields.at(1), '3');
    await tester.enterText(fields.at(2), '5000');
    await tester.tap(find.text('توليد').first);
    await tester.pumpAndSettle();
    expect(find.text('توليد عدد كبير من الكروت؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(adapter.where('POST', '/cards/generate'), isEmpty);
    await tester.enterText(fields.at(2), '1000000');
    await tester.tap(find.text('توليد').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('10000'), findsWidgets);
    expect(adapter.where('POST', '/cards/generate'), isEmpty);
  });

  testWidgets(
      'R05: defaults follow the plan (validity 0, devices 0, digits) — '
      'not «1 day», which gave 1-hour-plan cards 24 h', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = RecordingAdapter(
      (_) => FakeResponse.ok(
        {
          'batch': {'id': 1},
          'cards': [],
        },
        status: 201,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CardBatchFormScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '3');
    await tester.enterText(fields.at(2), '10');
    await tester.tap(find.text('توليد').first);
    await tester.pumpAndSettle();
    final body = adapter.where('POST', '/cards/generate').single.body as Map;
    expect(body['time_value'], 0);
    expect(body['device_count'], 0);
    expect(body['password_generation_type'], 'digits');
  });
}
