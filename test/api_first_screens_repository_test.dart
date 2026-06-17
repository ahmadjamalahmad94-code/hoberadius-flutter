import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/admin_alerts/data/admin_alerts_repository.dart';
import 'package:hoberadius_app/features/mikrotik/data/mikrotik_repository.dart';
import 'package:hoberadius_app/features/store_admin/data/store_admin_repository.dart';

class _MemTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => 'token';
  @override
  Future<void> write(String token) async {}
}

class _MemEndpointStorage implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

/// Returns a programmed body per path + records every request.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final p = options.path;
    final data = switch (p) {
      '/api/v1/alerts/telegram' => {
          'bot': {
            'has_token': true,
            'token_masked': '…ab12',
            'chat_id': '-100',
            'thread_id': '',
            'enabled': true,
            'ready': true,
          },
          'groups': [
            {'key': 'subs', 'label': 'المشتركون', 'icon': 'users'},
          ],
          'catalogue': [
            {
              'key': 'sub_expiring',
              'group': 'subs',
              'group_label': 'المشتركون',
              'label': 'اشتراك على وشك الانتهاء',
              'description': 'تنبيه قبل الانتهاء',
              'enabled': true,
              'template': '...',
              'preview': 'سينتهي اشتراك أحمد غدًا',
            },
          ],
        },
      '/api/v1/alerts/telegram/bot' => {
          'bot': {
            'has_token': true,
            'token_masked': '…ab12',
            'chat_id': '-200',
            'thread_id': '5',
            'enabled': false,
            'ready': false,
          },
        },
      '/api/v1/alerts/telegram/alerts/sub_expiring/toggle' => {
          'key': 'sub_expiring',
          'enabled': false,
        },
      '/api/v1/store/admin/support' => {
          'deposits': {
            'pending': [
              {
                'id': 7,
                'card_user_id': 3,
                'payer_name': 'سامي',
                'amount_claimed': '20.00',
                'status': 'pending',
                'status_ar': 'بانتظار',
                'method': 'bank',
                'method_ar': 'تحويل بنكي',
                'currency': 'JOD',
              },
            ],
            'resolved': <dynamic>[],
            'pending_count': 1,
          },
          'withdrawals': {
            'pending': <dynamic>[],
            'resolved': <dynamic>[],
            'pending_count': 0,
          },
          'chat_threads': [
            {
              'card_user_id': 3,
              'display_name': 'سامي',
              'mobile': '0790',
              'last_body': 'مرحبا',
              'unread_admin_count': 2,
              'total_count': 4,
            },
          ],
          'chat_unread_count': 2,
          'payment_methods': [
            {'id': 1, 'method': 'bank', 'label': 'البنك', 'active': 1},
          ],
        },
      '/api/v1/store/admin/deposits/7/confirm' => {
          'request_id': 7,
          'status': 'confirmed',
        },
      '/api/v1/store/admin/payment-methods' => {
          'payment_method': {'id': 9, 'method': 'wallet', 'label': 'محفظة'},
        },
      '/api/v1/store/admin/chat/3' => {
          'thread': [
            {'id': 1, 'sender': 'customer', 'body': 'مرحبا'},
            {'id': 2, 'sender': 'admin', 'body': 'أهلًا'},
          ],
          'status': 'open',
        },
      '/api/v1/mikrotik/3/program' => {
          'nas': {'id': 3, 'name': 'فرع', 'address': '10.0.0.1'},
          'kind': 'hotspot',
          'form_fields': {'interface': 'ether2', 'dns_servers': '8.8.8.8'},
          'router_state': {
            'interfaces': [
              {'name': 'ether2'},
              {'name': 'ether3'},
            ],
            'addresses': <dynamic>[],
            'routes': <dynamic>[],
          },
        },
      '/api/v1/mikrotik/3/program/plan' => {
          'plan': {
            'kind': 'hotspot',
            'script': '/ip ...',
            'summary': ['ينشئ pool', 'يضيف عنوان'],
            'warnings': <dynamic>[],
            'risks': <dynamic>[],
            'commands': [
              {
                'path': '/ip/pool/add',
                'attrs': {'name': 'hs', 'ranges': '10.5.0.2-10.5.0.254'},
              },
            ],
          },
          'change_preview': null,
          'backup_warning_ar': 'لا توجد نسخة احتياطية حديثة.',
        },
      _ => {'ok': true},
    };
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

ApiClient _client(_Adapter adapter) {
  final c = ApiClient(_MemTokenStorage(), _MemEndpointStorage());
  c.dio.httpClientAdapter = adapter;
  return c;
}

void main() {
  test('AdminAlertsRepository wires telegram catalogue + bot + toggle',
      () async {
    final adapter = _Adapter();
    final repo = AdminAlertsRepository(_client(adapter));

    final snap = await repo.catalogue();
    expect(snap.bot.hasToken, isTrue);
    expect(snap.bot.tokenMasked, '…ab12');
    expect(snap.catalogue.single.preview, contains('سينتهي'));

    final bot = await repo.saveBot(chatId: '-200', threadId: '5', enabled: true);
    expect(bot.chatId, '-200');

    final enabled = await repo.toggleAlert('sub_expiring', false);
    expect(enabled, isFalse);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'GET /api/v1/alerts/telegram',
      'PATCH /api/v1/alerts/telegram/bot',
      'POST /api/v1/alerts/telegram/alerts/sub_expiring/toggle',
    ]);
    // Blank token must NOT be sent (PATCH-keep semantics).
    expect((adapter.requests[1].data as Map).containsKey('bot_token'), isFalse);
  });

  test('StoreAdminRepository wires support + confirm + pm-create + chat',
      () async {
    final adapter = _Adapter();
    final repo = StoreAdminRepository(_client(adapter));

    final snap = await repo.support();
    expect(snap.depositsPendingCount, 1);
    expect(snap.depositsPending.single.amount, '20.00');
    expect(snap.chatUnreadCount, 2);
    expect(snap.paymentMethods.single.active, isTrue);

    await repo.confirmDeposit(7, confirmedAmount: '20', note: 'ok');
    final pm = await repo.createPaymentMethod(method: 'wallet', label: 'محفظة');
    expect(pm.id, 9);
    final messages = await repo.chatThread(3);
    expect(messages.length, 2);
    expect(messages.last.fromAdmin, isTrue);

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'GET /api/v1/store/admin/support',
      'POST /api/v1/store/admin/deposits/7/confirm',
      'POST /api/v1/store/admin/payment-methods',
      'GET /api/v1/store/admin/chat/3',
    ]);
  });

  test('MikrotikRepository wires program state + plan', () async {
    final adapter = _Adapter();
    final repo = MikrotikRepository(_client(adapter));

    final state = await repo.programState(3, kind: 'hotspot');
    expect(state.nasName, 'فرع');
    expect(state.interfaces, ['ether2', 'ether3']);
    expect(state.formFields['dns_servers'], '8.8.8.8');

    final planResult = await repo.programPlan(3, {
      'kind': 'hotspot',
      'interface': 'ether2',
      'cidr': '10.5.0.1/24',
    });
    expect(planResult.plan.commands.single.path, '/ip/pool/add');
    expect(planResult.plan.hasRisks, isFalse);
    expect(planResult.backupWarning, contains('نسخة احتياطية'));

    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'GET /api/v1/mikrotik/3/program',
      'POST /api/v1/mikrotik/3/program/plan',
    ]);
    expect(adapter.requests.first.queryParameters['kind'], 'hotspot');
  });
}
