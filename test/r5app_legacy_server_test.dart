// r5app (round 5) — old-server regressions: the fix3 contracts must degrade
// gracefully on a panel that has not been updated yet.

import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';
import 'package:hoberadius_app/features/plans/data/plans_repository.dart';

import 'support/fake_api.dart';

void main() {
  group('r5app: plans picker on an old server', () {
    test('a 404 on the lite route falls back to /api/v1/profiles', () async {
      final adapter = RecordingAdapter((req) {
        if (req.path.endsWith('/plans/options')) {
          // What a real HobeRadius panel answers for an unknown /api/v1
          // path: the same Arabic `not_found` envelope it uses for a
          // missing record. The fallback must still fire.
          return FakeResponse.error(
            404,
            'not_found',
            'المسار أو السجلّ المطلوب غير موجود.',
            details: const <String, dynamic>{},
          );
        }
        return FakeResponse.ok({
          'items': [
            {
              'id': 4,
              'name': 'باقة قديمة',
              'price': 10,
              'currency': 'ILS',
              'enabled': true,
            },
          ],
        });
      });
      final repo = PlansRepository(fakeApiClient(adapter));
      final opts = await repo.listForPicker();
      expect(opts, hasLength(1));
      expect(opts.single.name, 'باقة قديمة');
      expect(adapter.where('GET', '/profiles'), isNotEmpty);
    });

    test('a bodyless 404 (bare Flask router) also falls back', () async {
      final adapter = RecordingAdapter((req) {
        if (req.path.endsWith('/plans/options')) {
          return const FakeResponse(404, '<h1>Not Found</h1>');
        }
        return FakeResponse.ok({
          'items': [
            {'id': 1, 'name': 'باقة', 'price': 1, 'enabled': true},
          ],
        });
      });
      final repo = PlansRepository(fakeApiClient(adapter));
      expect(await repo.listForPicker(), hasLength(1));
    });

    test('a real 403 surfaces as-is — no silent fallback', () async {
      final adapter = RecordingAdapter(
        (req) => req.path.endsWith('/plans/options')
            ? FakeResponse.error(403, 'forbidden', 'لا تملك صلاحيةَ الباقات.')
            : FakeResponse.ok({'items': const []}),
      );
      final repo = PlansRepository(fakeApiClient(adapter));
      await expectLater(
        repo.listForPicker(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 403)
              .having((e) => e.message, 'message', contains('صلاحية')),
        ),
      );
      expect(adapter.where('GET', '/profiles'), isEmpty);
    });

    test('a 500 surfaces as-is — no silent fallback', () async {
      final adapter = RecordingAdapter(
        (req) => req.path.endsWith('/plans/options')
            ? FakeResponse.error(500, 'server_error', 'خطأٌ داخليّ.')
            : FakeResponse.ok({'items': const []}),
      );
      final repo = PlansRepository(fakeApiClient(adapter));
      await expectLater(repo.listForPicker(), throwsA(isA<ApiException>()));
      expect(adapter.where('GET', '/profiles'), isEmpty);
    });
  });

  group('r5app: dashboard on an old server', () {
    test('no sales_today key → the tile has nothing to show', () {
      final m = DashboardMetrics.fromJson({
        'subscribers': {'total': 10},
      });
      expect(m.salesToday, isNull);
    });

    test('sales_today present → the tile has data', () {
      final m = DashboardMetrics.fromJson({
        'subscribers': {'total': 10},
        'sales_today': {'cards_count': 3, 'money_visible': false},
      });
      expect(m.salesToday, isNotNull);
      expect(m.salesToday!.cardsCount, 3);
    });
  });
}
