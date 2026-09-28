import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_search_field.dart';
import 'package:hoberadius_app/features/tickets/application/tickets_providers.dart';
import 'package:hoberadius_app/features/tickets/data/tickets_repository.dart';

import 'support/fake_api.dart';

void main() {
  test('M5: tickets page with limit/offset past the old 200 cap', () async {
    final adapter = RecordingAdapter((r) {
      final offset = int.parse('${r.query['offset']}');
      final n = (235 - offset).clamp(0, 50);
      return FakeResponse.ok({
        'items': [
          for (var i = 0; i < n; i++)
            {'id': 235 - offset - i, 'subject': 't', 'status': 'open'},
        ],
        'count': n,
        'has_more': offset + n < 235,
      });
    });
    final c = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
    );
    addTearDown(c.dispose);
    final sub = c.listen(ticketsPageProvider, (_, __) {});
    await c.read(ticketsPageProvider.future);
    for (var i = 0; i < 6; i++) {
      await c.read(ticketsPageProvider.notifier).loadMore();
    }
    final page = c.read(ticketsPageProvider).value!;
    expect(page.items, hasLength(235));
    expect(page.items.last.id, 1); // seed ticket #1 reachable
    expect(page.hasMore, isFalse);
    sub.close();
  });

  test('ticket decision sends expected_status', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.ok({'service_request': {}, 'ticket': {}}),
    );
    final repo = TicketsRepository(fakeApiClient(adapter));
    await repo.decideServiceRequest(
      ticketId: 7,
      decision: 'approve',
      expectedStatus: 'open',
    );
    expect(adapter.requests.single.jsonBody['expected_status'], 'open');
  });

  testWidgets(
      'A11 F-13 / L11: the subscriber picker searches the server, '
      'no pre-selection', (tester) async {
    final adapter = RecordingAdapter(
      (r) => FakeResponse.ok({
        'items': [
          {'id': 5050, 'username': 'demo050', 'full_name': 'ديمو'},
        ],
        'total': 1,
      }),
    );
    int? picked = -1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SubscriberSearchField(onChanged: (s) => picked = s?.id),
          ),
        ),
      ),
    );
    expect(adapter.requests, isEmpty); // nothing preloaded / preselected
    await tester.enterText(find.byType(TextField), 'demo050');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(adapter.requests.single.query['q'], 'demo050');
    await tester.tap(find.text('ديمو'));
    await tester.pumpAndSettle();
    expect(picked, 5050);
    expect(find.textContaining('demo050'), findsOneWidget);
  });
}
