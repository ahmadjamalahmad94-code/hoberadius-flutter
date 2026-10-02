// FIX2 misc screens (R11 L-1…L-5, R09 N10/N13, R07 N10/N15): page titles,
// 360 px truncation, raw UTC ISO times, raw English tokens, raw Python
// errors and the RTL-garbled IPv4-mapped NAS address.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/format/server_time.dart';
import 'package:hoberadius_app/core/l10n/arabic_labels.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/backups/domain/backup_model.dart';
import 'package:hoberadius_app/features/backups/presentation/backups_screen.dart';
import 'package:hoberadius_app/features/business_ops/domain/business_ops_model.dart';
import 'package:hoberadius_app/features/business_ops/presentation/business_ops_screen.dart';
import 'package:hoberadius_app/features/cards/application/cards_list_providers.dart';
import 'package:hoberadius_app/features/cards/presentation/widgets/cards_list_toolbar.dart';
import 'package:hoberadius_app/features/communications/domain/communications_model.dart';
import 'package:hoberadius_app/features/communications/presentation/communications_screen.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_detail_screen.dart';
import 'package:hoberadius_app/features/events/presentation/events_center_screen.dart';
import 'package:hoberadius_app/features/mikrotik/presentation/router_operations_screen.dart';
import 'package:hoberadius_app/features/nas/presentation/nas_list_screen.dart';
import 'package:hoberadius_app/features/recycle_bin/domain/recycle_bin_model.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';
import 'package:hoberadius_app/features/tickets/domain/ticket_model.dart';
import 'package:hoberadius_app/features/tickets/presentation/tickets_list_screen.dart';
import 'package:hoberadius_app/features/wallets/presentation/wallets_screen.dart';
import 'package:hoberadius_app/shared/widgets/hub_layout.dart';

import 'support/fake_api.dart';

void _phone(WidgetTester tester, {double width = 360, double height = 640}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<RecordingAdapter> _pump(
  WidgetTester tester,
  Widget child,
  FakeHandler handler, {
  double width = 360,
  double height = 640,
  bool scroll = true,
}) async {
  _phone(tester, width: width, height: height);
  final adapter = RecordingAdapter(handler);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        tenantCurrencyProvider.overrideWith((ref) => 'ILS'),
      ],
      child: MaterialApp(
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
          body: scroll
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: child,
                )
              : Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

/// The text of [finder] is on screen whole: not cut with «…», not scaled
/// down, on one line and inside the [screenWidth].
void _expectOneLineWhole(
  WidgetTester tester,
  Finder finder, {
  double screenWidth = 360,
  bool allowScaleDown = false,
}) {
  expect(finder, findsWidgets);
  for (final element in finder.evaluate()) {
    final p = element.renderObject! as RenderParagraph;
    expect(p.didExceedMaxLines, isFalse, reason: 'cut: ${p.text}');
    final natural = p.getMaxIntrinsicWidth(double.infinity);
    expect(
      natural,
      lessThanOrEqualTo(p.size.width + 0.5),
      reason: 'wrapped or clipped: ${p.text.toPlainText()}',
    );
    final global = MatrixUtils.transformRect(
      p.getTransformTo(null),
      Offset.zero & p.size,
    );
    expect(
      global.width / p.size.width,
      greaterThan(allowScaleDown ? 0.3 : 0.99),
      reason: 'scaled down: ${p.text.toPlainText()}',
    );
    expect(global.left, greaterThanOrEqualTo(-0.5));
    expect(global.right, lessThanOrEqualTo(screenWidth + 0.5));
  }
}

bool _anyTextContains(String needle) => find
    .byWidgetPredicate(
      (w) =>
          (w is Text && (w.data ?? '').contains(needle)) ||
          (w is RichText && w.text.toPlainText().contains(needle)),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  // ── 1) page titles (R11 L-4) ─────────────────────────────────────────
  group('mobile app bar title', () {
    test('backups / business-ops / wallets name their own page', () {
      expect(mobileTitleForLocation('/backups', 4), 'البيانات والحفظ والأرشفة');
      expect(mobileTitleForLocation('/business-ops', 4), 'مشغّلو الأعمال');
      expect(mobileTitleForLocation('/wallets', 4), 'الخزائن والمحافظ');
      expect(
        mobileTitleForLocation('/cards/recharge', 2),
        'بطاقات الشحن المسبق',
      );
      expect(
        mobileTitleForLocation('/router-programming/3', 4),
        'برمجة الراوتر',
      );
      // unchanged: tabs, menu items, dashboard
      expect(mobileTitleForLocation('/', 0), 'لوحة التحكم');
      expect(mobileTitleForLocation('/cards', 2), 'البطاقات');
      expect(mobileTitleForLocation('/nas', 4), 'أجهزة الشبكة');
      expect(mobileTitleForLocation('/notifications', 0), 'الإشعارات');
    });

    test('no routed shell page falls back to «لوحة التحكم»', () {
      final src = File('lib/core/router/app_router.dart').readAsStringSync();
      final shell = src.substring(src.indexOf('ShellRoute('));
      final paths = RegExp(r"path: '(/[^']*)'")
          .allMatches(shell)
          .map((m) => m.group(1)!)
          .where((p) => p != '/')
          .map((p) => p.replaceAll(RegExp(r':\w+'), '7'))
          .toList();
      expect(paths, contains('/backups'));
      for (final path in paths) {
        final idx = mobileNavIndexForLocation(path);
        expect(
          mobileTitleForLocation(path, idx),
          isNot('لوحة التحكم'),
          reason: path,
        );
      }
    });
  });

  // ── 2) 360 px truncation (R11 L-5, L-2, L-3; R09 N13; R07 N15) ────────
  group('labels fit at 360 px', () {
    test('ActionBar balances rows and never goes below the min width', () {
      expect(ActionBar.perRowFor(4, 300, 4), 2);
      expect(ActionBar.perRowFor(4, 800, 4), 4);
      expect(ActionBar.perRowFor(3, 300, 3), 3);
      expect(ActionBar.perRowFor(5, 300, 3), 3);
      expect(ActionBar.perRowFor(2, 90, 3), 1);
    });

    testWidgets('cards toolbar: «تطبيق» «CSV» «Excel» «PDF» whole at 360',
        (tester) async {
      await _pump(
        tester,
        CardsListToolbar(
          filters: const CardBatchOpsFilters(),
          selectedCount: 2,
          onFiltersChanged: (_) {},
          onExportCsv: () {},
          onExportXlsx: () {},
          onExportPdf: () {},
          onBulkAction: (_) {},
        ),
        (_) => FakeResponse.ok({}),
      );
      expect(tester.takeException(), isNull);
      // Owner 2026-10-02: «تطبيق» beside the search; «تصدير» beside the
      // status opens one menu with CSV / Excel / PDF.
      _expectOneLineWhole(tester, find.text('تطبيق'));
      _expectOneLineWhole(tester, find.text('تصدير'));
      await tester.tap(find.byKey(const ValueKey('cards-export-menu')));
      await tester.pumpAndSettle();
      for (final label in ['CSV', 'Excel', 'PDF']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      // The test font is ~2x wider than Cairo: a label may shrink, never cut.
      for (final label in ['أرشفة', 'استعادة', 'تحديث']) {
        _expectOneLineWhole(tester, find.text(label), allowScaleDown: true);
      }
    });

    testWidgets('wallets: the balances card shows every currency at 360',
        (tester) async {
      await _pump(
        tester,
        const WalletsScreen(),
        (r) => FakeResponse.ok({
          'items': [
            {
              'id': 1,
              'owner_type': 'company',
              'currency': 'ILS',
              'balance': '300',
              'status': 'active',
            },
            {
              'id': 2,
              'owner_type': 'company',
              'currency': 'USD',
              'balance': '12.5',
              'status': 'active',
            },
          ],
          'count': 2,
        }),
      );
      expect(tester.takeException(), isNull);
      final balances = find.textContaining('300 ₪\u2069 / ');
      expect(balances, findsOneWidget);
      final p = tester.renderObject<RenderParagraph>(balances);
      expect(p.didExceedMaxLines, isFalse);
      expect(p.text.toPlainText(), contains('12.50 دولار أمريكي'));
      _expectOneLineWhole(tester, find.text('الأرصدة المعروضة'));
    });

    testWidgets('business-ops ledger: one labelled card per entry at 360',
        (tester) async {
      await _pump(
        tester,
        const BusinessOpsScreen(),
        (r) {
          if (r.path.contains('/finance/ledger')) {
            return FakeResponse.ok({
              'items': [
                {
                  'id': 9,
                  'entry_type': 'payment',
                  'debit_account': 'cash',
                  'credit_account': 'wallet:4',
                  'amount': '25',
                  'currency': 'ILS',
                  'target_type': 'distributor',
                  'target_id': 1,
                  'reference_type': 'revenue:plan',
                  'created_at': '2026-09-29T01:35:23.057631Z',
                },
              ],
            });
          }
          return FakeResponse.ok({'items': <dynamic>[]});
        },
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(DataTable), findsNothing);
      _expectOneLineWhole(tester, find.text('نقدًا'));
      _expectOneLineWhole(tester, find.text('محفظة #4'));
      _expectOneLineWhole(tester, find.text('موزّع #1'));
      expect(find.text(ltrIsolate('revenue:plan')), findsOneWidget);
      for (final raw in ['cash', 'wallet:4', 'distributor #1', 'T01:35']) {
        expect(_anyTextContains(raw), isFalse, reason: raw);
      }
    });

    testWidgets(
        'distributor: «خصم من الدين (…)» stays on one line at 360; '
        '«تاريخ الربط» is formatted', (tester) async {
      const linkedAt = '2026-09-29T01:35:23.057631Z';
      await _pump(
        tester,
        const DistributorDetailScreen(distributorId: 41),
        (r) {
          if (r.path.endsWith('/summary')) {
            return FakeResponse.ok({
              'summary': {
                'distributor': {'id': 41, 'name': 'r11_dist'},
                'balance': 3,
                'debt_balance': 39,
              },
            });
          }
          if (r.path.endsWith('/batches')) {
            return FakeResponse.ok({
              'items': [
                {
                  'id': 5,
                  'batch_code': 'B-1',
                  'count': 10,
                  'used': 2,
                  'status': 'active',
                  'assigned_at': linkedAt,
                },
              ],
            });
          }
          return FakeResponse.ok({'items': <dynamic>[]});
        },
        height: 3000,
      );
      expect(tester.takeException(), isNull);
      // Stacked, each choice gets the full row (the test font is ~2x wider
      // than Cairo, so width — not the line count — is what is checked).
      final debt = find.textContaining('خصم من الدين (');
      final bal = find.textContaining('إضافة للرصيد (');
      expect(find.byType(SegmentedButton<String>), findsNothing);
      expect(
        tester.getTopLeft(debt).dy,
        greaterThan(tester.getBottomLeft(bal).dy),
      );
      for (final f in [debt, bal]) {
        final p = tester.renderObject<RenderParagraph>(f);
        expect(p.didExceedMaxLines, isFalse);
        expect(p.size.width, greaterThan(200)); // was ~130 per segment
      }
      expect(_anyTextContains(linkedAt), isFalse);
      expect(_anyTextContains('T01:35'), isFalse);
      expect(find.text(formatServerTimestamp(linkedAt)), findsOneWidget);
    });

    testWidgets('tickets: every status chip is on screen at 390',
        (tester) async {
      await _pump(
        tester,
        const TicketsListScreen(),
        (_) => FakeResponse.ok({'items': <dynamic>[], 'total': 0}),
        width: 390,
        height: 844,
      );
      expect(tester.takeException(), isNull);
      for (final label in ['محلولة', 'مغلقة', 'قيد المعالجة']) {
        _expectOneLineWhole(tester, find.text(label), screenWidth: 390);
      }
    });

    test('session length is compact enough for a third of a phone row', () {
      expect(compactSessionDuration(748), '12 د 28 ث');
      expect(compactSessionDuration(4920), '1 س 22 د');
      expect(compactSessionDuration(3 * 86400 + 4 * 3600), '3 ي 4 س');
      expect(compactSessionDuration(0), 'غير معروف');
    });

    testWidgets('InfoGrid: «المدة» value is whole at 360', (tester) async {
      await _pump(
        tester,
        InfoGrid(
          items: [
            InfoItem(
              icon: Icons.timer_outlined,
              label: 'المدة',
              value: compactSessionDuration(748),
            ),
            const InfoItem(icon: Icons.download, label: 'تنزيل', value: '1 MB'),
            const InfoItem(icon: Icons.upload, label: 'رفع', value: '2 MB'),
          ],
        ),
        (_) => FakeResponse.ok({}),
      );
      // The test font is ~2x wider than Cairo, so the cell may shrink the
      // value — but it is never cut with «…».
      _expectOneLineWhole(
        tester,
        find.text('12 د 28 ث'),
        allowScaleDown: true,
      );
    });
  });

  // ── 3) raw UTC ISO times ─────────────────────────────────────────────
  group('server timestamps', () {
    test('formatServerTimestamp: ISO → «yyyy-MM-dd HH:mm» on the panel clock',
        () {
      const iso = '2026-09-29T01:35:23.057631Z';
      final expected = parseServerDateTime(iso)!;
      final text = formatServerTimestamp(iso);
      expect(text, matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$')));
      expect(
        text,
        '${expected.year}-${expected.month.toString().padLeft(2, '0')}-'
        '${expected.day.toString().padLeft(2, '0')} '
        '${expected.hour.toString().padLeft(2, '0')}:'
        '${expected.minute.toString().padLeft(2, '0')}',
      );
      expect(formatServerTimestamp(''), '—');
      expect(formatServerTimestamp(null, empty: 'بدون وقت'), 'بدون وقت');
      expect(formatServerTimestamp('garbage'), 'garbage');
      expect(looksLikeServerTimestamp(iso), isTrue);
      expect(looksLikeServerTimestamp('B-1'), isFalse);
    });

    test('no screen prints a *_at string field raw', () {
      // Every String-typed `*At` field read by these screens goes through
      // formatServerTimestamp.
      const files = {
        'lib/features/network_devices/presentation/network_devices_screen.dart':
            ['item.lastCheckedAt}', 'session.expiresAt}'],
        'lib/features/network_policy/presentation/network_policy_screen.dart': [
          'item.finishedAt}',
          'item.createdAt}',
        ],
        'lib/features/router_alerts/presentation/router_alerts_screen.dart': [
          'router.lastPushAt}',
          'probe.lastReadingAt}',
        ],
        'lib/features/device_fingerprints/presentation/device_fingerprints_screen.dart':
            ['item.firstSeenAt}', 'item.lastSeenAt}'],
        'lib/features/distributors/presentation/distributor_detail_screen.dart':
            [': item.assignedAt'],
      };
      files.forEach((path, raws) {
        final src = File(path).readAsStringSync();
        for (final raw in raws) {
          final needle = raw.startsWith(':') ? raw : '\${$raw';
          expect(src.contains(needle), isFalse, reason: '$path $raw');
        }
      });
    });
  });

  // ── 4) raw English on /backups, /business-ops, /communications ─────────
  group('raw English → Arabic', () {
    test('tokens and ledger parties', () {
      expect(businessAccountLabel('cash'), 'نقدًا');
      expect(businessAccountLabel('wallet:4'), 'محفظة #4');
      expect(businessAccountLabel('distributor #1'), 'موزّع #1');
      expect(businessAccountLabel('revenue'), 'الإيرادات');
      expect(businessAccountLabel('card_batch #3'), 'حزمة بطاقات #3');
      expect(businessAccountLabel('zzz_unknown'), ltrIsolate('zzz_unknown'));
      expect(backupStatusLabel('never_run'), 'لم تُشغَّل بعد');
      expect(backupStatusLabel('whatever'), 'حالة غير معروفة');
      expect(communicationStatusLabel('skipped'), 'تم التخطّي');
      expect(communicationStatusLabel('bounced'), 'مرتدّ');
      expect(communicationStatusLabel('weird_state'), 'حالة غير معروفة');
      expect(communicationChannelLabel('in_app'), 'داخل التطبيق');
    });

    test('serverTextOrFallback never returns English', () {
      expect(
        serverTextOrFallback(
          'No local backup has been run yet.',
          fallback: 'x',
        ),
        'لم يتم تشغيل نسخة محلية بعد',
      );
      expect(
        serverTextOrFallback('SQLite backup failed: disk I/O', fallback: 'x'),
        'x',
      );
      expect(serverTextOrFallback('skipped', fallback: 'x'), 'تم التخطّي');
      expect(serverTextOrFallback('تمت النسخة', fallback: 'x'), 'تمت النسخة');
      expect(serverTextOrFallback('', fallback: 'x'), 'x');
    });

    testWidgets('/backups shows no never_run and no English message',
        (tester) async {
      await _pump(
        tester,
        const BackupsScreen(),
        (_) => FakeResponse.ok({
          'job': {
            'id': 1,
            'last_status': 'never_run',
            'last_message': 'No local backup has been run yet.',
          },
          'recent_runs': [
            {
              'id': 3,
              'status': 'failed',
              'path': '',
              'message': 'SQLite backup failed: disk I/O error',
              'created_at': '2026-09-29T00:00:00Z',
            },
          ],
          'google_drive': {
            'configured': true,
            'connected': true,
            'email': 'a@b.c',
            'last_upload_at': '2026-09-29T00:59:34.408075Z',
            'message_ar': 'مربوط',
          },
        }),
        height: 2000,
      );
      expect(tester.takeException(), isNull);
      for (final raw in [
        'never_run',
        'No local backup',
        'SQLite backup failed',
        '2026-09-29T00:59',
      ]) {
        expect(_anyTextContains(raw), isFalse, reason: raw);
      }
      expect(find.text('لم تُشغَّل بعد'), findsOneWidget);
      expect(find.text('لم يتم تشغيل نسخة محلية بعد'), findsOneWidget);
    });

    testWidgets('/communications delivery rows: skipped → Arabic',
        (tester) async {
      await _pump(
        tester,
        const CommunicationsScreen(),
        (_) => FakeResponse.ok({
          'summary': {'templates': 0, 'segments': 0, 'queued': 0},
          'deliveries': [
            {
              'id': 1,
              'channel': 'sms',
              'status': 'skipped',
              'recipient_type': 'subscriber',
              'recipient_id': 3,
              'subject': 'تنبيه',
              'body': 'نص',
              'error_message': 'no_phone',
              'created_at': '2026-09-29T00:00:00Z',
            },
            {
              'id': 2,
              'channel': 'sms',
              'status': 'failed',
              'recipient_type': 'subscriber',
              'recipient_id': 4,
              'subject': 'تنبيه ٢',
              'body': 'نص',
              'error_message': 'Gateway said: HTTP 500 upstream',
              'created_at': '2026-09-29T00:00:00Z',
            },
          ],
        }),
        height: 3000,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('تم التخطّي'), findsOneWidget);
      expect(_anyTextContains('skipped'), isFalse);
      expect(_anyTextContains('no_phone'), isFalse);
      expect(_anyTextContains('Gateway said'), isFalse);
      expect(_anyTextContains('لا يوجد رقم هاتف'), isTrue);
    });
  });

  // ── 5) Python / OS errors (R11 L-1) ─────────────────────────────────
  group('humanizeTechnicalError', () {
    test('rewrites errno fragments inside Arabic messages', () {
      expect(
        visibleErrorMessage(
          'تعذّر الاتصال بـ 10.10.0.1:8728 — [Errno 111] Connection refused',
        ),
        'تعذّر الاتصال بـ 10.10.0.1:8728 — '
        'رفض الراوتر الاتصال (المنفذ مغلق أو خدمة API معطّلة)',
      );
      expect(
        humanizeTechnicalError('[Errno 110] Connection timed out'),
        'انتهت مهلة الاتصال',
      );
      expect(humanizeTechnicalError('timed out'), 'انتهت مهلة الاتصال');
      expect(
        humanizeTechnicalError('[Errno 113] No route to host'),
        'لا يوجد مسار إلى الراوتر',
      );
      expect(
        humanizeTechnicalError('ConnectionResetError: [Errno 104] Connection '
            'reset by peer'),
        'قطع الطرف الآخر الاتصال',
      );
      expect(
        humanizeTechnicalError('[Errno -2] Name or service not known'),
        'اسم المضيف غير معروف',
      );
      expect(
        humanizeTechnicalError(
          'فشل: [Errno 99] Cannot assign requested address',
        ),
        'فشل: خطأ اتصال (رمز 99)',
      );
      expect(humanizeTechnicalError('رسالة عادية'), 'رسالة عادية');
    });

    test('English-only errno messages become Arabic too', () {
      expect(
        visibleErrorMessage('[Errno 111] Connection refused'),
        'رفض الراوتر الاتصال (المنفذ مغلق أو خدمة API معطّلة)',
      );
    });

    test('router diagnostics failure is humanized', () {
      expect(
        formatRouterDiagnostics({
          'ok': false,
          'error': '[Errno 113] No route to host',
        }),
        'فشل التشخيص: لا يوجد مسار إلى الراوتر',
      );
    });

    test('router operations sections never print section.error raw', () {
      final src = File(
        'lib/features/mikrotik/presentation/router_operations_screen.dart',
      ).readAsStringSync();
      expect(src.contains(': section.error,'), isFalse);
      expect(
        RegExp(r'visibleErrorMessage\(\s*section\.error')
            .allMatches(src)
            .length,
        2,
      );
    });
  });

  // ── 6) IPv4-mapped IPv6 NAS address (R07 N10) ─────────────────────────
  testWidgets('NAS list keeps «::ffff:192.0.2.171» as one LTR run',
      (tester) async {
    await _pump(
      tester,
      const NasListScreen(),
      (r) {
        if (r.path == '/api/v1/nas') {
          return FakeResponse.ok({
            'items': [
              {'id': 3, 'name': 'r07', 'address': '::ffff:192.0.2.171'},
            ],
          });
        }
        return FakeResponse.ok({'items': <dynamic>[]});
      },
      height: 1200,
    );
    expect(
      find.textContaining(ltrIsolate('::ffff:192.0.2.171')),
      findsOneWidget,
    );
    expect(rawTokenLabel('skipped'), 'تم التخطّي');
  });

  // ── 7) strict number input (no silent stripping of «-», «e», letters) ─
  group('strict number fields', () {
    Finder field(String label) => find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.labelText ?? '').startsWith(label),
        );

    test('no digits-only / [0-9.] filters left on these screens', () {
      for (final path in [
        'lib/features/business_ops/presentation/business_ops_screen.dart',
        'lib/features/wallets/presentation/wallets_screen.dart',
        'lib/features/events/presentation/events_center_screen.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(
          src.contains('FilteringTextInputFormatter'),
          isFalse,
          reason: path,
        );
        expect(src.contains('num.tryParse('), isFalse, reason: path);
        expect(src.contains('num.parse('), isFalse, reason: path);
        expect(
          RegExp(r'int\.tryParse\(\w+\.text').hasMatch(src),
          isFalse,
          reason: path,
        );
      }
    });

    testWidgets('business-ops correction: «-5» / «1e9» refused, «١٢٫٥» sent',
        (tester) async {
      final adapter = await _pump(
        tester,
        const BusinessOpsScreen(),
        (r) => r.method == 'POST'
            ? FakeResponse.ok({'entry': {}}, status: 201)
            : FakeResponse.ok({'items': <dynamic>[]}),
        width: 1000,
        height: 2400,
      );
      await tester.tap(find.text('قيد تصحيح'));
      await tester.pumpAndSettle();
      await tester.enterText(field('حساب المدين'), 'cash');
      await tester.enterText(field('حساب الدائن'), 'revenue');
      for (final bad in ['-5', '1e9', '12abc', '200000']) {
        await tester.enterText(field('المبلغ'), bad);
        await tester.tap(find.text('تسجيل القيد'));
        await tester.pumpAndSettle();
        // the text is kept as typed — never rewritten
        expect(find.text(bad), findsOneWidget);
        expect(adapter.where('POST', '/corrections'), isEmpty, reason: bad);
      }
      expect(find.textContaining('الحدّ الأعلى 100,000'), findsOneWidget);
      await tester.enterText(field('رقم الهدف'), '-3');
      await tester.enterText(field('المبلغ'), '١٢٫٥');
      await tester.tap(find.text('تسجيل القيد'));
      await tester.pumpAndSettle();
      expect(adapter.where('POST', '/corrections'), isEmpty);
      await tester.enterText(field('رقم الهدف'), '٧');
      await tester.tap(find.text('تسجيل القيد'));
      await tester.pumpAndSettle();
      final post = adapter.where('POST', '/corrections').single;
      expect(post.jsonBody['amount'], 12.5);
      expect(post.jsonBody['target_id'], 7);
    });

    testWidgets('wallet debit: «1,5» refused (was rewritten to 1.5)',
        (tester) async {
      final adapter = await _pump(
        tester,
        const WalletsScreen(),
        (r) {
          if (r.method == 'POST') {
            return FakeResponse.ok({
              'wallet': {'id': 1, 'currency': 'ILS', 'balance': '10'},
              'transaction': {'id': 1},
            });
          }
          return FakeResponse.ok({
            'items': [
              {
                'id': 1,
                'owner_type': 'company',
                'currency': 'ILS',
                'balance': '300',
                'status': 'active',
              },
            ],
            'count': 1,
          });
        },
        height: 1600,
      );
      await tester.tap(find.text('خصم').first);
      await tester.pumpAndSettle();
      await tester.enterText(field('المبلغ'), '1,5');
      await tester.tap(find.widgetWithText(FilledButton, 'خصم').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('بدون فواصل'), findsOneWidget);
      expect(adapter.where('POST', '/debit'), isEmpty);
      await tester.enterText(field('المبلغ'), '٥٫٥');
      await tester.tap(find.widgetWithText(FilledButton, 'خصم').last);
      await tester.pumpAndSettle();
      expect(adapter.where('POST', '/debit').single.jsonBody['amount'], 5.5);
    });

    testWidgets('event record: actor id «-5» refused, «٧» sent as 7',
        (tester) async {
      final adapter = await _pump(
        tester,
        const EventsCenterScreen(),
        (r) => r.method == 'POST'
            ? FakeResponse.ok(
                {
                  'event': {'id': 1},
                },
                status: 201,
              )
            : FakeResponse.ok({'items': <dynamic>[]}),
        width: 1000,
        height: 2400,
      );
      await tester.tap(find.text('تسجيل حدث').first);
      await tester.pumpAndSettle();
      await tester.enterText(field('وصف الحدث'), 'مراجعة');
      await tester.enterText(field('رقم المنفذ'), '-5');
      await tester.pumpAndSettle();
      expect(find.text('-5'), findsOneWidget); // kept as typed
      expect(find.text('القيم السالبة غير مسموحة.'), findsOneWidget);
      await tester.tap(find.text('حفظ الحدث'));
      await tester.pumpAndSettle();
      expect(adapter.where('POST', '/api/v1/events'), isEmpty);
      await tester.enterText(field('رقم المنفذ'), '٧');
      await tester.tap(find.text('حفظ الحدث'));
      await tester.pumpAndSettle();
      expect(
        adapter.where('POST', '/api/v1/events').single.jsonBody['actor_id'],
        7,
      );
    });
  });

  // ── 8) server Arabic *_label fields (FIX2 network contract) ───────────
  group('server labels win, client mapping is the fallback', () {
    test('backups: last_status_label / status_label', () {
      final withLabel = BackupStatus.fromJson({
        'job': {'last_status': 'never_run', 'last_status_label': 'لم تبدأ'},
        'recent_runs': [
          {'status': 'failed', 'status_label': 'فشلت (خادم)'},
        ],
      });
      expect(withLabel.job.statusText, 'لم تبدأ');
      expect(withLabel.recentRuns.single.statusLabel, 'فشلت (خادم)');
      final old = BackupStatus.fromJson({
        'job': {'last_status': 'never_run'},
        'recent_runs': [
          {'status': 'failed'},
        ],
      });
      expect(old.job.statusText, 'لم تُشغَّل بعد');
      expect(old.recentRuns.single.statusLabel, 'فشلت');
      final blank = BackupStatus.fromJson({
        'job': {'last_status': 'success', 'last_status_label': '  '},
      });
      expect(blank.job.statusText, 'ناجحة');
    });

    test('tickets: category_label', () {
      expect(
        SupportTicket.fromJson(
          {'category': 'network', 'category_label': 'شبكة'},
        ).categoryLabel,
        'شبكة',
      );
      expect(
        SupportTicket.fromJson({'category': 'network'}).categoryLabel,
        'الشبكة',
      );
    });

    test('ledger: debit/credit/target labels', () {
      final e = BusinessLedgerEntry.fromJson({
        'id': 1,
        'debit_account': 'cash',
        'debit_account_label': 'الصندوق (نقدًا)',
        'credit_account': 'wallet:manager:3',
        'credit_account_label': 'محفظة المدير #3',
        'target_type': 'distributor',
        'target_id': 1,
        'target_label': 'موزّع #1',
      });
      expect(e.debitAccountLabel, 'الصندوق (نقدًا)');
      expect(e.creditAccountLabel, 'محفظة المدير #3');
      expect(e.targetLabel, 'موزّع #1');
      expect(
        BusinessLedgerEntry.fromJson({'debit_account': 'cash'})
            .debitAccountLabel,
        '',
      );
    });

    testWidgets('ledger card shows the server labels', (tester) async {
      await _pump(
        tester,
        const BusinessOpsScreen(),
        (r) => r.path.contains('/finance/ledger')
            ? FakeResponse.ok({
                'items': [
                  {
                    'id': 9,
                    'entry_type': 'payment',
                    'debit_account': 'cash',
                    'debit_account_label': 'الصندوق (نقدًا)',
                    'credit_account': 'wallet:manager:3',
                    'credit_account_label': 'محفظة المدير #3',
                    'amount': '25',
                    'currency': 'ILS',
                    'target_type': 'distributor',
                    'target_id': 1,
                    'target_label': 'الموزّع أحمد',
                  },
                ],
              })
            : FakeResponse.ok({'items': <dynamic>[]}),
      );
      expect(find.text('الصندوق (نقدًا)'), findsOneWidget);
      expect(find.text('محفظة المدير #3'), findsOneWidget);
      expect(find.text('الموزّع أحمد'), findsOneWidget);
      expect(_anyTextContains('wallet:manager'), isFalse);
    });

    test('deliveries: status_label', () {
      expect(
        MessageDelivery.fromJson(
          {'status': 'skipped', 'status_label': 'تُخطّي'},
        ).statusLabel,
        'تُخطّي',
      );
      expect(
        MessageDelivery.fromJson({'status': 'skipped'}).statusLabel,
        'تم التخطّي',
      );
    });

    test('recycle bin: status_label / deleted_by_label', () {
      final item = RecycleBinItem.fromJson({
        'status': 'deleted',
        'status_label': 'محذوف (في السلّة)',
        'deleted_by': 'api-token:4',
        'deleted_by_label': 'واجهة API (رمز #4)',
      });
      expect(item.statusLabel, 'محذوف (في السلّة)');
      expect(item.deletedByText, 'واجهة API (رمز #4)');
      final old = RecycleBinItem.fromJson({
        'status': 'deleted',
        'deleted_by': 'admin',
      });
      expect(old.statusLabel, 'محذوف');
      expect(old.deletedByText, 'admin');
      expect(RecycleBinItem.fromJson({}).deletedByText, 'غير معروف');
    });
  });
}
