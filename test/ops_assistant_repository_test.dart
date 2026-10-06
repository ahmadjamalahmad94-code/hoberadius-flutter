import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/ops_assistant/data/ops_assistant_repository.dart';
import 'package:hoberadius_app/features/ops_assistant/domain/ops_models.dart';

class _Tokens implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => 'token';
  @override
  Future<void> write(String token) async {}
}

class _Endpoint implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

typedef _Handler = (int, Object?) Function(RequestOptions o);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final _Handler handler;
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
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      body is String ? body : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [
          body is String ? 'text/html' : 'application/json',
        ],
      },
    );
  }
}

(OpsAssistantRepository, _Adapter) _repo(_Handler h) {
  final api = ApiClient(
    _Tokens(),
    _Endpoint(),
    config: const ApiClientConfig(maxRetries: 0),
  );
  final adapter = _Adapter(h);
  api.dio.httpClientAdapter = adapter;
  return (OpsAssistantRepository(api), adapter);
}

Map<String, dynamic> _fail(String code, String msg, [Map? details]) => {
      'ok': false,
      'error': {
        'code': code,
        'message': msg,
        if (details != null) 'details': details,
      },
    };

void main() {
  test('status: an older server (404 page) → not supported', () async {
    final (repo, _) = _repo((_) => (404, '<html>Not Found</html>'));
    final s = await repo.status();
    expect(s.unavailableReason, OpsUnavailableReason.notSupported);
  });

  test('status: JSON router 404 → not supported', () async {
    final (repo, _) = _repo(
      (_) => (404, _fail('not_found', 'المسار أو السجلّ المطلوب غير موجود.')),
    );
    expect((await repo.status()).available, isFalse);
  });

  test('status: unbound credential → not supported', () async {
    final (repo, _) = _repo(
      (_) => (
        403,
        _fail('forbidden', 'المساعد يعمل بصلاحيّات مدير', {
          'reason': 'ops_requires_admin',
        })
      ),
    );
    expect(
      (await repo.status()).unavailableReason,
      OpsUnavailableReason.notSupported,
    );
  });

  test('status: other failures surface', () async {
    final (repo, _) = _repo((_) => (500, _fail('internal', 'خطأ داخلي')));
    expect(repo.status(), throwsA(isA<ApiException>()));
  });

  test('message: path, body, long receive timeout', () async {
    final (repo, adapter) = _repo(
      (_) => (
        200,
        {
          'ok': true,
          'data': {
            'conversation_id': 'c1',
            'replies': [
              {'type': 'assistant', 'action': 'reply', 'text': 'أهلًا'},
            ],
          },
        }
      ),
    );
    final turn = await repo.sendMessage(text: 'مرحبا');
    expect(turn.conversationId, 'c1');
    expect(turn.replies.single.text, 'أهلًا');
    final req = adapter.requests.single;
    expect(req.method, 'POST');
    expect(req.path, kOpsMessagePath);
    expect(req.data, {'text': 'مرحبا'});
    expect(req.receiveTimeout, kOpsTurnTimeout);

    await repo.sendMessage(conversationId: 'c1', text: 'تابع');
    expect(
      adapter.requests.last.data,
      {'conversation_id': 'c1', 'text': 'تابع'},
    );
  });

  test('confirm sends id + hash + Idempotency-Key', () async {
    final (repo, adapter) = _repo(
      (_) => (
        200,
        {
          'ok': true,
          'data': {
            'conversation_id': 'c1',
            'report': {'status': 'executed', 'steps': []},
            'show_once': null,
          },
        }
      ),
    );
    final out = await repo.confirm(
      conversationId: 'c1',
      proposal: const OpsProposal(proposalId: 'p1', proposalHash: 'h1'),
      idempotencyKey: 'k-1',
    );
    expect(out.report.status, 'executed');
    expect(out.secrets, isEmpty);
    final req = adapter.requests.single;
    expect(req.path, kOpsConfirmPath);
    expect(req.data, {
      'conversation_id': 'c1',
      'proposal_id': 'p1',
      'proposal_hash': 'h1',
    });
    expect(req.headers['Idempotency-Key'], 'k-1');
  });

  test('start-event and cancel bodies', () async {
    final (repo, adapter) = _repo(
      (_) => (
        200,
        {
          'ok': true,
          'data': {'conversation_id': 'c9', 'replies': []},
        }
      ),
    );
    final turn = await repo.startFromSuggestion(
      const OpsSuggestion(
        eventType: 'low_card_stock',
        index: 2,
        title: 't',
        text: 'x',
      ),
    );
    expect(turn.conversationId, 'c9');
    expect(adapter.requests.last.path, kOpsStartEventPath);
    expect(
      adapter.requests.last.data,
      {'event_type': 'low_card_stock', 'index': 2},
    );
    await repo.cancel('c9');
    expect(adapter.requests.last.path, kOpsCancelPath);
    expect(adapter.requests.last.data, {'conversation_id': 'c9'});
  });

  group('error mapping', () {
    Future<OpsError> errOf(int status, Object body) async {
      final (repo, _) = _repo((_) => (status, body));
      try {
        await repo.sendMessage(conversationId: 'c1', text: 'x');
      } on OpsError catch (e) {
        return e;
      }
      fail('expected OpsError');
    }

    test('missing route → server not updated', () async {
      final e = await errOf(404, '<html>Not Found</html>');
      expect(e.notUpdated, isTrue);
      expect(e.message, contains('لم يُحدَّث'));
      final e2 = await errOf(405, _fail('method_not_allowed', 'x'));
      expect(e2.notUpdated, isTrue);
    });

    test('conversation not found → start over', () async {
      final e = await errOf(
        404,
        _fail('not_found', 'المحادثة غير موجودة — ابدأ محادثة جديدة.'),
      );
      expect(e.conversationLost, isTrue);
      expect(e.notUpdated, isFalse);
    });

    test('flag off / weak passwords → unavailable', () async {
      final e = await errOf(
        403,
        _fail('forbidden', 'مساعد العمليّات غير مفعّل لهذه الشبكة.', {
          'reason': 'assistant_disabled',
        }),
      );
      expect(e.unavailable, isTrue);
      final e2 = await errOf(
        403,
        {'ok': false, 'code': 'unavailable', 'error': 'المساعد متوقّف'},
      );
      expect(e2.message, 'المساعد متوقّف');
    });

    test('validation keeps the server text', () async {
      final e =
          await errOf(422, _fail('validation_error', 'اكتب رسالة أوّلًا.'));
      expect(e.message, 'اكتب رسالة أوّلًا.');
      expect(e.unavailable || e.notUpdated || e.conversationLost, isFalse);
    });
  });

  test('suggestions read the existing /ops/events', () async {
    final (repo, adapter) = _repo(
      (_) => (
        200,
        {
          'ok': true,
          'data': {
            'items': [
              {
                'type': 'plan_without_offers',
                'data': {
                  'plans': [
                    {'plan_id': 1, 'plan_name': 'أسبوعي'},
                  ],
                },
              },
            ],
            'count': 1,
          },
        }
      ),
    );
    final list = await repo.suggestions();
    expect(adapter.requests.single.path, kOpsEventsPath);
    expect(list.single.title, 'باقة بلا عرض بيع');
  });
}
