import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/auth_controller.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/core/router/pop_on_route_change.dart';
import 'package:hoberadius_app/features/accounting/domain/accounting_model.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/admin_control/domain/admin_control_model.dart';
import 'package:hoberadius_app/features/cards/data/cards_repository.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';
import 'package:hoberadius_app/features/cards/print/application/quick_print_controller.dart';
import 'package:hoberadius_app/features/cards/print/data/quick_print_repository.dart';
import 'package:hoberadius_app/features/cards/print/domain/quick_print_form.dart';
import 'package:hoberadius_app/features/distributors/data/distributors_repository.dart';
import 'package:hoberadius_app/features/revenue/domain/revenue_model.dart';
import 'package:hoberadius_app/features/shell/shell_scaffold.dart';
import 'package:hoberadius_app/features/tools/domain/tools_models.dart';

import 'support/fake_api.dart';

class _Tokens implements TokenStorage {
  _Tokens(this.token);
  String? token;
  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String t) async => token = t;
}

class _Endpoint implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

void main() {
  group('1 — currency', () {
    test('fallback is ILS (server default_currency)', () {
      expect(kDefaultCurrency, 'ILS');
      expect(normalizeCurrency(''), 'ILS');
    });

    test('settings system.currency wins over billing.currency', () {
      final snap = SettingsSnapshot.fromJson({
        'items': <dynamic>[],
        'settings': {'billing.currency': 'JOD'},
        'system': {
          'currency': 'ils',
          'currency_symbol': '₪',
          'currency_name': 'شيكل',
        },
      });
      expect(snap.systemCurrency, 'ILS');
      expect(snap.currencySymbol, '₪');
    });

    test('/api/admin/me system.currency is used right after restore', () async {
      final adapter = RecordingAdapter((r) {
        if (r.path == '/api/admin/me') {
          return FakeResponse.ok({
            'admin': {'id': 1, 'username': 'owner'},
            'system': {'currency': 'USD'},
          });
        }
        // settings still loading/failing → the session value is used
        return FakeResponse.error(500, 'server_error', 'x');
      });
      final c = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(_Tokens('t')),
          apiEndpointStorageProvider.overrideWithValue(_Endpoint()),
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
      );
      addTearDown(c.dispose);
      c.read(authControllerProvider);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(c.read(authControllerProvider).systemCurrency, 'USD');
      expect(c.read(sessionCurrencyProvider), 'USD');
      final sub = c.listen(tenantCurrencyProvider, (_, __) {});
      expect(c.read(tenantCurrencyProvider), 'USD');
      sub.close();
    });
  });

  test('2 — next batch id comes from meta.next_batch_id', () {
    final page = CardBatchOperationsPage.fromJson({
      'ok': true,
      'data': {
        'items': [
          {'id': 5},
        ],
        'meta': {'next_batch_id': 143},
      },
    });
    expect(page.nextBatchId, 143);
    final old = CardBatchOperationsPage.fromJson({
      'data': {'items': <dynamic>[]},
    });
    expect(old.nextBatchId, isNull);
  });

  group('3 — card checker', () {
    test('a username is sent as query only', () {
      expect(cardCheckQueryParams(' 482913 '), {'query': '482913'});
    });
    test('#id / id:id → card_id (+ query for older servers)', () {
      expect(cardCheckQueryParams('#77'), {'card_id': '77', 'query': '77'});
      expect(cardCheckQueryParams('ID: 9'), {'card_id': '9', 'query': '9'});
    });
    test('repository sends card_id', () async {
      final adapter = RecordingAdapter(
        (_) => FakeResponse.ok({
          'card': {'exists': true, 'id': 77, 'username': 'u'},
        }),
      );
      await CardsRepository(fakeApiClient(adapter)).checkCard('#77');
      expect(adapter.requests.single.query['card_id'], '77');
    });
  });

  test('5 — assign-batch sends batch_code and the resolved id', () async {
    final adapter = RecordingAdapter((_) => FakeResponse.ok({}));
    await DistributorsRepository(fakeApiClient(adapter)).assignBatch(
      41,
      batchId: 63,
      batchCode: 'B-20260928-0052',
    );
    final body = adapter.requests.single.jsonBody;
    expect(body['batch_id'], 63);
    expect(body['batch_code'], 'B-20260928-0052');
  });

  test('8 — general adjustments preview shape', () {
    final r = AdjustmentsReport.fromJson({
      'dry_run': true,
      'targets': 3,
      'not_found': ['ghost'],
      'would_succeed': 2,
      'would_fail': 1,
      'items': [
        {
          'username': 'a',
          'ok': true,
          'status': 'ok',
          'new_expire_at': '2026-10-01T10:00:00Z',
        },
        {'username': 'ghost', 'ok': false, 'status': 'not_found'},
      ],
    });
    expect(r.hasDetails, isTrue);
    expect(r.items.first.statusLabel, 'سينجح');
    expect(r.items.last.statusLabel, 'غير موجود');
    expect(r.notFound, ['ghost']);
    // old server: counters only
    expect(
      AdjustmentsReport.fromJson({'dry_run': true, 'matched': 3}).hasDetails,
      isFalse,
    );
  });

  group('9 — additive fields', () {
    test('card row carries locked_mac / used_by_mac', () {
      final c = CardItem.fromJson({
        'id': 1,
        'username': 'u',
        'locked_mac': 'AA:BB',
        'used_by_mac': 'CC:DD',
      });
      expect(c.lockedMac, 'AA:BB');
      expect(c.usedByMac, 'CC:DD');
    });

    test('loans totals split per currency', () {
      final t = LoanTotals.fromJson({
        'count': 2,
        'outstanding': 40,
        'mixed_currency': true,
        'by_currency': [
          {'currency': 'ILS', 'outstanding': 30},
          {'currency': 'USD', 'outstanding': 10},
        ],
      });
      expect(t.mixedCurrency, isTrue);
      expect(
        stripBidiMarks(formatByCurrency(t.outstandingByCurrency)),
        '30 ILS · 10 USD',
      );
    });

    test('revenue totals split per currency', () {
      final p = RevenuePage.fromJson({
        'data': {
          'items': <dynamic>[],
          'totals': {
            'collected': 50,
            'mixed_currency': true,
            'by_currency': [
              {'currency': 'ILS', 'total': 40},
              {'currency': 'USD', 'total': 10},
            ],
          },
        },
      });
      expect(p.mixedCurrency, isTrue);
      expect(p.collectedByCurrency.map((e) => e.currency), ['ILS', 'USD']);
    });

    test('print job cancel posts to /print-jobs/<id>/cancel; old server ok',
        () async {
      final adapter = RecordingAdapter(
        (_) => FakeResponse.error(405, 'method_not_allowed', 'x'),
      );
      await QuickPrintRepository(fakeApiClient(adapter)).cancelJob(12);
      expect(adapter.requests.single.path, '/api/v1/print-jobs/12/cancel');
    });
  });

  group('L5 — print price / page controls', () {
    test('batch price label', () {
      expect(
        batchPriceLabel({'price_per_card': 5, 'currency': 'ILS'}),
        '5 ILS',
      );
      expect(batchPriceLabel({'price_per_card': 0}), '');
    });
    test(
        'a page-layout change switches the preview to «الصفحة»; '
        '«إظهار السعر» fills the batch price', () async {
      final adapter = RecordingAdapter((r) {
        if (r.path.contains('/cards/batches/')) {
          return FakeResponse.ok({
            'batch': {'id': 7, 'price_per_card': 5, 'currency': 'ILS'},
          });
        }
        return FakeResponse.ok({'items': <dynamic>[], 'settings': {}});
      });
      // The preview rasterizer is a platform plugin: park it (never answers).
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('net.nfet.printing'),
        (_) => Completer<Object?>().future,
      );
      final ctl =
          QuickPrintController(QuickPrintRepository(fakeApiClient(adapter)), 7);
      addTearDown(ctl.dispose);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(ctl.state.mode, PreviewMode.card);
      ctl.updateSheet((x) => x.copyWith(columns: 3));
      expect(ctl.state.mode, PreviewMode.page);
      ctl.setShowPrice(true);
      expect(ctl.state.form.showPrice, isTrue);
      expect(ctl.state.form.priceText, '5 ILS');
    });

    test('price text travels in the form fields', () {
      final f = const QuickPrintForm().withPriceText(' 5 شيكل ');
      expect(f.priceText, '5 شيكل');
      expect(f.toFields()['price_text'], '5 شيكل');
    });
  });

  group('L10', () {
    test('scroll restore keeps trying while the page loads', () {
      final waiting = scrollRestoreStep(
        target: 900,
        maxExtent: 300,
        elapsed: const Duration(milliseconds: 800),
      );
      expect(waiting.done, isFalse);
      expect(waiting.jumpTo, 300);
      final ready = scrollRestoreStep(
        target: 900,
        maxExtent: 1400,
        elapsed: const Duration(seconds: 1),
      );
      expect((ready.jumpTo, ready.done), (900, true));
      final gaveUp = scrollRestoreStep(
        target: 900,
        maxExtent: 300,
        elapsed: const Duration(seconds: 5),
      );
      expect(gaveUp.done, isTrue);
    });

    testWidgets('a pushed PDF screen closes when the route changes (back)',
        (tester) async {
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/cards/1/print',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Text('HOME'),
            routes: [
              GoRoute(
                path: 'cards/1/print',
                builder: (ctx, __) => TextButton(
                  onPressed: () => Navigator.of(ctx, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PopOnRouteChange(
                        child: Scaffold(body: Text('PDF')),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('PDF'), findsOneWidget);
      router.go('/'); // what the browser back does to the router
      await tester.pumpAndSettle();
      expect(find.text('PDF'), findsNothing);
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
