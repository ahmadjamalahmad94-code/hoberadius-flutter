import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoberadius_app/features/ops_assistant/application/ops_assistant_providers.dart';
import 'package:hoberadius_app/features/ops_assistant/data/ops_assistant_repository.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_labels.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_models.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_task_catalog.dart';
import 'package:hoberadius_app/features/ops_assistant/presentation/ops_assistant_screen.dart';

import 'ops_assistant_screen_test.dart' show FakeOpsGateway;

/// The screen as the shell hosts it: inside a page scroller, RTL, on a
/// small phone surface.
Future<void> _pump(WidgetTester tester, FakeOpsGateway gw) async {
  tester.view.physicalSize = const Size(380, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        opsAssistantGatewayProvider.overrideWithValue(gw),
        opsStatusProvider.overrideWith((ref) async => gw.statusValue),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(child: OpsAssistantScreen()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The «+» sheet's own scrollable (the transcript is another one).
final _sheetList = find.descendant(
  of: find.byKey(const ValueKey('ops-tasks-list')),
  matching: find.byType(Scrollable),
);

FakeOpsGateway _gateway({String text = 'تمام'}) => FakeOpsGateway(
      turns: [
        OpsTurn(
          conversationId: 'c1',
          replies: [OpsReply(type: OpsReplyType.assistant, text: text)],
        ),
      ],
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('suggested-task catalogue', () {
    test('every task maps to an action of the deployed ops-v3 catalog', () {
      // app/radius/services/ops_assistant/catalog_ops_v2.json → `actions`
      // (catalog_version "ops-v3"). A task outside this set would be a
      // request the executor cannot serve.
      const known = {
        'create_subscriber',
        'renew_or_extend_subscriber',
        'change_subscriber_plan',
        'temporary_speed',
        'suspend_subscriber',
        'enable_subscriber',
        'create_plan',
        'create_offer',
        'create_card_batch',
        'list_plans',
        'list_offers',
        'find_subscriber',
        'list_card_batches',
        'card_batch_status',
        'subscriber_info',
        'online_sessions',
        'recent_subscribers',
        'recent_card_batches',
        'recent_activity',
        'card_info',
      };
      expect(kOpsAllTasks, isNotEmpty);
      for (final t in kOpsAllTasks) {
        expect(known, contains(t.action), reason: '${t.id} → ${t.action}');
        expect(t.label.trim(), isNotEmpty);
        expect(t.prompt.trim(), isNotEmpty);
      }
      // ids are unique (they are widget keys)
      final ids = kOpsAllTasks.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(kOpsQuickTasks.length, 3);
    });
  });

  group('the «+» sheet', () {
    testWidgets('opens the full list and closes when a task is picked',
        (tester) async {
      final gw = _gateway();
      await _pump(tester, gw);
      expect(find.byKey(const ValueKey('ops-task-create_subscriber')),
          findsNothing,);

      await tester.tap(find.byKey(const ValueKey('ops-tasks-open')));
      await tester.pumpAndSettle();
      // grouped, system suggestions first
      expect(find.text(OpsTexts.tasksTitle), findsOneWidget);
      expect(find.text(OpsTexts.eventsTitle), findsOneWidget);
      expect(find.text(kOpsTaskGroups.first.title), findsOneWidget);
      // every group title is reachable by scrolling the sheet
      for (final g in kOpsTaskGroups) {
        await tester.scrollUntilVisible(
          find.text(g.title),
          120,
          scrollable: _sheetList,
        );
      }
      final row = find.byKey(const ValueKey('ops-task-online_now'));
      await tester.scrollUntilVisible(row, 120, scrollable: _sheetList);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // the list disappeared and the sentence was sent as a normal message
      expect(find.text(OpsTexts.tasksTitle), findsNothing);
      final task = kOpsAllTasks.firstWhere((t) => t.id == 'online_now');
      expect(gw.sent.single.$2, task.prompt);
      expect(find.text(task.prompt), findsOneWidget);
    });

    testWidgets('dismissing the sheet sends nothing', (tester) async {
      final gw = _gateway();
      await _pump(tester, gw);
      await tester.tap(find.byKey(const ValueKey('ops-tasks-open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ops-tasks-close')));
      await tester.pumpAndSettle();
      expect(find.text(OpsTexts.tasksTitle), findsNothing);
      expect(gw.sent, isEmpty);
    });
  });

  group('the quick-task chip row', () {
    testWidgets('hides after a task is chosen, returns with a new chat',
        (tester) async {
      final gw = _gateway();
      await _pump(tester, gw);
      expect(find.byKey(const ValueKey('ops-quick-tasks')), findsOneWidget);
      expect(find.byKey(const ValueKey('ops-chip-more')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ops-chip-card_stock')));
      await tester.pumpAndSettle();

      final stock = kOpsAllTasks.firstWhere((t) => t.id == 'card_stock');
      expect(gw.sent.single.$2, stock.prompt);
      expect(find.byKey(const ValueKey('ops-quick-tasks')), findsNothing);

      // «محادثة جديدة» (from the history sheet) brings the chips back
      await tester.tap(find.byKey(const ValueKey('ops-history')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ops-new')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ops-quick-tasks')), findsOneWidget);
    });

    testWidgets('a chip chosen from the «+» sheet also retires the row',
        (tester) async {
      await _pump(tester, _gateway());
      await tester.tap(find.byKey(const ValueKey('ops-tasks-open')));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('ops-task-list_plans'));
      await tester.scrollUntilVisible(row, 120, scrollable: _sheetList);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ops-quick-tasks')), findsNothing);
      // the «+» itself stays available
      expect(find.byKey(const ValueKey('ops-tasks-open')), findsOneWidget);
    });
  });

  group('the result card', () {
    testWidgets('«عرض التفاصيل» opens and closes the key/value rows',
        (tester) async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(
            conversationId: 'c1',
            replies: [
              OpsReply(
                type: OpsReplyType.result,
                source: 'subscriber_info',
                data: {'username': 'ahmad', 'online': true},
              ),
            ],
          ),
        ],
      );
      await _pump(tester, gw);
      await tester.enterText(
        find.byKey(const ValueKey('ops-input')),
        'معلومات ahmad',
      );
      await tester.tap(find.byKey(const ValueKey('ops-send')));
      await tester.pumpAndSettle();

      // the green check + the summary are visible, the rows are not
      expect(find.text(OpsTexts.resultReady), findsOneWidget);
      expect(find.text('معلومات المشترك'), findsOneWidget);
      expect(find.text(OpsTexts.showDetails), findsOneWidget);
      expect(find.text('ahmad'), findsNothing);

      final toggle = find.byKey(const ValueKey('ops-details-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('ahmad'), findsOneWidget);
      expect(find.text('اسم المستخدم'), findsOneWidget);
      expect(find.text(OpsTexts.hideDetails), findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.text('ahmad'), findsNothing);
      expect(find.text(OpsTexts.showDetails), findsOneWidget);
    });
  });

  group('the typing indicator', () {
    testWidgets('shows «المساعد الذكي…» with animated dots while waiting',
        (tester) async {
      final gw = _gateway()..hold = Completer<void>();
      await _pump(tester, gw);
      await tester.enterText(find.byKey(const ValueKey('ops-input')), 'مرحبا');
      await tester.tap(find.byKey(const ValueKey('ops-send')));
      await tester.pump();

      expect(find.byKey(const ValueKey('ops-typing')), findsOneWidget);
      expect(find.text(OpsTexts.typingLabel), findsOneWidget);

      // the dots keep animating: the opacities change between frames
      List<double> opacities() => tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('ops-typing')),
              matching: find.byType(Opacity),
            ),
          )
          .map((o) => o.opacity)
          .toList();
      final first = opacities();
      expect(first.length, 3);
      await tester.pump(const Duration(milliseconds: 300));
      expect(opacities(), isNot(equals(first)));

      gw.hold!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ops-typing')), findsNothing);
      expect(find.text('تمام'), findsOneWidget);
    });
  });

  group('header and composer', () {
    testWidgets('mockup header, disabled mic, no overflow on a small phone',
        (tester) async {
      await _pump(tester, _gateway());
      expect(find.text(OpsTexts.smartTitle), findsOneWidget);
      expect(find.text(OpsTexts.smartSubtitle), findsOneWidget);
      expect(find.byKey(const ValueKey('ops-bell')), findsOneWidget);
      expect(find.byKey(const ValueKey('ops-history')), findsOneWidget);

      // no speech package in pubspec → the mic is rendered disabled
      final mic =
          tester.widget<IconButton>(find.byKey(const ValueKey('ops-mic')));
      expect(mic.onPressed, isNull);

      expect(tester.takeException(), isNull);
    });

    testWidgets('an example chip fills the composer without sending',
        (tester) async {
      final gw = _gateway();
      await _pump(tester, gw);
      await tester.tap(find.byKey(const ValueKey('ops-example-0')));
      await tester.pumpAndSettle();
      final field =
          tester.widget<TextField>(find.byKey(const ValueKey('ops-input')));
      expect(field.controller?.text, OpsTexts.exampleRenew);
      expect(gw.sent, isEmpty);
    });

    testWidgets('history says the server keeps no past conversations',
        (tester) async {
      await _pump(tester, _gateway());
      await tester.tap(find.byKey(const ValueKey('ops-history')));
      await tester.pumpAndSettle();
      expect(find.text(OpsTexts.historyTitle), findsOneWidget);
      expect(find.text(OpsTexts.historyOnlyCurrent), findsOneWidget);
      expect(find.text(OpsTexts.historyEmpty), findsOneWidget);
    });
  });
}
