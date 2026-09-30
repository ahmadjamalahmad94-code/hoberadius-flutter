import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/features/cards/data/cards_repository.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_form_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/card_batch_import_screen.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_import.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/features/plans/data/plans_repository.dart';
import 'package:hoberadius_app/shared/widgets/form_field_row.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/features/accounting/presentation/financial_reports_screen.dart';
import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/features/admin_control/application/admin_control_providers.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_requests.dart';
import 'package:hoberadius_app/features/cards/presentation/recharge_cards_screen.dart';
import 'package:hoberadius_app/features/cards/presentation/widgets/card_number_field.dart';
import 'package:hoberadius_app/features/cards/print/application/quick_print_controller.dart';
import 'package:hoberadius_app/features/cards/print/data/quick_print_repository.dart';
import 'package:hoberadius_app/features/cards/print/domain/auto_sizes.dart';
import 'package:hoberadius_app/features/cards/print/presentation/print_job_flow.dart';
import 'package:hoberadius_app/features/cards/print/presentation/quick_print_screen.dart';

import 'support/fake_api.dart';

const _clash = 'يوجد قالب طباعة بهذا الاسم — اختر اسمًا آخر.';

List<Map<String, dynamic>> _templates() => [
      {
        'id': 3,
        'name': 'قالب سريع',
        'layout_json': {'is_default': true},
      },
      {'id': 4, 'name': 'قالب سريع 2', 'layout_json': <String, dynamic>{}},
    ];

/// The preview rasterizer is a platform plugin: park it (never answers).
void _parkPrinting() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('net.nfet.printing'),
    (_) => Completer<Object?>().future,
  );
}

/// The print endpoints of a server; [onSave] answers `quick-save`.
RecordingAdapter _server({
  Map<String, dynamic> batch = const {'id': 7, 'price_per_card': 5},
  Map<String, dynamic> lastSettings = const {},
  FakeResponse Function(RecordedRequest r)? onSave,
}) =>
    RecordingAdapter((r) {
      if (r.path.contains('/cards/batches/')) {
        return FakeResponse.ok({'batch': batch});
      }
      if (r.path.endsWith('/quick-save')) {
        return onSave?.call(r) ??
            FakeResponse.ok({
              'template': {'id': 11, 'name': r.jsonBody['form']?['name']},
            });
      }
      if (r.path.endsWith('/last-settings')) {
        return FakeResponse.ok({
          'settings': <String, dynamic>{},
          ...lastSettings,
        });
      }
      if (r.path.endsWith('/print-templates')) {
        return FakeResponse.ok({'items': _templates()});
      }
      return FakeResponse.ok(<String, dynamic>{});
    });

Future<QuickPrintController> _controller(
  RecordingAdapter adapter, {
  String Function()? currency,
}) async {
  _parkPrinting();
  final ctl = QuickPrintController(
    QuickPrintRepository(fakeApiClient(adapter)),
    7,
    tenantCurrency: currency,
  );
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return ctl;
}

Map<String, dynamic> _elementsJson({
  bool adjusted = true,
  bool newServer = true,
}) =>
    {
      'card': {'width_mm': 54, 'height_mm': 85.6},
      'elements': {
        'username': {
          'x': 29.96,
          'y': 20,
          'w': 25.5,
          'h': 8,
          if (newServer) 'requested': {'x': 16.1, 'y': 20},
          if (newServer) 'adjusted': adjusted,
        },
        'qr': {
          'x': 10,
          'y': 40,
          'w': 20,
          'h': newServer ? 20 : 22,
          if (newServer) 'size_pct': 37.04,
          if (newServer) 'requested': {'x': 30, 'y': 30},
          if (newServer) 'adjusted': adjusted,
        },
      },
      if (newServer) 'qr_conflict': false,
      if (newServer)
        'warnings': [
          'نُقل رمز QR (أو صُغّر) كي لا يغطّي اسم المستخدم أو كلمة المرور.',
        ],
    };

void main() {
  group('1 — «تصميم جديد» name', () {
    test('a new design gets a name no template has', () {
      expect(uniqueTemplateName(const []), 'قالب سريع');
      expect(uniqueTemplateName(_templates()), 'قالب سريع 3');
      expect(
        uniqueTemplateName([
          {'name': 'قالب سريع'},
        ]),
        'قالب سريع 2',
      );
      // a clash on «X 2» suggests «X 3», not «X 2 2»
      expect(
        uniqueTemplateName(_templates(), base: 'قالب سريع 2'),
        'قالب سريع 3',
      );
    });

    test('409 duplicate_name and the old 422 text are both a name clash', () {
      expect(
        isTemplateNameClash(
          ApiException(code: 'duplicate_name', message: _clash, status: 409),
        ),
        isTrue,
      );
      expect(
        isTemplateNameClash(
          ApiException(code: 'validation_error', message: _clash, status: 422),
        ),
        isTrue,
      );
      expect(
        isTemplateNameClash(
          ApiException(code: 'validation_error', message: 'x', status: 422),
        ),
        isFalse,
      );
    });

    test('«تصميم جديد» shows the unique name; an empty name is not sent',
        () async {
      final adapter = _server();
      final ctl = await _controller(adapter);
      addTearDown(ctl.dispose);
      await ctl.selectTemplate(0);
      expect(ctl.state.templateId, 0);
      expect(ctl.state.form.name, 'قالب سريع 3');
      ctl.updateForm((f) => f.copyWith(name: ''));
      expect(ctl.state.form.name, '', reason: 'no snap back to «قالب سريع»');
      await expectLater(ctl.save(), throwsA(isA<TemplateNameRequired>()));
      expect(adapter.where('POST', '/quick-save'), isEmpty);
    });

    for (final status in [409, 422]) {
      test('a $status name clash → TemplateNameTaken, then overwrite / rename',
          () async {
        var saves = 0;
        final adapter = _server(
          onSave: (r) {
            saves++;
            if (saves == 1) {
              return FakeResponse.error(
                status,
                status == 409 ? 'duplicate_name' : 'validation_error',
                _clash,
              );
            }
            return FakeResponse.ok({
              'template': {
                'id': r.jsonBody['template_id'] ?? 12,
                'name': r.jsonBody['form']['name'],
              },
            });
          },
        );
        final ctl = await _controller(adapter);
        addTearDown(ctl.dispose);
        await ctl.selectTemplate(0);
        ctl.updateForm((f) => f.copyWith(name: 'قالب سريع'));
        TemplateNameTaken? taken;
        try {
          await ctl.save();
        } on TemplateNameTaken catch (e) {
          taken = e;
        }
        expect(taken, isNotNull);
        expect(taken!.existingId, 3);
        expect(taken.suggestion, 'قالب سريع 3');
        expect(taken.message, contains('يوجد قالب طباعة بهذا الاسم'));

        // «استبدال الموجود»: saved INTO template 3
        final id = await ctl.save(targetTemplateId: taken.existingId);
        expect(id, 3);
        expect(ctl.state.templateId, 3);
        expect(
          adapter.where('POST', '/quick-save').last.jsonBody['template_id'],
          3,
        );
      });
    }

    testWidgets('the name clash dialog: rename saves under the new name',
        (tester) async {
      var saves = 0;
      final adapter = _server(
        onSave: (r) {
          saves++;
          if (saves == 1) {
            return FakeResponse.error(409, 'duplicate_name', _clash);
          }
          return FakeResponse.ok({
            'template': {'id': 12, 'name': r.jsonBody['form']['name']},
          });
        },
      );
      late QuickPrintController ctl;
      await tester.runAsync(() async {
        ctl = await _controller(adapter);
        await ctl.selectTemplate(0);
        ctl.updateForm((f) => f.copyWith(name: 'قالب سريع'));
      });
      addTearDown(ctl.dispose);
      int? result = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await saveDesignOrAsk(context, ctl),
                child: const Text('save'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('save'));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('يوجد قالب بهذا الاسم'), findsOneWidget);
      expect(find.text('استبدال الموجود'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'قالب سريع 3'), findsOneWidget);
      await tester.tap(find.text('حفظ باسم جديد'));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(result, 12);
      expect(
        adapter.where('POST', '/quick-save').last.jsonBody['form']['name'],
        'قالب سريع 3',
      );
      expect(ctl.state.form.name, 'قالب سريع 3');
    });

    testWidgets(
        'the name field shows the new name and stays empty when cleared',
        (tester) async {
      final adapter = _server();
      _parkPrinting();
      final container = ProviderContainer(
        overrides: [
          quickPrintRepositoryProvider
              .overrideWithValue(QuickPrintRepository(fakeApiClient(adapter))),
          tenantCurrencyProvider.overrideWith((ref) => 'ILS'),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: QuickPrintScreen(batchId: 7)),
            ),
          ),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await settle();
      final chip = find.text('تصميم جديد');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await settle();
      final nameField = find.widgetWithText(TextField, 'اسم القالب');
      expect(
        tester.widget<TextField>(nameField).controller!.text,
        'قالب سريع 3',
      );
      await tester.enterText(nameField, '');
      await settle();
      expect(tester.widget<TextField>(nameField).controller!.text, '');
      expect(find.text('اسم القالب مطلوب'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('2 — handles follow where the server draws', () {
    test('new contract: requested / adjusted / warnings / square QR', () {
      final els = CardElements.fromJson(_elementsJson());
      final u = els.boxes['username']!;
      expect((u.x, u.requestedX, u.adjusted), (29.96, 16.1, true));
      expect(els.boxes['qr']!.w, els.boxes['qr']!.h);
      expect(els.boxes['qr']!.sizePct, 37.04);
      expect(els.warnings.single, contains('QR'));
      // old server: none of the new fields
      final old = CardElements.fromJson(_elementsJson(newServer: false));
      expect(old.boxes['username']!.adjusted, isFalse);
      expect(old.boxes['username']!.requestedX, isNull);
      expect(old.warnings, isEmpty);
    });

    test('preview.pdf X-Print-Elements header is read (ASCII-escaped JSON)',
        () async {
      final header = jsonEncode(_elementsJson()).replaceAllMapped(
        RegExp(r'[^\x00-\x7F]'),
        (m) => '\\u${m[0]!.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}',
      );
      final adapter = RecordingAdapter(
        (_) => FakeResponse(
          200,
          'PDF',
          headers: {
            'x-print-elements': [header],
          },
        ),
      );
      final res = await QuickPrintRepository(fakeApiClient(adapter))
          .preview(form: const {});
      expect(res.elements!.boxes['username']!.x, 29.96);
      expect(res.elements!.warnings.single, startsWith('نُقل رمز QR'));
      // old server: no header
      final old = await QuickPrintRepository(
        fakeApiClient(RecordingAdapter((_) => const FakeResponse(200, 'PDF'))),
      ).preview(form: const {});
      expect(old.elements, isNull);
      expect(CardElements.tryParseHeader('not json'), isNull);
    });

    test('quick-save «elements» is parsed next to «template»', () async {
      final adapter = RecordingAdapter(
        (_) => FakeResponse.ok({
          'template': {'id': 5},
          'elements': _elementsJson(),
        }),
      );
      final res = await QuickPrintRepository(fakeApiClient(adapter))
          .quickSave(form: const {'name': 'x'});
      expect(res.template['id'], 5);
      expect(res.elements!.boxes['username']!.adjusted, isTrue);
      final old = await QuickPrintRepository(
        fakeApiClient(
          RecordingAdapter(
            (_) => FakeResponse.ok({
              'template': {'id': 5},
            }),
          ),
        ),
      ).quickSave(form: const {'name': 'x'});
      expect(old.elements, isNull);
    });

    test('an adjusted element moves the slider to the drawn place', () async {
      final ctl = await _controller(_server());
      addTearDown(ctl.dispose);
      ctl.updateForm((f) => f.copyWith(showQr: true, qrSizePct: 30));
      ctl.moveElement('username', 16.1, 20);
      ctl.moveElement('qr', 30, 30);
      final rendered = ctl.state.form;
      ctl.applyElements(CardElements.fromJson(_elementsJson()), rendered);
      final f = ctl.state.form;
      expect((f.usernameX, f.usernameY), (30.0, 20.0));
      expect((f.qrX, f.qrY), (10.0, 40.0));
      expect(f.qrSizePct, 37.0);
      expect(ctl.state.elementWarnings.single, contains('QR'));
    });

    test('old server / stale answer: the sliders stay as they are', () async {
      final ctl = await _controller(_server());
      addTearDown(ctl.dispose);
      ctl.moveElement('username', 16.1, 20);
      final rendered = ctl.state.form;
      ctl.applyElements(
        CardElements.fromJson(_elementsJson(newServer: false)),
        rendered,
      );
      expect(ctl.state.form.usernameX, 16.1);
      expect(ctl.state.elementWarnings, isEmpty);
      expect(ctl.state.elements!.boxes['username']!.x, 29.96);
      // the operator moved again before the answer came: keep the new move
      ctl.moveElement('username', 18, 20);
      ctl.applyElements(CardElements.fromJson(_elementsJson()), rendered);
      expect(ctl.state.form.usernameX, 18);
    });
  });

  group('3 — «إظهار السعر» fills price + currency', () {
    test('batch currency first, else the panel currency', () {
      expect(
        batchPriceLabel(
          {'price_per_card': 5, 'currency': 'USD'},
          fallbackCurrency: 'ILS',
        ),
        '5 USD',
      );
      expect(
        batchPriceLabel({'price_per_card': 5}, fallbackCurrency: 'ILS'),
        '5 ILS',
      );
      expect(batchPriceLabel({'price_per_card': 2.5}), '2.50');
    });

    test('old server batch without currency → «5 ILS» on the card', () async {
      final ctl = await _controller(_server(), currency: () => 'ILS');
      addTearDown(ctl.dispose);
      ctl.setShowPrice(true);
      expect(ctl.state.form.priceText, '5 ILS');
    });

    test('updated server batch currency wins', () async {
      final ctl = await _controller(
        _server(batch: const {'id': 7, 'price_per_card': 5, 'currency': 'JOD'}),
        currency: () => 'ILS',
      );
      addTearDown(ctl.dispose);
      ctl.setShowPrice(true);
      expect(ctl.state.form.priceText, '5 JOD');
    });
  });

  group('4 — PDF screen bottom bar', () {
    for (final width in [360.0, 390.0]) {
      testWidgets('«مشاركة» is not clipped at ${width.toInt()} px',
          (tester) async {
        _parkPrinting();
        tester.view.physicalSize = Size(width, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: PrintPdfScreen(
                bytes: Uint8List(0),
                fileName: 'cards.pdf',
                title: 'كروت',
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        for (final label in ['تحميل', 'مشاركة', 'طباعة']) {
          final text = find.text(label);
          expect(text, findsOneWidget);
          final button = find.ancestor(
            of: text,
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          );
          final t = tester.getRect(text);
          final b = tester.getRect(button.first);
          expect(
            t.left >= b.left - 0.5 && t.right <= b.right + 0.5,
            isTrue,
            reason: '$label $t inside $b',
          );
          final para = tester.renderObject<RenderParagraph>(text);
          expect(
            para.size.width + 0.5 >= para.getMaxIntrinsicWidth(double.infinity),
            isTrue,
            reason: '$label is laid out whole (not faded/clipped)',
          );
        }
      });
    }
  });

  group('5 — card-sales CSV export', () {
    String decode(Uint8List b) => utf8.decode(b);

    test('a BOM-only / empty server CSV gets the Arabic header row', () {
      for (final raw in [
        Uint8List.fromList([0xEF, 0xBB, 0xBF]),
        Uint8List(0),
      ]) {
        final out = financialReportCsvForSave(raw, 'card-sales')!;
        expect(out.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
        expect(
          decode(Uint8List.sublistView(out, 3)).trim(),
          'رقم الحزمة,العدد,الإجمالي',
        );
      }
    });

    test('a CSV with content is saved as the server sent it', () {
      final raw = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('batch_id,count,total\r\n3,2,10\r\n'),
      ]);
      expect(financialReportCsvForSave(raw, 'card-sales'), same(raw));
    });

    test('an empty report with unknown columns is not saved', () {
      expect(
        financialReportCsvForSave(
          Uint8List.fromList([0xEF, 0xBB, 0xBF]),
          'loans',
        ),
        isNull,
      );
    });
  });

  group('6 — final print contract (where cheap and old-server safe)', () {
    test('no QR box when there is no room; the rest still applies', () async {
      final json = _elementsJson();
      (json['elements'] as Map).remove('qr');
      final els = CardElements.fromJson(json);
      expect(els.boxes.containsKey('qr'), isFalse);
      final ctl = await _controller(_server());
      addTearDown(ctl.dispose);
      ctl.updateForm((f) => f.copyWith(showQr: true));
      ctl.moveElement('qr', 30, 30);
      ctl.moveElement('username', 16.1, 20);
      ctl.applyElements(els, ctl.state.form);
      expect(ctl.state.form.usernameX, 30.0);
      expect((ctl.state.form.qrX, ctl.state.form.qrY), (30.0, 30.0));
      expect(autoQrPct(ctl.state.elements), isNull);
    });

    test('«تلقائي · X pt» uses the drawn font_pt when sent', () {
      const box = ElementBox(1, 1, 20, 8);
      expect(autoFontPt(box), 12.0); // old server: h × 0.52 × 72/25.4
      expect(autoFontPt(const ElementBox(1, 1, 20, 8, fontPt: 10.35)), 10.5);
      final parsed = CardElements.fromJson({
        'card': {'width_mm': 54, 'height_mm': 85.6},
        'elements': {
          'username': {'x': 1, 'y': 1, 'w': 20, 'h': 8, 'font_pt': 9.2},
        },
      });
      expect(autoFontPt(parsed.boxes['username']), 9.0);
      expect(kMaxFontPt, 36);
    });

    test('a name over 120 characters is refused with the server wording',
        () async {
      expect(templateNameError('x' * 120), isNull);
      expect(
        templateNameError('x' * 121),
        'اسم القالب طويل جدًّا — 120 حرفًا على الأكثر.',
      );
      final adapter = _server();
      final ctl = await _controller(adapter);
      addTearDown(ctl.dispose);
      ctl.updateForm((f) => f.copyWith(name: 'x' * 121));
      await expectLater(
        ctl.save(),
        throwsA(
          isA<TemplateNameRequired>().having(
            (e) => e.message,
            'message',
            contains('120'),
          ),
        ),
      );
      expect(adapter.where('POST', '/quick-save'), isEmpty);
    });

    test('opens on last_template_id, then default_template_id, then today',
        () async {
      Future<int> opened(Map<String, dynamic> last) async {
        final ctl = await _controller(_server(lastSettings: last));
        addTearDown(ctl.dispose);
        return ctl.state.templateId;
      }

      expect(
        await opened({'last_template_id': 4, 'default_template_id': 3}),
        4,
      );
      expect(
        await opened({'last_template_id': 99, 'default_template_id': 4}),
        4,
      );
      // old server: the is_default flag in the list
      expect(await opened(const {}), 3);
    });

    test('cancel 409 returns the reason; old server errors are ignored',
        () async {
      const reason = 'اكتملت مهمة الطباعة ولا يمكن إلغاؤها.';
      final repo = QuickPrintRepository(
        fakeApiClient(
          RecordingAdapter((_) => FakeResponse.error(409, 'conflict', reason)),
        ),
      );
      expect(await repo.cancelJob(5), reason);
      final old = QuickPrintRepository(
        fakeApiClient(
          RecordingAdapter((_) => FakeResponse.error(405, 'x', 'x')),
        ),
      );
      expect(await old.cancelJob(5), isNull);
    });

    test('download 409 → the Arabic reason (no endless retry)', () async {
      final repo = QuickPrintRepository(
        fakeApiClient(
          RecordingAdapter(
            (_) => FakeResponse.error(
              409,
              'conflict',
              'أُلغيت مهمة الطباعة.',
            ),
          ),
        ),
      );
      await expectLater(
        repo.download(5),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.message, 'message', 'أُلغيت مهمة الطباعة.'),
        ),
      );
      final job = PrintExportJob.fromJson({'id': 5, 'status': 'cancelled'});
      expect((job.cancelled, job.failed, job.done), (true, false, false));
    });
  });

  group('7 — card screens read numbers strictly', () {
    test('«٣» is 3; «-1», «1e3», «7.5», text are refused in Arabic', () {
      expect(validateCardNumber('٣', required: true, min: 1), isNull);
      expect(parseIntInput('٣'), 3);
      expect(validateCardNumber('-1'), 'القيم السالبة غير مسموحة.');
      expect(validateCardNumber('1e3'), contains('«e»'));
      expect(validateCardNumber('7.5'), 'أدخل عددًا صحيحًا بدون كسور.');
      expect(validateCardNumber('abc'), 'أدخل رقمًا صحيحًا (أرقام فقط).');
      expect(validateCardNumber(''), isNull, reason: 'optional stays optional');
      expect(validateCardNumber('', required: true), 'مطلوب');
      // money fields: decimals (Arabic «٫» too) up to the cap
      expect(validateCardNumber('٥٫٥', decimal: true), isNull);
      expect(parseNumberInput('٥٫٥'), 5.5);
      expect(
        validateCardNumber('100001', decimal: true, max: kMaxMoneyAmount),
        startsWith('أعلى قيمة مسموحة'),
      );
      // the batch count keeps its own rule after the strict read
      expect(
        validateCardNumber('٠', check: (v) => validateCardCount(v?.toInt())),
        validateCardCount(0),
      );
    });

    test('a recharge row with a typo is reported, not dropped', () {
      expect(rechargeRowError('٥', '٣'), isNull);
      expect(rechargeRowError('', ''), isNull);
      expect(rechargeRowError('5', 'x'), startsWith('عدد الكروت:'));
      expect(rechargeRowError('-5', '3'), startsWith('قيمة الشحن:'));
      expect(rechargeRowError('0', '3'), startsWith('قيمة الشحن:'));
    });

    testWidgets('the field accepts «٣» and shows the reason for «-1»',
        (tester) async {
      final key = GlobalKey<FormState>();
      final c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: key,
              child: CardNumberField(controller: c, required: true, min: 1),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), '٣');
      expect(key.currentState!.validate(), isTrue);
      await tester.enterText(find.byType(TextFormField), '-1');
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('القيم السالبة غير مسموحة.'), findsOneWidget);
    });
  });

  group('8 — «توليد دفعة كروت»: plan picker + generate dialog', () {
    Map<String, dynamic> plan(
      int id,
      String name, {
      bool enabled = true,
      Map<String, dynamic>? meta,
    }) =>
        {
          'id': id,
          'name': name,
          'enabled': enabled,
          'price': 7,
          'price_card': 5,
          'currency': 'ILS',
          'validity_days': 30,
          if (meta != null) 'metadata': meta,
        };

    Map<String, dynamic> batchJson() => {
          'id': 77,
          'batch_code': 'B-000077',
          'package_name': 'دفعة الاختبار',
          'generated': 10,
        };

    late bool plansFail;
    late FakeResponse Function(RecordedRequest r) onGenerate;

    RecordingAdapter formServer() {
      plansFail = false;
      onGenerate = (_) => FakeResponse.ok({
            'batch': batchJson(),
            'cards': <dynamic>[],
          });
      return RecordingAdapter((r) {
        // fix3: CardPlanPicker now reads the lite `/plans/options` list
        // first (active plans only, server-filtered) — mirror that here.
        if (r.path.endsWith('/plans/options')) {
          if (plansFail) return FakeResponse.error(500, 'internal', 'x');
          return FakeResponse.ok({
            'items': [
              {
                'id': 1,
                'name': 'Gold 1H',
                'price': 5,
                'currency': 'ILS',
                'validity_days': 30,
              },
            ],
          });
        }
        if (r.path.endsWith('/profiles')) {
          if (plansFail) return FakeResponse.error(500, 'internal', 'x');
          return FakeResponse.ok({
            'items': [
              plan(1, 'Gold 1H'),
              plan(2, 'Off plan', enabled: false),
              plan(3, 'Old plan', meta: {'archived': true}),
            ],
          });
        }
        if (r.path.endsWith('/cards/generate')) return onGenerate(r);
        return FakeResponse.ok({'items': <dynamic>[]});
      });
    }

    Future<void> settle(WidgetTester tester, [int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> pumpForm(WidgetTester tester, RecordingAdapter adapter) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/cards/new',
        routes: [
          GoRoute(
            path: '/cards',
            name: 'cards',
            builder: (_, __) => const Text('BATCHES'),
            routes: [
              GoRoute(
                path: 'new',
                name: 'card-batch-new',
                builder: (_, __) => const Scaffold(
                  body: SingleChildScrollView(child: CardBatchFormScreen()),
                ),
              ),
              GoRoute(
                path: 'batches/:id',
                name: 'card-batch-detail',
                builder: (_, st) => Text('DETAIL ${st.pathParameters['id']}'),
              ),
              GoRoute(
                path: 'batches/:id/print',
                name: 'card-batch-print',
                builder: (_, st) => Text('PRINT ${st.pathParameters['id']}'),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plansRepositoryProvider
                .overrideWithValue(PlansRepository(fakeApiClient(adapter))),
            cardsRepositoryProvider
                .overrideWithValue(CardsRepository(fakeApiClient(adapter))),
            tenantCurrencyProvider.overrideWith((ref) => 'ILS'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await settle(tester);
    }

    /// The label of a FormFieldRow (a Text.rich with «*»/hint on phones).
    Finder label(String text) => find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith(text),
        );

    Finder fieldOf(String text) => find.descendant(
          of: find
              .ancestor(of: label(text), matching: find.byType(FormFieldRow))
              .first,
          matching: find.byType(TextField),
        );

    TextField fieldAfter(WidgetTester tester, String text) {
      final row = find.ancestor(
        of: label(text),
        matching: find.byType(FormFieldRow),
      );
      return tester.widget<TextField>(
        find.descendant(of: row.first, matching: find.byType(TextField)),
      );
    }

    Future<void> pickGold(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Gold 1H').last);
      await tester.pumpAndSettle();
    }

    test('price × count, Arabic digits read', () {
      expect(batchTotalPrice('5', '10'), '50');
      expect(batchTotalPrice('٥', '٣'), '15');
      expect(batchTotalPrice('2.5', '3'), '7.5');
      expect(batchTotalPrice('x', '3'), isNull);
      expect(formatBatchNumber(1.25), '1.25');
    });

    test('server 4xx → the field it concerns', () {
      ApiException e(String m, [Object? d]) =>
          ApiException(code: 'validation_error', message: m, details: d);
      expect(generateErrorField(e('الباقة رقم 9 غير موجودة.')), 'plan');
      expect(
        generateErrorField(e('x', {'field': 'count'})),
        'count',
      );
      expect(
        generateErrorField(e('الحدّ الأعلى 5000 بطاقة في الدفعة الواحدة.')),
        'count',
      );
      expect(generateErrorField(e('الخادم مشغول')), isNull);
      // the backend's 422 for a length too short for prefix/suffix/batch no.
      expect(
        generateErrorField(
          e('طول اسم المستخدم المختار 4 محارف لا يتّسع: الأجزاء الثابتة '
              '(بادئة + رقم الحزمة + لاحقة) 5 محارف.'),
        ),
        'username_length',
      );
    });

    testWidgets('only active plans; picking one fills the price and total',
        (tester) async {
      await pumpForm(tester, formServer());
      expect(find.text('معرّف الباقة'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Gold 1H'), findsWidgets);
      expect(find.textContaining('5 ILS · صلاحية 30 يوم'), findsWidgets);
      expect(find.textContaining('Off plan'), findsNothing);
      expect(find.textContaining('Old plan'), findsNothing);
      await tester.tap(find.textContaining('Gold 1H').last);
      await tester.pumpAndSettle();
      expect(fieldAfter(tester, 'سعر البطاقة').controller!.text, '5');
      expect(fieldAfter(tester, 'السعر الإجمالي').controller!.text, '50');
      // Arabic digits in the count
      await tester.enterText(
        fieldOf('العدد'),
        '٣',
      );
      await tester.pump();
      expect(fieldAfter(tester, 'السعر الإجمالي').controller!.text, '15');
    });

    testWidgets('a failed plan list says so and «إعادة المحاولة» reloads',
        (tester) async {
      final adapter = formServer();
      plansFail = true;
      await pumpForm(tester, adapter);
      expect(find.textContaining('تعذّر تحميل الباقات'), findsOneWidget);
      expect(find.text('معرّف الباقة (يدوي)'), findsNothing);
      plansFail = false;
      await tester.tap(find.text('إعادة المحاولة'));
      await settle(tester);
      expect(find.text('اختر الباقة'), findsOneWidget);
      expect(adapter.where('GET', '/plans/options'), hasLength(2));
    });

    testWidgets('progress → success; «طباعة / تصدير» opens the print route',
        (tester) async {
      final adapter = formServer();
      await pumpForm(tester, adapter);
      await pickGold(tester);
      final gate = Completer<void>();
      adapter.beforeRespond = (r) async {
        if (r.path.endsWith('/cards/generate')) await gate.future;
      };
      await tester.tap(find.text('توليد'));
      await settle(tester, 4);
      expect(find.text('جاري توليد 10 بطاقات…'), findsOneWidget);
      gate.complete();
      await settle(tester);
      expect(find.text('تم توليد 10 بطاقات'), findsOneWidget);
      expect(find.textContaining('B-000077'), findsOneWidget);
      expect(find.text('عرض الحزمة'), findsOneWidget);
      expect(find.text('رجوع للحزم'), findsOneWidget);
      await tester.tap(find.text('طباعة / تصدير'));
      await settle(tester);
      expect(find.text('PRINT 77'), findsOneWidget);
    });

    for (final (button, target) in [
      ('عرض الحزمة', 'DETAIL 77'),
      ('رجوع للحزم', 'BATCHES'),
    ]) {
      testWidgets('«$button» → $target', (tester) async {
        await pumpForm(tester, formServer());
        await pickGold(tester);
        await tester.tap(find.text('توليد'));
        await settle(tester);
        await tester.tap(find.text(button));
        await settle(tester);
        expect(find.text(target), findsOneWidget);
      });
    }

    testWidgets('error → «إعادة المحاولة» resends with the SAME key and body',
        (tester) async {
      final adapter = formServer();
      var calls = 0;
      await pumpForm(tester, adapter);
      await pickGold(tester);
      onGenerate = (_) {
        calls++;
        if (calls == 1) {
          return FakeResponse.error(
            503,
            'busy',
            'الخادم مشغول، حاول بعد قليل.',
          );
        }
        return FakeResponse.ok({'batch': batchJson(), 'cards': <dynamic>[]});
      };
      await tester.tap(find.text('توليد'));
      await settle(tester);
      expect(find.text('تعذّر توليد الكروت'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      await settle(tester);
      final posts = adapter.where('POST', '/cards/generate').toList();
      expect(posts, hasLength(2));
      expect(
        posts[1].headers['Idempotency-Key'],
        posts[0].headers['Idempotency-Key'],
      );
      expect(posts[0].headers['Idempotency-Key'], isNotNull);
      expect(jsonEncode(posts[1].body), jsonEncode(posts[0].body));
      expect(find.text('تم توليد 10 بطاقات'), findsOneWidget);
    });

    testWidgets('closing an error keeps the form and shows it at the field',
        (tester) async {
      final adapter = formServer();
      await pumpForm(tester, adapter);
      await pickGold(tester);
      onGenerate = (_) => FakeResponse.error(
            422,
            'validation_error',
            'الباقة رقم 1 غير موجودة.',
          );
      await tester.enterText(
        fieldOf('اسم باقة الكروت'),
        'دفعتي',
      );
      await tester.tap(find.text('توليد'));
      await settle(tester);
      await tester.tap(find.text('إغلاق'));
      await settle(tester);
      expect(find.text('تعذّر توليد الكروت'), findsNothing);
      expect(find.text('الباقة رقم 1 غير موجودة.'), findsOneWidget);
      expect(fieldAfter(tester, 'اسم باقة الكروت').controller!.text, 'دفعتي');
      // no inline card list under the form any more
      expect(find.textContaining('كلمة المرور: '), findsNothing);
    });
  });

  group('9 — card import report', () {
    test('updated server: skipped messages + duplicate_in_file + invalid', () {
      final r = CardBatchImportResult.fromJson({
        'data': {
          'batch': {'id': 5, 'batch_code': 'B-5', 'source_type': 'imported'},
          'inserted_count': 7,
          'skipped_count': 3,
          'skipped': [
            {
              'username': '0599',
              'reason': 'duplicate',
              'message': 'الاسم مستعمل في النظام (بطاقة أو مشترك)',
            },
            {
              'username': 'aa',
              'reason': 'duplicate_in_file',
              'message': 'مكرّر داخل الملف نفسه',
            },
            {'username': '', 'reason': 'missing_username', 'message': ''},
          ],
          'duplicate_in_file': {
            'count': 1,
            'samples': ['aa'],
          },
          'invalid': [
            {
              'reason': 'empty_username',
              'label': 'اسم المستخدم فارغ (حقل مفقود)',
              'count': 1,
              'samples': [''],
            },
          ],
          'radius_sync_enabled': true,
          'radius_synced_count': 7,
        },
      });
      expect(r.duplicateInFile, 1);
      expect(r.invalid.single.label, 'اسم المستخدم فارغ (حقل مفقود)');
      final summary = importResultSummary(r);
      expect(summary, contains('مستورد'));
      expect(summary, contains('مكرّر داخل الملف 1'));
      expect(summary, contains('اسم المستخدم فارغ (حقل مفقود): 1'));
      expect(
        stripBidiMarks(importSkippedLine(r.skipped.first)),
        '0599 — الاسم مستعمل في النظام (بطاقة أو مشترك)',
      );
      // no message: the known reason in Arabic
      expect(importSkippedLine(r.skipped.last), '— — اسم المستخدم فارغ');
    });

    test('old server: codes only, no new counts', () {
      final r = CardBatchImportResult.fromJson({
        'batch': {'id': 5, 'batch_code': 'B-5', 'source_type': 'external'},
        'inserted_count': 2,
        'skipped_count': 1,
        'skipped': [
          {'username': 'x1', 'reason': 'duplicate'},
        ],
      });
      expect(r.duplicateInFile, 0);
      expect(r.invalid, isEmpty);
      expect(importSkippedLine(r.skipped.single), contains('مستعمل'));
      expect(importResultSummary(r), contains('خارجي'));
      expect(kImportSyncCaption, contains('دائمًا'));
    });
  });
}
