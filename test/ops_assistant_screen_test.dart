import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/ops_assistant/application/ops_assistant_providers.dart';
import 'package:hoberadius_app/features/ops_assistant/data/ops_assistant_repository.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_labels.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_models.dart';
import 'package:hoberadius_app/features/ops_assistant/presentation/ops_assistant_screen.dart';
import 'package:hoberadius_app/features/provider_grants/application/nav_visibility.dart';
import 'package:hoberadius_app/features/shell/navigation_schema.dart';
import 'package:hoberadius_app/features/shell/visible_nav_sections.dart';

const _proposal = OpsReply(
  type: OpsReplyType.proposal,
  action: 'create_subscriber',
  text: 'سأنشئ المشترك ahmad على الباقة الشهريّة.',
  proposal: OpsProposal(
    proposalId: 'p1',
    proposalHash: 'h1',
    steps: [
      OpsStep(
        n: 1,
        action: 'create_subscriber',
        titleAr: 'إنشاء مشترك',
        values: {'username': 'ahmad', 'plan_id': 3},
        names: {'plan_id': 'شهري'},
        password: 'generated_and_shown_once',
      ),
    ],
  ),
);

/// In-memory server: scripted turns, records every call.
class FakeOpsGateway implements OpsAssistantGateway {
  FakeOpsGateway({
    this.statusValue = const OpsStatus(available: true, flagEnabled: true),
    this.turns = const [],
    this.suggestionList = const [],
  });

  OpsStatus statusValue;
  List<OpsTurn> turns;
  List<OpsSuggestion> suggestionList;
  Object? sendError;
  Object? confirmError;
  OpsConfirmOutcome confirmOutcome = const OpsConfirmOutcome(
    report: OpsReport(
      status: 'executed',
      steps: [OpsReportStep(n: 1, action: 'create_subscriber', status: 'done')],
    ),
    secrets: [OpsSecret(username: 'ahmad', password: 'Xy7pQ2mn4k')],
  );
  Completer<void>? hold;

  final sent = <(String?, String)>[];
  final confirms = <(String, String, String)>[];
  final cancels = <String>[];
  final started = <OpsSuggestion>[];

  int _turn = 0;
  OpsTurn _next() => turns[_turn++ % turns.length];

  @override
  Future<OpsStatus> status() async => statusValue;

  @override
  Future<List<OpsSuggestion>> suggestions() async => suggestionList;

  @override
  Future<OpsTurn> sendMessage({
    String? conversationId,
    required String text,
  }) async {
    sent.add((conversationId, text));
    if (hold != null) await hold!.future;
    if (sendError != null) throw sendError!;
    return _next();
  }

  @override
  Future<OpsTurn> startFromSuggestion(OpsSuggestion suggestion) async {
    started.add(suggestion);
    return _next();
  }

  @override
  Future<OpsConfirmOutcome> confirm({
    required String conversationId,
    required OpsProposal proposal,
    required String idempotencyKey,
  }) async {
    confirms.add((conversationId, proposal.proposalHash, idempotencyKey));
    if (confirmError != null) throw confirmError!;
    return confirmOutcome;
  }

  @override
  Future<void> cancel(String conversationId) async =>
      cancels.add(conversationId);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('OpsChatController', () {
    test('send → bubbles, choices, empty line, info, proposal', () async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(
            conversationId: 'c1',
            replies: [
              OpsReply(
                type: OpsReplyType.choices,
                text: 'هذه الباقات',
                items: [
                  {'n': 1, 'id': 3, 'name': 'شهري'},
                ],
              ),
              OpsReply(
                type: OpsReplyType.choices,
                items: [],
                emptyFlag: true,
                emptyText: 'لا توجد عروض مسجّلة في النظام بعد…',
              ),
              OpsReply(
                type: OpsReplyType.result,
                source: 'online_sessions',
                data: {'total': 2},
              ),
              _proposal,
            ],
          ),
        ],
      );
      final c = OpsChatController(gw);
      expect(await c.send('  '), isFalse);
      expect(c.state.entries.single, isA<OpsErrorEntry>());

      await c.send('أنشئ ahmad');
      expect(gw.sent.single, (null, 'أنشئ ahmad'));
      expect(c.state.conversationId, 'c1');
      final kinds = c.state.entries.map((e) => e.runtimeType).toList();
      expect(kinds, [
        OpsErrorEntry,
        OpsUserEntry,
        OpsBotEntry,
        OpsChoicesEntry,
        OpsBotEntry, // the empty-state line
        OpsInfoEntry,
        OpsBotEntry,
        OpsProposalEntry,
      ]);
      final empty = c.state.entries[4] as OpsBotEntry;
      expect(empty.empty, isTrue);
      expect(empty.text, 'لا توجد عروض مسجّلة في النظام بعد…');

      // the conversation id goes with the next message
      await c.send('تابع');
      expect(gw.sent.last.$1, 'c1');
    });

    test('confirm executes once, returns secrets, never stores them', () async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(conversationId: 'c1', replies: [_proposal]),
        ],
      );
      final c = OpsChatController(gw);
      await c.send('x');
      final p = c.state.entries.whereType<OpsProposalEntry>().single;
      final secrets = await c.confirm(p.id);
      expect(secrets.single.password, 'Xy7pQ2mn4k');
      expect(gw.confirms.single.$1, 'c1');
      expect(gw.confirms.single.$2, 'h1');
      final after = c.state.entries.whereType<OpsProposalEntry>().single;
      expect(after.state, OpsProposalState.confirmed);
      final report = c.state.entries.last as OpsReportEntry;
      expect(report.titles['create_subscriber'], 'إنشاء مشترك');
      // a second tap does nothing
      expect(await c.confirm(p.id), isEmpty);
      expect(gw.confirms.length, 1);
    });

    test('a failed confirm stays retryable with the SAME key', () async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(conversationId: 'c1', replies: [_proposal]),
        ],
      )..confirmError = const OpsError('الخادم مشغول');
      final c = OpsChatController(gw);
      await c.send('x');
      final p = c.state.entries.whereType<OpsProposalEntry>().single;
      await c.confirm(p.id);
      expect(
        c.state.entries.whereType<OpsProposalEntry>().single.state,
        OpsProposalState.pending,
      );
      expect((c.state.entries.last as OpsErrorEntry).text, 'الخادم مشغول');
      gw.confirmError = null;
      await c.confirm(p.id);
      expect(gw.confirms.length, 2);
      expect(gw.confirms[0].$3, gw.confirms[1].$3);
    });

    test('cancel records it and locks the card', () async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(conversationId: 'c1', replies: [_proposal]),
        ],
      );
      final c = OpsChatController(gw);
      await c.send('x');
      final p = c.state.entries.whereType<OpsProposalEntry>().single;
      await c.cancelProposal(p.id);
      expect(gw.cancels, ['c1']);
      expect(
        c.state.entries.whereType<OpsProposalEntry>().single.state,
        OpsProposalState.cancelled,
      );
      expect((c.state.entries.last as OpsBotEntry).text, OpsTexts.cancelled);
      expect(await c.confirm(p.id), isEmpty);
      expect(gw.confirms, isEmpty);
    });

    test('lost conversation resets; unavailable re-reads the status', () async {
      var unavailable = 0;
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(conversationId: 'c1', replies: []),
        ],
      );
      final c = OpsChatController(gw, onUnavailable: () => unavailable++);
      await c.send('x');
      expect(c.state.conversationId, 'c1');
      gw.sendError =
          const OpsError('المحادثة غير موجودة', conversationLost: true);
      await c.send('y');
      expect(c.state.conversationId, isNull);
      gw.sendError = const OpsError('غير مفعّل', unavailable: true);
      await c.send('z');
      expect(unavailable, 1);
      expect(c.state.busy, isFalse);
    });
  });

  group('menu entry', () {
    test('visible only when /ops/status says available', () async {
      for (final available in [true, false]) {
        final container = ProviderContainer(
          overrides: [
            opsStatusProvider.overrideWith(
              (ref) async => OpsStatus(available: available),
            ),
            gatedNavSectionsProvider.overrideWithValue(const []),
            eCardsInUseProvider.overrideWith((ref) async => false),
          ],
        );
        addTearDown(container.dispose);
        await container.read(opsStatusProvider.future);
        expect(container.read(opsAssistantNavVisibleProvider), available);
        final paths = [
          for (final s in container.read(visibleNavSectionsProvider))
            for (final i in s.items) i.item.path,
        ];
        expect(paths.contains('/ops-assistant'), available);
      }
    });

    test('hidden while loading or on error (fails closed)', () {
      final container = ProviderContainer(
        overrides: [
          opsStatusProvider
              .overrideWith((ref) => Completer<OpsStatus>().future),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(opsAssistantNavVisibleProvider), isFalse);
    });

    test('not part of the web-mirrored groups; titled on mobile', () {
      expect(
        appNavigationItems.map((i) => i.path),
        isNot(contains('/ops-assistant')),
      );
      expect(mobileTitleForLocation('/ops-assistant', 4), 'مساعد العمليّات');
      // any signed-in admin may open it (the executor decides each action)
      final manager = AppPermissions.fromMe({
        'admin': {'id': 5, 'is_owner': false},
        'grants': <String, dynamic>{},
      });
      final kept = filterNavSectionsByPermissions(
        const [
          GatedNavSection(
            section: opsAssistantNavSection,
            items: [
              GatedNavItem(item: opsAssistantNavItem, requiresUpgrade: false),
            ],
          ),
        ],
        manager,
      );
      expect(kept.single.items.single.item.routeName, 'ops-assistant');
    });
  });

  group('screen', () {
    Future<FakeOpsGateway> pump(
      WidgetTester tester,
      FakeOpsGateway gw, {
      Map<String, dynamic>? me,
    }) async {
      tester.view.physicalSize = const Size(420, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            opsAssistantGatewayProvider.overrideWithValue(gw),
            opsStatusProvider.overrideWith((ref) async => gw.statusValue),
            if (me != null)
              permissionsProvider.overrideWith(
                (ref) => PermissionsController(ref)..apply(me),
              ),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: OpsAssistantScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();
      return gw;
    }

    testWidgets('flag off: why + owner hint, experimental badge',
        (tester) async {
      await pump(
        tester,
        FakeOpsGateway(
          statusValue: const OpsStatus(available: false, reason: 'disabled'),
        ),
      );
      expect(find.byKey(const ValueKey('ops-experimental')), findsOneWidget);
      expect(find.text(OpsTexts.experimental), findsOneWidget);
      expect(find.text(OpsTexts.disabled), findsOneWidget);
      expect(find.text(OpsTexts.disabledOwnerHint), findsOneWidget);
      expect(find.byKey(const ValueKey('ops-input')), findsNothing);
    });

    testWidgets('flag off for a manager: ask the owner', (tester) async {
      await pump(
        tester,
        FakeOpsGateway(
          statusValue: const OpsStatus(available: false, reason: 'disabled'),
        ),
        me: {
          'admin': {'id': 5, 'is_owner': false},
          'grants': <String, dynamic>{},
        },
      );
      expect(find.text(OpsTexts.disabledAskOwner), findsOneWidget);
    });

    testWidgets('password gate: counts only', (tester) async {
      await pump(
        tester,
        FakeOpsGateway(
          statusValue: const OpsStatus(
            available: false,
            flagEnabled: true,
            reason: 'weak_admin_passwords',
            passwordGate: OpsPasswordGate(
              defaultPasswordCount: 2,
              mustChangeCount: 1,
            ),
          ),
        ),
      );
      expect(find.text(OpsTexts.weakPasswords), findsOneWidget);
      expect(
        find.text('• ${OpsTexts.defaultPasswordAdmins} 2'),
        findsOneWidget,
      );
      expect(find.text('• ${OpsTexts.mustChangeAdmins} 1'), findsOneWidget);
    });

    testWidgets('older server: not updated', (tester) async {
      await pump(
        tester,
        FakeOpsGateway(statusValue: const OpsStatus.notSupported()),
      );
      expect(find.text(OpsTexts.notSupported), findsOneWidget);
    });

    testWidgets(
        'chat: message → confirmation card → confirm → report + one-time '
        'password dialog (copy + warning), gone after close', (tester) async {
      final gw = await pump(
        tester,
        FakeOpsGateway(
          turns: [
            const OpsTurn(conversationId: 'c1', replies: [_proposal]),
          ],
        ),
      );
      expect(find.text(OpsTexts.greetingLead), findsOneWidget);
      expect(find.text(OpsTexts.exampleRenew), findsOneWidget);

      // markup is shown as plain text, never interpreted
      await tester.enterText(
        find.byKey(const ValueKey('ops-input')),
        'أنشئ ahmad <b>شهري</b>',
      );
      await tester.tap(find.byKey(const ValueKey('ops-send')));
      await tester.pumpAndSettle();
      expect(gw.sent.single.$2, 'أنشئ ahmad <b>شهري</b>');
      expect(find.text('أنشئ ahmad <b>شهري</b>'), findsOneWidget);
      expect(find.text(_proposal.text), findsOneWidget);
      expect(find.text(OpsTexts.proposalTitle), findsOneWidget);
      expect(find.text('شهري (#3)'), findsOneWidget);
      expect(find.text(OpsTexts.passwordNote), findsOneWidget);

      final entry = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('ops-confirm-'),
      );
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(gw.confirms.single.$2, 'h1');
      expect(find.text(OpsTexts.secretTitle), findsOneWidget);
      expect(find.text(OpsTexts.secretWarning), findsOneWidget);
      expect(find.text('Xy7pQ2mn4k'), findsOneWidget);

      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      await tester.tap(find.byKey(const ValueKey('ops-copy-0')));
      await tester.pumpAndSettle();
      expect(copied, 'Xy7pQ2mn4k');
      expect(find.text(OpsTexts.copied), findsOneWidget);

      await tester.tap(find.text(OpsTexts.secretClose));
      await tester.pumpAndSettle();
      expect(find.text('Xy7pQ2mn4k'), findsNothing);
      expect(
        find.text('${OpsTexts.resultTitle} — ${OpsTexts.rsExecuted}'),
        findsOneWidget,
      );
      expect(find.text('${OpsTexts.step} 1 · إنشاء مشترك'), findsOneWidget);
    });

    testWidgets('plan card + per-step report (done / failed / not run)',
        (tester) async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(
            conversationId: 'c1',
            replies: [
              OpsReply(
                type: OpsReplyType.proposal,
                text: 'خطّة',
                proposal: OpsProposal(
                  proposalId: 'p2',
                  proposalHash: 'h2',
                  level: 3,
                  steps: [
                    OpsStep(
                      n: 1,
                      action: 'create_subscriber',
                      titleAr: 'إنشاء مشترك',
                    ),
                    OpsStep(
                      n: 2,
                      action: 'temporary_speed',
                      titleAr: 'سرعة مؤقتة',
                      danger: 'L3',
                    ),
                    OpsStep(
                      n: 3,
                      action: 'create_card_batch',
                      titleAr: 'توليد كروت',
                      executable: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      )..confirmOutcome = const OpsConfirmOutcome(
          report: OpsReport(
            status: 'partial',
            steps: [
              OpsReportStep(n: 1, action: 'create_subscriber', status: 'done'),
              OpsReportStep(
                n: 2,
                action: 'temporary_speed',
                status: 'failed',
                errorMessage: 'المشترك غير متّصل الآن',
              ),
              OpsReportStep(
                  n: 3, action: 'create_card_batch', status: 'not_run',),
            ],
          ),
        );
      await pump(tester, gw);
      await tester.enterText(find.byKey(const ValueKey('ops-input')), 'خطّة');
      await tester.tap(find.byKey(const ValueKey('ops-send')));
      await tester.pumpAndSettle();
      expect(find.text(OpsTexts.planTitle), findsOneWidget);
      expect(find.text('${OpsTexts.step} 2: سرعة مؤقتة'), findsOneWidget);
      expect(find.text(OpsTexts.danger), findsOneWidget);
      expect(find.text(OpsTexts.notExec), findsOneWidget);

      final confirm = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('ops-confirm-'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(find.text(OpsTexts.secretTitle), findsNothing);
      expect(
        find.text('${OpsTexts.resultTitle} — ${OpsTexts.rsPartial}'),
        findsOneWidget,
      );
      expect(find.text(OpsTexts.stDone), findsWidgets);
      expect(find.text(OpsTexts.stFailed), findsOneWidget);
      expect(find.text(OpsTexts.stNotRun), findsOneWidget);
      expect(find.text('المشترك غير متّصل الآن'), findsOneWidget);
    });

    testWidgets('info RESULT card + empty-state line', (tester) async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(
            conversationId: 'c1',
            replies: [
              OpsReply(
                type: OpsReplyType.result,
                source: 'card_batch_status',
                data: {
                  'batch_id': 4,
                  'name': 'حزمة الساعة',
                  'status': 'active',
                  'total_cards': 100,
                  'available_count': 40,
                },
              ),
              OpsReply(
                type: OpsReplyType.result,
                source: 'subscriber_info',
                error: 'out_of_scope',
              ),
              OpsReply(
                type: OpsReplyType.choices,
                items: [],
                emptyText: 'لا توجد عروض مسجّلة في النظام بعد…',
                emptyFlag: true,
              ),
            ],
          ),
        ],
      );
      await pump(tester, gw);
      await tester.enterText(
        find.byKey(const ValueKey('ops-input')),
        'وضع الحزمة',
      );
      await tester.tap(find.byKey(const ValueKey('ops-send')));
      await tester.pumpAndSettle();
      expect(find.text('وضع حزمة البطاقات'), findsOneWidget);
      expect(find.text(OpsTexts.resultReady), findsWidgets);
      // the rows open behind «عرض التفاصيل»
      expect(find.text('حزمة الساعة'), findsNothing);
      final toggle = find.byKey(const ValueKey('ops-details-toggle'));
      await tester.ensureVisible(toggle.first);
      await tester.tap(toggle.first);
      await tester.pumpAndSettle();
      expect(find.text('حزمة الساعة'), findsOneWidget);
      expect(find.text('فعّال'), findsOneWidget);
      expect(find.text('متاحة (غير مستعملة)'), findsOneWidget);
      expect(find.text('هذا السجلّ ليس ضمن نطاقك.'), findsOneWidget);
      expect(find.text('لا توجد عروض مسجّلة في النظام بعد…'), findsOneWidget);
    });

    testWidgets('suggestions → start a conversation', (tester) async {
      final gw = FakeOpsGateway(
        suggestionList: const [
          OpsSuggestion(
            eventType: 'low_card_stock',
            index: 0,
            title: 'مخزون كروت منخفض',
            text: 'الباقة «ساعة»: 5 كرت غير مستخدم (الحدّ 20).',
          ),
        ],
        turns: [
          const OpsTurn(
            conversationId: 'c7',
            replies: [
              OpsReply(type: OpsReplyType.assistant, text: 'أولّد 100 كرت؟'),
            ],
          ),
        ],
      );
      await pump(tester, gw);
      await tester.tap(find.byKey(const ValueKey('ops-tasks-open')));
      await tester.pumpAndSettle();
      expect(find.text('مخزون كروت منخفض'), findsOneWidget);
      final start = find.byKey(const ValueKey('ops-start-low_card_stock-0'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(gw.started.single.eventType, 'low_card_stock');
      expect(find.textContaining(OpsTexts.eventStarted), findsOneWidget);
      expect(find.text('أولّد 100 كرت؟'), findsOneWidget);
    });

    testWidgets('busy: thinking bubble, input and send disabled',
        (tester) async {
      final gw = FakeOpsGateway(
        turns: [
          const OpsTurn(
            conversationId: 'c1',
            replies: [
              OpsReply(type: OpsReplyType.assistant, text: 'تمّ'),
            ],
          ),
        ],
      )..hold = Completer<void>();
      await pump(tester, gw);
      await tester.enterText(find.byKey(const ValueKey('ops-input')), 'مرحبا');
      await tester.tap(find.byKey(const ValueKey('ops-send')));
      await tester.pump();
      expect(find.byKey(const ValueKey('ops-typing')), findsOneWidget);
      final send = tester
          .widget<ButtonStyleButton>(find.byKey(const ValueKey('ops-send')));
      expect(send.onPressed, isNull);
      gw.hold!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ops-typing')), findsNothing);
      expect(find.text('تمّ'), findsOneWidget);
    });

    testWidgets('server error is shown in the chat', (tester) async {
      final gw = FakeOpsGateway(turns: const [])
        ..sendError = const OpsError(OpsTexts.notSupported, notUpdated: true);
      await pump(tester, gw);
      await tester.enterText(find.byKey(const ValueKey('ops-input')), 'مرحبا');
      await tester.tap(find.byKey(const ValueKey('ops-send')));
      await tester.pumpAndSettle();
      expect(find.text(OpsTexts.notSupported), findsOneWidget);
    });
  });
}
