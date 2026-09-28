import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/features/accounting/presentation/loans_center_screen.dart';
import 'package:hoberadius_app/features/cards/data/cards_repository.dart';
import 'package:hoberadius_app/features/distributors/data/distributors_repository.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_detail_screen.dart';

import 'support/fake_api.dart';

FakeHandler _distributorServer({double debt = 15, double balance = 3}) => (r) {
      if (r.path.endsWith('/summary')) {
        return FakeResponse.ok({
          'summary': {
            'distributor': {'id': 41, 'name': 'st13 dist', 'status': 'active'},
            'balance': balance,
            'debt_balance': debt,
          },
        });
      }
      if (r.path == '/api/v1/cards/batches') {
        return FakeResponse.ok({
          'items': [
            {'id': 63, 'batch_code': 'B-20260928-0052'},
          ],
          'total': 1,
        });
      }
      if (r.method == 'POST') {
        return FakeResponse.ok({'entry': {}}, status: 201);
      }
      return FakeResponse.ok({'items': <dynamic>[]});
    };

Future<RecordingAdapter> _pumpDetail(
  WidgetTester tester, {
  double debt = 15,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final adapter = RecordingAdapter(_distributorServer(debt: debt));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DistributorDetailScreen(distributorId: 41),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

Finder _field(String label) => find.byWidgetPredicate(
      (w) =>
          w is TextField && (w.decoration?.labelText ?? '').startsWith(label),
    );

void main() {
  testWidgets('owner rule: payment defaults to «خصم من الدين» with debt',
      (tester) async {
    final adapter = await _pumpDetail(tester);
    expect(find.textContaining('خصم من الدين'), findsWidgets);
    await tester.enterText(_field('المبلغ'), '10');
    await tester.tap(find.text('تسجيل الحركة'));
    await tester.pumpAndSettle();
    final post = adapter.where('POST', '/settle').single;
    expect(post.jsonBody['apply_to'], 'debt');
    expect(post.jsonBody['direction'], 'credit');
    expect(post.jsonBody.containsKey('currency'), isFalse); // no JOD
  });

  testWidgets('«خصم من الدين» above the debt is refused on the phone',
      (tester) async {
    final adapter = await _pumpDetail(tester);
    await tester.enterText(_field('المبلغ'), '40');
    await tester.tap(find.text('تسجيل الحركة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('أكبر من الدين'), findsOneWidget);
    expect(adapter.where('POST', '/settle'), isEmpty);
    // switching to «إضافة للرصيد» sends apply_to=balance
    await tester.tap(find.textContaining('إضافة للرصيد ('));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل الحركة'));
    await tester.pumpAndSettle();
    expect(
      adapter.where('POST', '/settle').single.jsonBody['apply_to'],
      'balance',
    );
  });

  testWidgets('M2: «ربط حزمة» accepts the visible batch code', (tester) async {
    final adapter = await _pumpDetail(tester);
    await tester.enterText(_field('رقم أو كود الحزمة'), 'B-20260928-0052');
    await tester.tap(find.text('ربط الحزمة'));
    await tester.pumpAndSettle();
    final post = adapter.where('POST', '/assign-batch').single;
    expect(post.jsonBody['batch_id'], 63);
  });

  test('M2: unknown code resolves to null; numeric id passes through',
      () async {
    final adapter = RecordingAdapter(_distributorServer());
    final cards = CardsRepository(fakeApiClient(adapter));
    expect(await resolveBatchId(cards, '63'), 63);
    expect(await resolveBatchId(cards, 'B-NOPE'), isNull);
  });

  test('A11 F-13: distributors list pages past 200', () async {
    final adapter = RecordingAdapter((r) {
      final offset = int.parse('${r.query['offset']}');
      final n = (230 - offset).clamp(0, 200);
      return FakeResponse.ok({
        'items': [
          for (var i = 0; i < n; i++) {'id': offset + i + 1, 'name': 'd$i'},
        ],
      });
    });
    final all = await DistributorsRepository(fakeApiClient(adapter)).list();
    expect(all, hasLength(230));
  });

  test('M7: English field errors name the field', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.error(
        422,
        'validation_error',
        'credit_limit must be >= 0',
      ),
    );
    try {
      await fakeApiClient(adapter).post('/api/v1/distributors', body: {});
      fail('should throw');
    } on ApiException catch (e) {
      expect(visibleErrorMessage(e), contains('credit_limit'));
    }
  });

  testWidgets('M3/M7: loan dialog keeps inputs on error; currency is a list',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = RecordingAdapter((r) {
      if (r.method == 'POST') {
        return FakeResponse.error(
          422,
          'validation_error',
          'المشترك غير موجود.',
        );
      }
      return FakeResponse.ok({'items': <dynamic>[]});
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: LoansCenterScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل سلفة أو دين').first);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    await tester.enterText(_field('اسم المستخدم'), 'ghost');
    // turn the safe preview off, then submit for real
    await tester.tap(find.text('تجربة آمنة (معاينة فقط)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل').last);
    await tester.pumpAndSettle();
    expect(find.text('المشترك غير موجود.'), findsOneWidget);
    expect(find.text('ghost'), findsOneWidget); // still open, input kept
  });
}
