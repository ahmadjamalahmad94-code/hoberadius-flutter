// r5app (round 5) — old-server regressions: the fix3 contracts must degrade
// gracefully on a panel that has not been updated yet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/format/arabic_plural.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';
import 'package:hoberadius_app/features/audit/data/audit_repository.dart';
import 'package:hoberadius_app/features/audit/domain/audit_model.dart';
import 'package:hoberadius_app/features/audit/presentation/audit_list_screen.dart';
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

  group('r5app: audit log action names are Arabic', () {
    testWidgets('an unknown server action code is not shown raw in English',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditListProvider.overrideWith((ref) async => [
                  AuditEvent.fromJson(const {
                    'id': 1,
                    'actor': 'admin',
                    'action': 'card_print_template.export_pdf',
                    'target_type': 'card_print_template',
                    'target_id': '3',
                    'created_at': '2026-09-28T11:45:25Z',
                  }),
                  AuditEvent.fromJson(const {
                    'id': 2,
                    'actor': 'admin',
                    'action': 'extend_time',
                    'target_type': 'subscriber',
                    'target_id': '7',
                    'created_at': '2026-09-28T12:54:43Z',
                  }),
                ]),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: AuditListScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('extend time'), findsNothing);
      expect(find.textContaining('card print template'), findsNothing);
      expect(find.textContaining('تمديد'), findsWidgets);
      expect(find.textContaining('تصدير'), findsWidgets);
    });
  });

  group('r5app: Arabic adjective agreement', () {
    String unread(int n) =>
        '${arCount(n, arNotification, showOne: true)} '
        '${arAgree(n, one: 'غير مقروء', two: 'غير مقروءين', many: 'غير مقروءة')}';

    test('the adjective follows the count, not one fixed form', () {
      expect(unread(1), '1 إشعار غير مقروء');
      expect(unread(2), 'إشعاران غير مقروءين');
      expect(unread(7), '7 إشعارات غير مقروءة');
      expect(unread(11), '11 إشعارًا غير مقروء');
      expect(unread(100), '100 إشعار غير مقروء');
    });
  });
}
