import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_mapper.dart';
import 'package:hoberadius_app/features/subscribers/data/subscribers_repository.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/subscribers_list_screen.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _row(String u, {Map<String, dynamic> extra = const {}}) =>
    {
      'id': u.hashCode & 0xffff,
      'username': u,
      'full_name': 'F $u',
      'status': 'enabled',
      'balance': -13.33,
      'expire_at': '2026-10-22T12:04:02Z',
      'mac_lock': null,
      'static_ip': null,
      'plan_id': 8,
      'metadata': {
        'general': {'notes': 'n', 'tags': <String>[]},
        'server_only': {'keep': true},
      },
      ...extra,
    };

void main() {
  group('item 1 — edit form sends only what changed', () {
    final loaded = Subscriber.fromJson(_row('ali'));

    test('untouched form → empty PATCH (no stale balance/expiry)', () {
      final again = Subscriber.fromJson(_row('ali'));
      expect(again.toPatchDiff(loaded), isEmpty);
    });

    test('balance is never sent, even when it differs', () {
      final edited = loaded.copyWith(balance: 999, fullName: 'Ali New');
      final diff = edited.toPatchDiff(loaded);
      expect(diff.keys, ['full_name']);
      expect(diff['full_name'], 'Ali New');
    });

    test('an action changed expiry meanwhile: saving another field keeps it',
        () {
      // The form was loaded BEFORE an extend; the operator edits the name.
      final edited = loaded.copyWith(mobile: '0599');
      final diff = edited.toPatchDiff(loaded);
      expect(diff.containsKey('expire_at'), isFalse);
      expect(diff.containsKey('balance'), isFalse);
      expect(diff, {'mobile': '0599'});
    });

    test('null mac_lock/static_ip are not turned into ""', () {
      expect(loaded.macLock, '');
      final edited = loaded.copyWith(remark: 'x');
      final diff = edited.toPatchDiff(loaded);
      expect(diff.containsKey('mac_lock'), isFalse);
      expect(diff.containsKey('static_ip'), isFalse);
      final withMac =
          Subscriber.fromJson(_row('ali', extra: {'mac_lock': 'AA:BB'}));
      final cleared = withMac.copyWith(macLock: '');
      // copyWith keeps '' → cleared on purpose → null on the wire
      expect(cleared.toPatchDiff(withMac), {'mac_lock': null});
    });

    test('metadata edits are merged into the full server metadata', () {
      final edited = loaded.copyWith(notes: 'changed');
      final diff = edited.toPatchDiff(loaded);
      final meta = diff['metadata'] as Map<String, dynamic>;
      expect((meta['general'] as Map)['notes'], 'changed');
      expect(meta['server_only'], {'keep': true});
    });

    test('changed expiry is sent as UTC ISO', () {
      final when = DateTime.utc(2026, 12, 1, 10).toLocal();
      final diff = loaded.copyWith(expireAt: when).toPatchDiff(loaded);
      expect(diff['expire_at'], startsWith('2026-12-01T10:00:00'));
    });
  });

  test('form round-trip of an untouched row produces no PATCH', () {
    final row = Subscriber.fromJson(
      _row(
        'ali',
        extra: {
          'custom_price': 12.5,
          'device_count': 2,
          'working_days': 'sat,sun',
          'override_concurrent': 1,
          'account_type': 'Personal',
          'metadata': {
            'mikrotik': {'profile': 'p1', 'service': 'pppoe'},
            'radius': {'session_timeout': 3600},
            'general': {
              'notes': 'n',
              'tags': ['a', 'b']
            },
          },
        },
      ),
    );
    final c = {
      for (final k in kSubscriberFormControllerKeys) k: TextEditingController(),
    };
    applySubscriberToForm(row, c);
    final rebuilt = buildSubscriberFromForm(c, selectionsFromSubscriber(row));
    expect(rebuilt.toPatchDiff(row), isEmpty);
    c['full_name']!.text = 'Other';
    final diff = buildSubscriberFromForm(c, selectionsFromSubscriber(row))
        .toPatchDiff(row);
    expect(diff, {'full_name': 'Other'});
  });

  group('item 3 — create validation + duplicate username', () {
    test('username rule = rename rule', () {
      expect(validateNewSubscriberUsername('st12 bad'), isNotNull);
      expect(validateNewSubscriberUsername('اسم_عربي'), isNotNull);
      expect(validateNewSubscriberUsername('a/b'), isNotNull);
      expect(validateNewSubscriberUsername('😀abc'), isNotNull);
      expect(validateNewSubscriberUsername('x' * 300), isNotNull);
      expect(validateNewSubscriberUsername('ab'), isNotNull);
      expect(validateNewSubscriberUsername('ahmad.2@net'), isNull);
      // the rename dialog shares the same format check
      expect(
        validateNewUsername('st12 bad', current: 'x'),
        validateNewSubscriberUsername('st12 bad'),
      );
    });

    test('password minimum length', () {
      expect(validateNewSubscriberPassword('1'), isNotNull);
      expect(validateNewSubscriberPassword('    '), isNotNull);
      expect(validateNewSubscriberPassword('1234'), isNull);
    });

    test('existing username is refused before POST (old servers upsert)',
        () async {
      final adapter = RecordingAdapter((r) {
        if (r.method == 'GET') return FakeResponse.ok(_row('st12_001'));
        return FakeResponse.ok(_row('st12_001'), status: 201);
      });
      final repo = SubscribersRepository(fakeApiClient(adapter));
      await expectLater(
        repo.create(Subscriber(username: 'st12_001', password: '123456')),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.message, 'message', contains('مستخدم مسبقًا')),
        ),
      );
      expect(adapter.where('POST', '/accounts'), isEmpty);
    });

    test('server 409 Arabic message reaches the form (not «success»)',
        () async {
      final adapter = RecordingAdapter((r) {
        if (r.method == 'GET') {
          return FakeResponse.error(404, 'not_found', 'الحساب غير موجود.');
        }
        return FakeResponse.error(
          409,
          'conflict',
          'اسم المستخدم مستخدم مسبقًا.',
        );
      });
      final repo = SubscribersRepository(fakeApiClient(adapter));
      try {
        await repo.create(Subscriber(username: 'newuser', password: '123456'));
        fail('should throw');
      } catch (e) {
        expect(visibleErrorMessage(e), 'اسم المستخدم مستخدم مسبقًا.');
      }
      expect(adapter.where('POST', '/accounts'), hasLength(1));
    });

    test('invalid username never reaches the server', () async {
      final adapter = RecordingAdapter((_) => FakeResponse.ok({}));
      final repo = SubscribersRepository(fakeApiClient(adapter));
      await expectLater(
        repo.create(Subscriber(username: 'st12 bad', password: '123456')),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('item 2 — server-side search + paging', () {
    ProviderContainer container(RecordingAdapter adapter) {
      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter))
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sends q/search/limit/offset and pages with total', () async {
      final adapter = RecordingAdapter((r) {
        final offset = int.parse('${r.query['offset']}');
        final items = [
          for (var i = offset; i < offset + 50 && i < 120; i++) _row('u$i'),
        ];
        return FakeResponse.ok({
          'items': items,
          'total': 120,
          'has_more': offset + items.length < 120,
        });
      });
      final c = container(adapter);
      const q = SubscribersQuery(search: 'demo050');
      final sub = c.listen(subscribersListProvider(q), (_, __) {});
      final first = await c.read(subscribersListProvider(q).future);
      expect(first.items, hasLength(50));
      expect(first.total, 120);
      expect(first.hasMore, isTrue);
      final req = adapter.requests.first;
      expect(req.query['q'], 'demo050');
      expect(req.query['search'], 'demo050');
      expect('${req.query['limit']}', '50');
      await c.read(subscribersListProvider(q).notifier).loadMore();
      await c.read(subscribersListProvider(q).notifier).loadMore();
      final all = c.read(subscribersListProvider(q)).value!;
      expect(all.items, hasLength(120));
      expect(all.hasMore, isFalse);
      expect(
        adapter.requests.map((r) => '${r.query['offset']}'),
        ['0', '50', '100'],
      );
      sub.close();
    });

    test('old server (ignores offset, no total) stops instead of looping',
        () async {
      final adapter = RecordingAdapter(
        (_) => FakeResponse.ok({
          'items': [for (var i = 0; i < 50; i++) _row('u$i')],
          'count': 50,
        }),
      );
      final c = container(adapter);
      const q = SubscribersQuery();
      final sub = c.listen(subscribersListProvider(q), (_, __) {});
      final first = await c.read(subscribersListProvider(q).future);
      expect(first.hasMore, isTrue); // a full page may have more
      await c.read(subscribersListProvider(q).notifier).loadMore();
      final after = c.read(subscribersListProvider(q)).value!;
      expect(after.items, hasLength(50)); // duplicates dropped
      expect(after.hasMore, isFalse);
      sub.close();
    });

    test('«ينتهي خلال ٣ أيام» asks the server with expiring_within_days=3',
        () async {
      final soon = DateTime.now().toUtc().add(const Duration(days: 1));
      final late = DateTime.now().toUtc().add(const Duration(days: 20));
      final adapter = RecordingAdapter(
        (_) => FakeResponse.ok({
          'items': [
            _row('soon', extra: {'expire_at': soon.toIso8601String()}),
            _row('late', extra: {'expire_at': late.toIso8601String()}),
          ],
          'total': 2,
        }),
      );
      final c = container(adapter);
      const q = SubscribersQuery(status: kExpiringSoonFilter);
      final sub = c.listen(subscribersListProvider(q), (_, __) {});
      final page = await c.read(subscribersListProvider(q).future);
      final req = adapter.requests.single;
      expect(req.query['status'], 'enabled');
      expect('${req.query['expiring_within_days']}', '3');
      // old servers ignore the filter → the client-side guard still applies
      expect(page.items.map((s) => s.username), ['soon']);
      sub.close();
    });
  });

  group('item 11 — status chips at 360×640', () {
    testWidgets('all 7 chips are on screen (wrapped, none hidden)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = RecordingAdapter(
        (_) => FakeResponse.ok({'items': <dynamic>[], 'total': 0}),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: SubscribersListScreen(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final chips = find.byType(ChoiceChip);
      expect(chips, findsNWidgets(7));
      for (final e in chips.evaluate()) {
        final box = e.renderObject! as RenderBox;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        expect(
          rect.left >= 0 && rect.right <= 360,
          isTrue,
          reason: 'chip off-screen: $rect',
        );
      }
      expect(tester.takeException(), isNull);
    });
  });
}
