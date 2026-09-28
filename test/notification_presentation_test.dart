import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoberadius_app/core/ota/ota_banner_card.dart';
import 'package:hoberadius_app/core/ota/ota_updater.dart';
import 'package:hoberadius_app/core/theme/app_theme.dart';
import 'package:hoberadius_app/features/notifications/domain/notification_model.dart';
import 'package:hoberadius_app/features/notifications/domain/notification_presentation.dart';

/// Owner 2026-09-28: notifications were a run-on wall of text, all one
/// colour, and app updates could be missed. Pins the parsing of the server's
/// real bodies, the kind colours, grouping and the update bar.
AppNotification _n(
  int id, {
  String type = 'system',
  String severity = 'critical',
  required String title,
  String body = '',
  String link = '/admin/radius/device-health',
  bool read = false,
}) =>
    AppNotification.fromJson({
      'id': id,
      'type': type,
      'severity': severity,
      'title': title,
      'body': body,
      'link': link,
      'created_at': '2026-09-28T08:29:00Z',
      'is_read': read,
      'read_at': read ? '2026-09-28T09:00:00Z' : '',
    });

class _Fixed extends OtaController {
  _Fixed(OtaState s) : super(enabled: false) {
    state = s;
  }
}

void main() {
  test('device alert body → headline + facts, telegram nag dropped', () {
    final p = parseNotificationBody(
        '🔴 «MT-PPPoE» — الراوتر ما زال غير متصل\n⏳ المدّة: \u206822 ساعة و39 دقيقة\u2069\n🕒 الوقت: \u20682026-09-28 11:29\u2069\n\n🔕 لم يصل إشعار فوري على جوالك لأن «تنبيهات تلجرام» غير مُفعّلة. فعّلها من: الإعدادات ← تنبيهات تلجرام.',
        title: 'ما زال مفصولًا: MT-PPPoE',);
    expect(p.headline, '«MT-PPPoE» — الراوتر ما زال غير متصل');
    expect(p.facts,
        [('المدّة', '22 ساعة و39 دقيقة'), ('الوقت', '2026-09-28 11:29')],);
    expect(p.notes.where((l) => l.contains('تلجرام')), isEmpty);
  });

  test('periodic check body → counts as facts, routers as list items', () {
    final p = parseNotificationBody(
        '⚠️ الفحص الدوري — توجد ملاحظات\n\nالحالة:\n🔴 مفصول: \u20683\u2069\n✅ سليم: \u20680\u2069\n\n🔴 المفصولة:\n• «MT-HQ-Core» (راوتر) — منذ \u206822 ساعة\u2069\n• «MT-PPPoE» (راوتر) — منذ \u206822 ساعة\u2069',);
    expect(p.headline, 'الفحص الدوري — توجد ملاحظات');
    expect(p.facts, [('مفصول', '3'), ('سليم', '0')]);
    expect(p.bullets.length, 2);
    expect(p.bullets.first, startsWith('«MT-HQ-Core»'));
  });

  test('kinds get different colours', () {
    final down = classifyNotification(_n(1, title: 'ما زال مفصولًا: MT-PPPoE'));
    final check = classifyNotification(
      _n(2, severity: 'warning', title: 'الفحص الدوري: ملاحظات'),
    );
    final sub = classifyNotification(
      _n(3,
          type: 'subscription',
          severity: 'info',
          title: 'إضافة/تمديد وقت',
          link: '',),
    );
    expect(down, NotificationKind.deviceDown);
    expect(check, NotificationKind.healthCheck);
    expect(sub, NotificationKind.subscriber);
    final colours = {
      kindStyle(down).color,
      kindStyle(check).color,
      kindStyle(sub).color,
    };
    expect(colours.length, 3);
  });

  test('repeated alerts fold into one row with a count', () {
    final groups = groupNotifications([
      _n(5, title: 'ما زال مفصولًا: MT-PPPoE'),
      _n(4, title: 'ما زال مفصولًا: MT-HQ-Core', read: true),
      _n(3, title: 'ما زال مفصولًا: MT-PPPoE', read: true),
      _n(2, title: 'ما زال مفصولًا: MT-PPPoE', read: true),
    ]);
    expect(groups.length, 2);
    expect(groups.first.count, 3);
    expect(groups.first.ids, [5, 3, 2]);
    expect(groups.first.anyUnread, isTrue);
    expect(groups.last.anyUnread, isFalse);
  });

  Future<void> pumpBanner(WidgetTester tester, OtaPhase phase) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          otaControllerProvider
              .overrideWith((ref) => _Fixed(OtaState(phase: phase))),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: OtaBannerCard()),
        ),
      ),
    );
    await tester.pump();
    tester.takeException();
  }

  testWidgets('update bar shows while an update is available', (tester) async {
    await pumpBanner(tester, OtaPhase.available);
    expect(find.text('يوجد تحديث جديد للتطبيق'), findsOneWidget);
    expect(find.text('تثبيت'), findsOneWidget);
  });

  testWidgets('update bar hidden when up to date', (tester) async {
    await pumpBanner(tester, OtaPhase.upToDate);
    expect(find.text('يوجد تحديث جديد للتطبيق'), findsNothing);
  });
}
