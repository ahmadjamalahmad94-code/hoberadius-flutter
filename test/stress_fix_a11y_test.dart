import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscriber_form_screen.dart';
import 'package:hoberadius_app/shared/widgets/form_field_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('en'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('12: a FormFieldRow text field carries its label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormFieldRow(
            label: 'الجوال',
            hint: 'بصيغة 05…',
            child: TextFormField(),
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(TextFormField));
    final data = node.getSemanticsData();
    expect(data.label, contains('الجوال'));
    expect(data.hint, contains('بصيغة'));
    expect(data.flagsCollection.isTextField, isTrue);
    handle.dispose();
  });

  testWidgets('12: the new-subscriber form exposes labelled inputs',
      (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = RecordingAdapter((_) => FakeResponse.ok({'items': []}));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SubscriberFormScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['اسم المستخدم', 'كلمة المرور', 'الجوال']) {
      final f = find.bySemanticsLabel(RegExp('^$label'));
      expect(f, findsWidgets, reason: label);
      final data = tester.getSemantics(f.first).getSemanticsData();
      expect(data.flagsCollection.isTextField, isTrue, reason: label);
    }
    expect(find.byTooltip('رجوع'), findsOneWidget);
    handle.dispose();
  });
}
