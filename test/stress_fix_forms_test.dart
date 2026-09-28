import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/format/input_rules.dart';
import 'package:hoberadius_app/features/tickets/presentation/ticket_detail_screen.dart';

import 'support/fake_api.dart';

void main() {
  test('L11: e-mail and id rules', () {
    expect(validateOptionalEmail(''), isNull);
    expect(validateOptionalEmail('a@b.co'), isNull);
    expect(validateOptionalEmail('not-an-email'), isNotNull);
    expect(validateOptionalEmail('a@b'), isNotNull);
    expect(validateOptionalId(''), isNull);
    expect(validateOptionalId('12'), isNull);
    expect(validateOptionalId('abc'), isNotNull);
    expect(validateOptionalId('0'), isNotNull);
  });

  testWidgets('L6: two taps in the same frame send ONE ticket reply',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final adapter = RecordingAdapter((r) {
      if (r.method == 'POST') {
        return FakeResponse.ok({'id': 1, 'body': 'x'}, status: 201);
      }
      return FakeResponse.ok({
        'ticket': {'id': 7, 'subject': 's', 'status': 'open'},
        'replies': <dynamic>[],
      });
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TicketDetailScreen(ticketId: 7)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة رد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'رد واحد');
    await tester.pump();
    final send = find.text('إرسال');
    await tester.tap(send);
    await tester.tap(send, warnIfMissed: false); // same frame, no pump
    await tester.pumpAndSettle();
    expect(adapter.where('POST', '/replies'), hasLength(1));
  });
}
