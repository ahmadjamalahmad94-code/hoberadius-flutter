// ZERO round, team w3 — app↔web parity defects (see the server's
// tests/test_zero_w3.py for the API side).
//
// 1. recycle bin: «أرشفة نهائية» (always a 404) → the web «حذف نهائي»
//    (card batches, owner only, typed confirmation).
// 2. backups: Drive linked through the customer-portal SSO link, no device
//    flow; 3. «تشغيل نسخة» = the web run-all (+ full mode).
// 4. tickets: no «طلب خدمة» in the generic form; one label map with the web.
// 5. SaaS create: blank numeric fields are not sent as 0.
// 6. invoices: shown in the row's own currency.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/backups/presentation/backups_screen.dart';
import 'package:hoberadius_app/features/invoices/domain/invoice_model.dart';
import 'package:hoberadius_app/features/recycle_bin/domain/recycle_bin_model.dart';
import 'package:hoberadius_app/features/recycle_bin/presentation/recycle_bin_screen.dart';
import 'package:hoberadius_app/features/saas_modules/application/saas_modules_catalog.dart';
import 'package:hoberadius_app/features/saas_modules/presentation/widgets/saas_create_dialog.dart';
import 'package:hoberadius_app/features/tickets/domain/ticket_model.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _me({bool owner = false, List<String> perms = const []}) =>
    {
      'admin': {
        'id': owner ? 1 : 7,
        'username': owner ? 'owner' : 'm7',
        'is_owner': owner,
        'is_co_owner': false,
        'is_original_owner': owner,
        'is_super_admin': owner,
      },
      'permissions': perms,
      'grants': {
        'actions': <String, bool>{},
        'sections': <String, String>{},
        'view_all_subscribers': false,
      },
    };

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required RecordingAdapter adapter,
  required Map<String, dynamic> me,
}) async {
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        permissionsProvider.overrideWith(
          (ref) => PermissionsController(ref)..apply(me),
        ),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _item(String type, int id, String label) => {
  'entity_type': type,
  'id': id,
  'label': label,
  'status': 'deleted',
  'deleted_at': '2026-10-01T10:00:00Z',
  'restore_allowed': true,
  'retention_expired': false,
};

void main() {
  setUpAll(() async => initializeDateFormatting('en'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('1. recycle bin: real permanent delete', () {
    RecordingAdapter api() => RecordingAdapter((r) {
      if (r.path.endsWith('/purge')) {
        return FakeResponse.ok({'purged': true, 'cards': 40, 'batch': 1});
      }
      return FakeResponse.ok({
        'items': [
          _item('card_batches', 5, 'حزمة مسرّبة'),
          _item('subscribers', 9, 'ali'),
        ],
      });
    });

    testWidgets('owner: «حذف نهائي» only on the batch, typed, → /purge', (
      tester,
    ) async {
      final adapter = api();
      await _pump(
        tester,
        const RecycleBinScreen(),
        adapter: adapter,
        me: _me(owner: true),
      );
      expect(find.text('أرشفة'), findsNothing);
      expect(find.text('حذف نهائي'), findsOneWidget);

      await tester.ensureVisible(find.text('حذف نهائي'));
      await tester.tap(find.text('حذف نهائي'));
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('recycle-purge-submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('recycle-purge-confirm')),
        'حذف',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('recycle-purge-confirm')),
        recyclePurgeConfirmPhrase,
      );
      await tester.pump();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(
        adapter.where('POST', '/api/v1/recycle-bin/card_batches/5/purge'),
        hasLength(1),
      );
      expect(adapter.where('POST', '/archive'), isEmpty);
    });

    testWidgets('a manager never sees it (owner-only on the web)', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecycleBinScreen(),
        adapter: api(),
        me: _me(perms: ['cards.restore', 'users.create']),
      );
      expect(find.text('حذف نهائي'), findsNothing);
      expect(find.text('أرشفة'), findsNothing);
    });

    test('rules', () {
      final batch = RecycleBinItem.fromJson(_item('card_batches', 1, 'b'));
      final sub = RecycleBinItem.fromJson(_item('subscribers', 2, 's'));
      expect(canPurgeRecycleItem(batch, ownerLike: true), isTrue);
      expect(canPurgeRecycleItem(batch, ownerLike: false), isFalse);
      expect(canPurgeRecycleItem(sub, ownerLike: true), isFalse);
      expect(recyclePurgeConfirmMatches('  حذف  نهائي '), isTrue);
      expect(recyclePurgeConfirmMatches('حذف'), isFalse);
    });
  });

  group('2+3. backups', () {
    RecordingAdapter api() => RecordingAdapter((r) {
      if (r.path.endsWith('/backups/run-all')) {
        return FakeResponse.ok({
          'ok': true,
          'mode': 'full',
          'steps': [
            {
              'key': 'local',
              'label': 'نسخة محلية',
              'status': 'success',
              'message': 'تم إنشاء النسخة المحلية والتحقق منها.',
            },
            {
              'key': 'panel',
              'label': 'لوحة التراخيص',
              'status': 'skipped',
              'message': 'الخدمة غير مفعّلة (خدمة مدفوعة).',
            },
            {
              'key': 'drive',
              'label': 'جوجل درايف',
              'status': 'skipped',
              'message': 'غير مربوط — اربط جوجل درايف من بوابة العميل.',
            },
          ],
        });
      }
      if (r.path.endsWith('/google-drive/portal-link')) {
        return FakeResponse.ok({'url': 'https://panel.example/sso?t=1'});
      }
      return FakeResponse.ok({
        'job': {'id': 1, 'last_status': 'never_run'},
        'recent_runs': <dynamic>[],
        'google_drive': {
          'configured': true,
          'connected': false,
          'status': 'not_connected',
          'message_ar': 'جوجل درايف غير مربوط — اربطه من بوابة العميل.',
          'link_via': 'customer_portal',
        },
      });
    });

    testWidgets('«تشغيل نسخة» is the web run-all, with the full mode', (
      tester,
    ) async {
      final adapter = api();
      await _pump(
        tester,
        const BackupsScreen(),
        adapter: adapter,
        me: _me(owner: true),
      );
      await tester.tap(find.text('تشغيل نسخة'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('backup-full-mode')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('backup-run-confirm')));
      await tester.pumpAndSettle();

      final runs = adapter.where('POST', '/api/v1/backups/run-all').toList();
      expect(runs, hasLength(1));
      expect(runs.single.jsonBody['mode'], 'full');
      expect(
        adapter
            .where('POST', '/api/v1/backups/run')
            .where((r) => r.path.endsWith('/backups/run')),
        isEmpty,
      );
      expect(find.textContaining('لوحة التراخيص'), findsWidgets);
    });

    testWidgets('«ربط جوجل درايف» opens the customer-portal SSO link', (
      tester,
    ) async {
      final adapter = api();
      await _pump(
        tester,
        const BackupsScreen(),
        adapter: adapter,
        me: _me(owner: true),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'ربط جوجل درايف'));
      await tester.pumpAndSettle();
      expect(
        adapter.where('POST', '/api/v1/backups/google-drive/portal-link'),
        hasLength(1),
      );
      expect(adapter.where('POST', '/google-drive/connect'), isEmpty);
      expect(adapter.where('POST', '/google-drive/poll'), isEmpty);
      expect(find.text('https://panel.example/sso?t=1'), findsOneWidget);
    });
  });

  group('4. tickets', () {
    test('the generic form has no «طلب خدمة» and the web labels', () {
      expect(ticketCreateCategories.keys, [
        'general',
        'billing',
        'connection',
        'hardware',
        'complaint',
      ]);
      expect(ticketCreateCategories.containsKey('service_request'), isFalse);
      expect(ticketCategoryLabel('billing'), 'الفواتير والدفع');
      expect(ticketCategoryLabel('hardware'), 'الأجهزة والمعدّات');
      expect(ticketCategoryLabel('service_request'), 'طلب خدمة');
    });
  });

  group('5. SaaS create body', () {
    test('a blank numeric field is left out, not 0', () {
      final def = kSaasModules['vouchers']!;
      final body = saasCreateBody(def, {
        'amount': '5',
        'count': '2',
        'plan_id': '  ',
      });
      expect(body, {'amount': 5, 'count': 2});
      expect(body.containsKey('plan_id'), isFalse);
      final services = saasCreateBody(kSaasModules['services']!, {
        'subscriber_id': '',
        'name': 'راوتر',
        'rent_per_month': '',
      });
      expect(services.containsKey('subscriber_id'), isFalse);
      expect(services.containsKey('rent_per_month'), isFalse);
      expect(services['name'], 'راوتر');
    });
  });

  group('6. invoice currency', () {
    test('the row currency wins; older servers fall back to the tenant', () {
      final jod = InvoiceRecord.fromJson({
        'id': 1,
        'amount': 7,
        'currency': 'jod',
      });
      final legacy = InvoiceRecord.fromJson({'id': 2, 'amount': 7});
      expect(jod.currencyOr('ILS'), 'JOD');
      expect(legacy.currencyOr('ILS'), 'ILS');
    });
  });
}
