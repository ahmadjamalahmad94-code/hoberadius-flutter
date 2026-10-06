// Operations assistant (experimental) — wire models.
//
// Mirrors the backend contract (radius-module docs/OPS_EXECUTOR.md, catalog
// ops-v2) and the web chat page (templates/radius/ops_assistant.html +
// static/js/ops_assistant.js). Every text the model wrote (`text`) is shown
// as PLAIN text by the UI — never parsed as markup.

Map<String, dynamic> _map(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return const {};
}

List<Map<String, dynamic>> _maps(Object? v) => v is List
    ? [
        for (final e in v)
          if (e is Map) _map(e),
      ]
    : const [];

int _int(Object? v, [int fallback = 0]) =>
    v is num ? v.toInt() : int.tryParse('${v ?? ''}'.trim()) ?? fallback;

String _str(Object? v) => v == null ? '' : v.toString();

bool _bool(Object? v) => v == true || v == 1 || v == 'true' || v == '1';

/// The envelope's `data` when present (API `ok()`), else the map itself.
Map<String, dynamic> opsData(Map<String, dynamic> res) {
  final d = res['data'];
  return d is Map ? _map(d) : res;
}

// ─────────────────────────── availability ────────────────────────────

/// `password_gate` of `/ops/status` — counts only, never ids.
class OpsPasswordGate {
  const OpsPasswordGate({
    this.ready = false,
    this.adminsChecked = 0,
    this.defaultPasswordCount = 0,
    this.mustChangeCount = 0,
  });

  factory OpsPasswordGate.fromJson(Map<String, dynamic> j) => OpsPasswordGate(
        ready: _bool(j['ready']),
        adminsChecked: _int(j['admins_checked']),
        defaultPasswordCount: _int(j['default_password_count']),
        mustChangeCount: _int(j['must_change_count']),
      );

  final bool ready;
  final int adminsChecked;
  final int defaultPasswordCount;
  final int mustChangeCount;
}

/// Why the assistant is not available here.
enum OpsUnavailableReason {
  /// The tenant flag `ops_assistant.enabled` is off (the default).
  disabled,

  /// An admin still has a default or temporary password.
  weakAdminPasswords,

  /// The server has no `/api/v1/ops/*` (older build) — or answered
  /// `ops_requires_admin` for this credential.
  notSupported,
}

/// `GET /api/v1/ops/status`.
class OpsStatus {
  const OpsStatus({
    required this.available,
    this.flagEnabled = false,
    this.reason = '',
    this.passwordGate,
    this.catalogVersion = '',
  });

  factory OpsStatus.fromJson(Map<String, dynamic> res) {
    final d = opsData(res);
    final pg = d['password_gate'];
    return OpsStatus(
      available: _bool(d['available']),
      flagEnabled: _bool(d['flag_enabled']),
      reason: _str(d['reason']),
      passwordGate: pg is Map ? OpsPasswordGate.fromJson(_map(pg)) : null,
      catalogVersion: _str(d['catalog_version']),
    );
  }

  /// The server cannot serve the assistant to this app (old build, unbound
  /// credential): the menu entry stays hidden.
  const OpsStatus.notSupported()
      : available = false,
        flagEnabled = false,
        reason = 'not_supported',
        passwordGate = null,
        catalogVersion = '';

  final bool available;
  final bool flagEnabled;
  final String reason;
  final OpsPasswordGate? passwordGate;
  final String catalogVersion;

  OpsUnavailableReason? get unavailableReason {
    if (available) return null;
    if (reason == 'not_supported') return OpsUnavailableReason.notSupported;
    if (reason == 'disabled' || !flagEnabled) {
      return OpsUnavailableReason.disabled;
    }
    return OpsUnavailableReason.weakAdminPasswords;
  }
}

// ─────────────────────────── level-4 suggestions ────────────────────────────

/// One suggestion («اقتراح») the admin can start a conversation from — one
/// row per record of a detector event, exactly like the web's
/// `/ops-assistant/events` (conversation.event_records + _event_text).
class OpsSuggestion {
  const OpsSuggestion({
    required this.eventType,
    required this.index,
    required this.title,
    required this.text,
  });

  final String eventType;
  final int index;
  final String title;
  final String text;
}

/// `GET /api/v1/ops/events` items (`{type, data}`) → suggestion rows.
List<OpsSuggestion> opsSuggestionsFromEvents(Map<String, dynamic> res) {
  final out = <OpsSuggestion>[];
  for (final ev in _maps(opsData(res)['items'])) {
    final type = _str(ev['type']);
    final data = _map(ev['data']);
    switch (type) {
      case 'expiring_tomorrow':
        out.add(
          OpsSuggestion(
            eventType: type,
            index: 0,
            title: 'اشتراكات تنتهي غدًا',
            text: '${_int(data['count'])} مشترك ينتهي اشتراكه يوم '
                '${_str(data['date_local'])}.',
          ),
        );
      case 'repeated_rejects':
        final nas = _maps(data['nas']);
        for (var i = 0; i < nas.length; i++) {
          final name = _str(nas[i]['nas']);
          out.add(
            OpsSuggestion(
              eventType: type,
              index: i,
              title: 'رفض دخول متكرّر',
              text: '${_str(nas[i]['rejects'])} محاولة مرفوضة على '
                  '«${name.isEmpty ? '-' : name}» خلال '
                  '${_str(data['window_minutes'])} دقيقة.',
            ),
          );
        }
      case 'low_card_stock':
        final plans = _maps(data['plans']);
        for (var i = 0; i < plans.length; i++) {
          out.add(
            OpsSuggestion(
              eventType: type,
              index: i,
              title: 'مخزون كروت منخفض',
              text: 'الباقة «${_str(plans[i]['plan_name'])}»: '
                  '${_str(plans[i]['unused_cards'])} كرت غير مستخدم '
                  '(الحدّ ${_str(data['threshold'])}).',
            ),
          );
        }
      case 'plan_without_offers':
        final plans = _maps(data['plans']);
        for (var i = 0; i < plans.length; i++) {
          out.add(
            OpsSuggestion(
              eventType: type,
              index: i,
              title: 'باقة بلا عرض بيع',
              text: 'الباقة «${_str(plans[i]['plan_name'])}» لا يبيعها أيّ '
                  'عرض فعّال.',
            ),
          );
        }
      default:
        break;
    }
  }
  return out;
}

// ─────────────────────────── replies ────────────────────────────

enum OpsReplyType { assistant, choices, result, proposal, error }

OpsReplyType _replyType(String t) => switch (t) {
      'choices' => OpsReplyType.choices,
      'result' => OpsReplyType.result,
      'proposal' => OpsReplyType.proposal,
      'error' => OpsReplyType.error,
      _ => OpsReplyType.assistant,
    };

/// One step of the executor's confirmation card (`proposal.steps[]`). Built
/// by the executor from VALIDATED values — never from the model's text.
class OpsStep {
  const OpsStep({
    required this.n,
    required this.action,
    this.titleAr = '',
    this.danger = 'L2',
    this.values = const {},
    this.display = const {},
    this.names = const {},
    this.pendingRefs = const {},
    this.password,
    this.executable = true,
  });

  factory OpsStep.fromJson(Map<String, dynamic> j) => OpsStep(
        n: _int(j['n'], 1),
        action: _str(j['action']),
        titleAr: _str(j['title_ar']),
        danger: _str(j['danger']).isEmpty ? 'L2' : _str(j['danger']),
        values: _map(j['values']),
        display: _map(j['display']),
        names: _map(j['names']).map((k, v) => MapEntry(k, _str(v))),
        pendingRefs:
            _map(j['pending_refs']).map((k, v) => MapEntry(k, _str(v))),
        password: j['password'] == null ? null : _str(j['password']),
        executable: j['executable'] != false,
      );

  final int n;
  final String action;
  final String titleAr;

  /// `L3` = immediate effect on the subscriber (disconnect / live change).
  final String danger;
  final Map<String, dynamic> values;
  final Map<String, dynamic> display;

  /// Plan / offer NAMES next to their ids (display only).
  final Map<String, String> names;

  /// field → `$stepN.field` (filled from an earlier step's result).
  final Map<String, String> pendingRefs;

  /// `generated_and_shown_once` when the server generates a password.
  final String? password;
  final bool executable;

  String get title => titleAr.isEmpty ? action : titleAr;
}

class OpsProposal {
  const OpsProposal({
    required this.proposalId,
    required this.proposalHash,
    this.level = 2,
    this.steps = const [],
    this.notExecutableSteps = const [],
  });

  factory OpsProposal.fromJson(Map<String, dynamic> j) => OpsProposal(
        proposalId: _str(j['proposal_id']),
        proposalHash: _str(j['proposal_hash']),
        level: _int(j['level'], 2),
        steps: [for (final s in _maps(j['steps'])) OpsStep.fromJson(s)],
        notExecutableSteps: j['not_executable_steps'] is List
            ? [for (final n in j['not_executable_steps'] as List) _int(n)]
            : const [],
      );

  final String proposalId;
  final String proposalHash;
  final int level;
  final List<OpsStep> steps;
  final List<int> notExecutableSteps;

  bool get isPlan => steps.length > 1;
}

/// One item of `replies[]` (conversation.run_model).
class OpsReply {
  const OpsReply({
    required this.type,
    this.action = '',
    this.text = '',
    this.code = '',
    this.emptyFlag = false,
    this.emptyText = '',
    this.source = '',
    this.items = const [],
    this.truncated = false,
    this.data,
    this.error = '',
    this.proposal,
  });

  factory OpsReply.fromJson(Map<String, dynamic> j) {
    final empty = j['empty'];
    final p = j['proposal'];
    final data = j['data'];
    return OpsReply(
      type: _replyType(_str(j['type'])),
      action: _str(j['action']),
      text: _str(j['text']),
      code: _str(j['code']),
      // `empty` is `true` on an assistant reply (repeated empty lookup) and
      // the translated empty-state LINE on a choices reply.
      emptyFlag: empty == true || (empty is String && empty.isNotEmpty),
      emptyText: empty is String ? empty : '',
      source: _str(j['source']),
      items: _maps(j['items']),
      truncated: _bool(j['truncated']),
      data: data is Map ? _map(data) : null,
      error: _str(j['error']),
      proposal: p is Map ? OpsProposal.fromJson(_map(p)) : null,
    );
  }

  final OpsReplyType type;
  final String action;

  /// The model's `message` (or `summary_ar` for a round-1/2 model). Plain text.
  final String text;
  final String code;
  final bool emptyFlag;
  final String emptyText;
  final String source;
  final List<Map<String, dynamic>> items;
  final bool truncated;
  final Map<String, dynamic>? data;

  /// INFO error code: not_found | out_of_scope | missing_permission | unavailable.
  final String error;
  final OpsProposal? proposal;
}

/// A model turn: `{conversation_id, replies[]}`.
class OpsTurn {
  const OpsTurn({required this.conversationId, required this.replies});

  factory OpsTurn.fromJson(Map<String, dynamic> res) {
    final d = opsData(res);
    return OpsTurn(
      conversationId: _str(d['conversation_id']),
      replies: [for (final r in _maps(d['replies'])) OpsReply.fromJson(r)],
    );
  }

  final String conversationId;
  final List<OpsReply> replies;
}

// ─────────────────────────── execution report ────────────────────────────

class OpsReportStep {
  const OpsReportStep({
    required this.n,
    required this.action,
    required this.status,
    this.errorMessage = '',
  });

  factory OpsReportStep.fromJson(Map<String, dynamic> j) {
    final err = j['error'];
    var msg = '';
    if (err is Map) {
      final m = _map(err);
      msg =
          _str(m['message']).isNotEmpty ? _str(m['message']) : _str(m['code']);
    } else if (err is String) {
      msg = err;
    }
    return OpsReportStep(
      n: _int(j['n'], 1),
      action: _str(j['action']),
      status: _str(j['status']),
      errorMessage: msg,
    );
  }

  final int n;
  final String action;

  /// done | failed | not_run
  final String status;
  final String errorMessage;
}

class OpsReport {
  const OpsReport({
    required this.status,
    this.replayed = false,
    this.steps = const [],
  });

  factory OpsReport.fromJson(Map<String, dynamic> j) => OpsReport(
        status: _str(j['status']),
        replayed: _bool(j['replayed']),
        steps: [for (final s in _maps(j['steps'])) OpsReportStep.fromJson(s)],
      );

  /// executed | failed | partial
  final String status;
  final bool replayed;
  final List<OpsReportStep> steps;
}

/// A generated subscriber password, shown ONCE (never stored by the app).
class OpsSecret {
  const OpsSecret({required this.username, required this.password});
  final String username;
  final String password;
}

/// The confirm response: the report + the one-time secrets (if any).
class OpsConfirmOutcome {
  const OpsConfirmOutcome({required this.report, this.secrets = const []});

  factory OpsConfirmOutcome.fromJson(Map<String, dynamic> res) {
    final d = opsData(res);
    final so = _map(d['show_once']);
    return OpsConfirmOutcome(
      report: OpsReport.fromJson(_map(d['report'])),
      secrets: [
        for (final s in _maps(so['subscriber_passwords']))
          OpsSecret(
            username: _str(s['username']),
            password: _str(s['password']),
          ),
      ],
    );
  }

  final OpsReport report;
  final List<OpsSecret> secrets;
}
