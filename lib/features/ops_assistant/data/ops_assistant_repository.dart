import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/idempotency.dart';
import '../domain/ops_labels.dart';
import '../domain/ops_models.dart';

// ════════════════════════════════════════════════════════════════════════
// Endpoints.
//
// Existing executor API (radius-module app/api/v1/ops.py):
//   GET  /api/v1/ops/status   availability (flag + password gate, counts)
//   GET  /api/v1/ops/events   level-4 detector events for this admin
//
// The MODEL TURN (conversation.run_model) is served to the web page by
// /admin/radius/ops-assistant/* (session + CSRF). The app calls the same
// five operations under the bearer-token API — a 1:1 mirror of
// routes/ops_assistant.py, same request/response bodies inside the usual
// `{ok, data}` envelope:
//   POST /api/v1/ops/assistant/message      {conversation_id?, text}
//                                           → {conversation_id, replies[]}
//   POST /api/v1/ops/assistant/start-event  {event_type, index}
//                                           → {conversation_id, replies[]}
//   POST /api/v1/ops/assistant/confirm      {conversation_id, proposal_id,
//                                            proposal_hash} + Idempotency-Key
//                                           → {report, show_once?}
//   POST /api/v1/ops/assistant/cancel       {conversation_id}
// A server without them answers 404/405 → «الخادم لم يُحدَّث».
// ════════════════════════════════════════════════════════════════════════
const kOpsStatusPath = '/api/v1/ops/status';
const kOpsEventsPath = '/api/v1/ops/events';
const kOpsMessagePath = '/api/v1/ops/assistant/message';
const kOpsStartEventPath = '/api/v1/ops/assistant/start-event';
const kOpsConfirmPath = '/api/v1/ops/assistant/confirm';
const kOpsCancelPath = '/api/v1/ops/assistant/cancel';

/// One admin message may make up to 4 model calls on the server (60 s each
/// by default) — far beyond the client's 30 s default receive timeout.
const kOpsTurnTimeout = Duration(minutes: 5);

/// A plan executes several real API calls in a row.
const kOpsConfirmTimeout = Duration(minutes: 2);

/// A user-facing failure of an assistant call ([message] is Arabic).
class OpsError implements Exception {
  const OpsError(
    this.message, {
    this.code = '',
    this.notUpdated = false,
    this.unavailable = false,
    this.conversationLost = false,
  });

  final String message;
  final String code;

  /// The server has no such endpoint (older build).
  final bool notUpdated;

  /// 403: the tenant flag went off or an admin got a weak password since
  /// the screen opened — the screen re-reads `/ops/status`.
  final bool unavailable;

  /// 404 «المحادثة غير موجودة»: start a new conversation (web parity).
  final bool conversationLost;

  @override
  String toString() => message;
}

bool _hasArabic(String s) => s.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

Map<String, dynamic> _details(ApiException e) {
  final d = e.details;
  return d is Map ? d.map((k, v) => MapEntry(k.toString(), v)) : const {};
}

/// The generic 404 texts of a router miss: the client's fallback for an
/// HTML page, and the API's JSON 404 (app/api/errors.py NOT_FOUND_MESSAGE).
const _kRouteMissTexts = {
  'العنصر المطلوب غير موجود.',
  'المسار أو السجلّ المطلوب غير موجود.',
  'تعذّر تنفيذ الطلب.',
};

/// A 404/405 from the router (no such endpoint) — not a specific «المحادثة
/// غير موجودة» from the assistant itself.
bool _missingRoute(ApiException e) {
  if (e.status == 405) return true;
  if (e.status != 404) return false;
  final msg = e.message.trim();
  return msg.isEmpty || _kRouteMissTexts.contains(msg) || !_hasArabic(msg);
}

OpsError mapOpsError(Object error) {
  if (error is OpsError) return error;
  if (error is! ApiException) {
    final t = error.toString().trim();
    return OpsError(t.isEmpty ? OpsTexts.network : t);
  }
  if (_missingRoute(error)) {
    return OpsError(OpsTexts.notSupported, code: error.code, notUpdated: true);
  }
  final reason = '${_details(error)['reason'] ?? ''}';
  if (error.status == 403 &&
      (error.code == 'unavailable' ||
          reason == 'assistant_disabled' ||
          reason == 'weak_admin_passwords')) {
    return OpsError(error.message, code: error.code, unavailable: true);
  }
  if (error.status == 404) {
    return OpsError(
      _hasArabic(error.message)
          ? error.message
          : 'المحادثة غير موجودة — ابدأ محادثة جديدة.',
      code: error.code,
      conversationLost: true,
    );
  }
  final msg = error.message.trim();
  return OpsError(msg.isEmpty ? OpsTexts.network : msg, code: error.code);
}

/// What the chat screen needs from the server (a fake in tests).
abstract class OpsAssistantGateway {
  Future<OpsStatus> status();
  Future<List<OpsSuggestion>> suggestions();
  Future<OpsTurn> sendMessage({String? conversationId, required String text});
  Future<OpsTurn> startFromSuggestion(OpsSuggestion suggestion);
  Future<OpsConfirmOutcome> confirm({
    required String conversationId,
    required OpsProposal proposal,
    required String idempotencyKey,
  });
  Future<void> cancel(String conversationId);
}

class OpsAssistantRepository implements OpsAssistantGateway {
  OpsAssistantRepository(this._api);
  final ApiClient _api;

  @override
  Future<OpsStatus> status() async {
    try {
      return OpsStatus.fromJson(await _api.get(kOpsStatusPath));
    } on ApiException catch (e) {
      // Older server, or a credential not bound to an admin
      // (`ops_requires_admin`): the assistant does not exist for this app.
      if (_missingRoute(e) ||
          '${_details(e)['reason'] ?? ''}' == 'ops_requires_admin') {
        return const OpsStatus.notSupported();
      }
      rethrow;
    }
  }

  @override
  Future<List<OpsSuggestion>> suggestions() async {
    try {
      return opsSuggestionsFromEvents(await _api.get(kOpsEventsPath));
    } catch (e) {
      throw mapOpsError(e);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration? timeout,
    Map<String, String>? headers,
  }) async {
    try {
      return await _api.post(
        path,
        body: body,
        headers: headers,
        receiveTimeout: timeout,
      );
    } catch (e) {
      throw mapOpsError(e);
    }
  }

  @override
  Future<OpsTurn> sendMessage({
    String? conversationId,
    required String text,
  }) async {
    final res = await _post(
      kOpsMessagePath,
      {
        if (conversationId != null && conversationId.isNotEmpty)
          'conversation_id': conversationId,
        'text': text,
      },
      timeout: kOpsTurnTimeout,
    );
    return OpsTurn.fromJson(res);
  }

  @override
  Future<OpsTurn> startFromSuggestion(OpsSuggestion suggestion) async {
    final res = await _post(
      kOpsStartEventPath,
      {'event_type': suggestion.eventType, 'index': suggestion.index},
      timeout: kOpsTurnTimeout,
    );
    return OpsTurn.fromJson(res);
  }

  @override
  Future<OpsConfirmOutcome> confirm({
    required String conversationId,
    required OpsProposal proposal,
    required String idempotencyKey,
  }) async {
    final res = await _post(
      kOpsConfirmPath,
      {
        'conversation_id': conversationId,
        'proposal_id': proposal.proposalId,
        'proposal_hash': proposal.proposalHash,
      },
      timeout: kOpsConfirmTimeout,
      headers: idempotencyHeaders(idempotencyKey),
    );
    return OpsConfirmOutcome.fromJson(res);
  }

  @override
  Future<void> cancel(String conversationId) async {
    await _post(kOpsCancelPath, {'conversation_id': conversationId});
  }
}

final opsAssistantGatewayProvider = Provider<OpsAssistantGateway>((ref) {
  return OpsAssistantRepository(ref.watch(apiClientProvider));
});
