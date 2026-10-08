import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/idempotency.dart';
import '../../../core/auth/auth_controller.dart';
import '../data/ops_assistant_repository.dart';
import '../domain/ops_labels.dart';
import '../domain/ops_models.dart';

/// `GET /api/v1/ops/status` for the signed-in admin. Re-read after a login
/// or server switch. An older server resolves to [OpsStatus.notSupported].
final opsStatusProvider = FutureProvider<OpsStatus>((ref) async {
  final adminId = ref.watch(authControllerProvider.select((s) => s.admin?.id));
  final authed =
      ref.watch(authControllerProvider.select((s) => s.isAuthenticated));
  if (!authed || adminId == null) return const OpsStatus.notSupported();
  return ref.watch(opsAssistantGatewayProvider).status();
});

/// Menu entry «مساعد العمليّات»: only when the server says the assistant is
/// available (flag ON + password gate open) — web `ops_assistant_nav_visible`.
/// Fails CLOSED: loading / error / old server → hidden.
final opsAssistantNavVisibleProvider = Provider<bool>((ref) {
  return ref.watch(opsStatusProvider).valueOrNull?.available ?? false;
});

/// Level-4 suggestions («اقتراحات») for this admin.
final opsSuggestionsProvider =
    FutureProvider.autoDispose<List<OpsSuggestion>>((ref) {
  return ref.watch(opsAssistantGatewayProvider).suggestions();
});

// ─────────────────────────── chat state ────────────────────────────

/// One row of the chat log.
sealed class OpsEntry {
  OpsEntry(this.id, {DateTime? at}) : at = at ?? DateTime.now();
  final int id;

  /// When the row entered the transcript — the time shown under the bubble
  /// (local device clock; the panel time zone is a server-side concern).
  final DateTime at;
}

class OpsUserEntry extends OpsEntry {
  OpsUserEntry(super.id, this.text, {super.at});
  final String text;
}

/// An assistant bubble. [empty] = an empty-state line (dashed bubble).
class OpsBotEntry extends OpsEntry {
  OpsBotEntry(super.id, this.text, {this.empty = false, super.at});
  final String text;
  final bool empty;
}

class OpsErrorEntry extends OpsEntry {
  OpsErrorEntry(super.id, this.text, {super.at});
  final String text;
}

/// A CHOICES list from the system.
class OpsChoicesEntry extends OpsEntry {
  OpsChoicesEntry(super.id, this.reply, {super.at});
  final OpsReply reply;
}

/// A read-only INFO answer (RESULT card).
class OpsInfoEntry extends OpsEntry {
  OpsInfoEntry(super.id, this.reply, {super.at});
  final OpsReply reply;
}

enum OpsProposalState { pending, confirming, confirmed, cancelled }

/// The executor's confirmation card.
class OpsProposalEntry extends OpsEntry {
  OpsProposalEntry(
    super.id,
    this.proposal, {
    this.state = OpsProposalState.pending,
    required this.idempotencyKey,
    super.at,
  });

  final OpsProposal proposal;
  final OpsProposalState state;

  /// One key per proposal: a retry after a lost response reuses it.
  final String idempotencyKey;

  OpsProposalEntry withState(OpsProposalState s) => OpsProposalEntry(
        id,
        proposal,
        state: s,
        idempotencyKey: idempotencyKey,
        at: at,
      );
}

/// The execution report (per step done / failed / not run).
class OpsReportEntry extends OpsEntry {
  OpsReportEntry(super.id, this.report, this.titles, {super.at});
  final OpsReport report;

  /// action → title_ar (from the confirmation cards).
  final Map<String, String> titles;
}

class OpsChatState {
  const OpsChatState({
    this.entries = const [],
    this.conversationId,
    this.busy = false,
    this.taskChosen = false,
  });

  final List<OpsEntry> entries;
  final String? conversationId;

  /// A request is in flight: the typing indicator shows, input and buttons
  /// are disabled.
  final bool busy;

  /// A suggested task was tapped in this conversation — the quick-task chip
  /// row above the composer retires (the «+» sheet stays available) and
  /// comes back with the next [OpsChatController.newConversation].
  final bool taskChosen;

  OpsChatState copyWith({
    List<OpsEntry>? entries,
    String? conversationId,
    bool clearConversation = false,
    bool? busy,
    bool? taskChosen,
  }) =>
      OpsChatState(
        entries: entries ?? this.entries,
        conversationId:
            clearConversation ? null : (conversationId ?? this.conversationId),
        busy: busy ?? this.busy,
        taskChosen: taskChosen ?? this.taskChosen,
      );
}

/// The chat: the web's ops_assistant.js behaviour. Nothing executes without
/// [confirm] (the admin's tap on «تأكيد»). One-time passwords are RETURNED by
/// [confirm] for the dialog and never kept in this state.
class OpsChatController extends StateNotifier<OpsChatState> {
  OpsChatController(this._gateway, {this.onUnavailable})
      : super(const OpsChatState());

  final OpsAssistantGateway _gateway;

  /// Called when the server says the assistant became unavailable.
  final void Function()? onUnavailable;

  int _seq = 0;
  final Map<String, String> _titles = {};

  int _id() => ++_seq;

  void _add(Iterable<OpsEntry> items) {
    if (!mounted) return;
    state = state.copyWith(entries: [...state.entries, ...items]);
  }

  void _fail(Object error) {
    final e = mapOpsError(error);
    if (!mounted) return;
    if (e.conversationLost) state = state.copyWith(clearConversation: true);
    if (e.unavailable) onUnavailable?.call();
    _add([OpsErrorEntry(_id(), e.message)]);
  }

  /// The web's `render(replies)`.
  List<OpsEntry> _render(List<OpsReply> replies) {
    final out = <OpsEntry>[];
    for (final r in replies) {
      switch (r.type) {
        case OpsReplyType.error:
          out.add(
            OpsErrorEntry(
              _id(),
              r.text.isEmpty ? OpsTexts.network : r.text,
            ),
          );
        case OpsReplyType.choices:
          if (r.text.isNotEmpty) out.add(OpsBotEntry(_id(), r.text));
          if (r.items.isEmpty) {
            out.add(
              OpsBotEntry(
                _id(),
                r.emptyText.isEmpty ? OpsTexts.choicesEmpty : r.emptyText,
                empty: true,
              ),
            );
          } else {
            out.add(OpsChoicesEntry(_id(), r));
          }
        case OpsReplyType.result:
          if (r.text.isNotEmpty) out.add(OpsBotEntry(_id(), r.text));
          out.add(OpsInfoEntry(_id(), r));
        case OpsReplyType.proposal:
        case OpsReplyType.assistant:
          if (r.emptyFlag) {
            out.add(
              OpsBotEntry(
                _id(),
                r.text.isEmpty ? OpsTexts.choicesEmpty : r.text,
                empty: true,
              ),
            );
            continue;
          }
          if (r.text.isNotEmpty) out.add(OpsBotEntry(_id(), r.text));
          final p = r.proposal;
          if (r.type == OpsReplyType.proposal && p != null) {
            for (final st in p.steps) {
              if (st.titleAr.isNotEmpty) _titles[st.action] = st.titleAr;
            }
            out.add(
              OpsProposalEntry(
                _id(),
                p,
                idempotencyKey: newIdempotencyKey(),
              ),
            );
          }
      }
    }
    return out;
  }

  /// Sends the admin's message. Returns false when nothing was sent.
  Future<bool> send(String raw) async {
    final text = raw.trim();
    if (state.busy) return false;
    if (text.isEmpty) {
      _add([OpsErrorEntry(_id(), OpsTexts.empty)]);
      return false;
    }
    state = state.copyWith(
      busy: true,
      entries: [...state.entries, OpsUserEntry(_id(), text)],
    );
    try {
      final turn = await _gateway.sendMessage(
        conversationId: state.conversationId,
        text: text,
      );
      if (!mounted) return true;
      state = state.copyWith(
        conversationId:
            turn.conversationId.isEmpty ? null : turn.conversationId,
      );
      _add(_render(turn.replies));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
    return true;
  }

  /// A suggested task («المهام المقترحة») was tapped: its sentence goes in
  /// exactly as if the admin had typed it — the model still asks for what is
  /// missing, and an executable action still ends at a confirmation card.
  Future<void> sendTask(String prompt) async {
    if (state.busy) return;
    state = state.copyWith(taskChosen: true);
    await send(prompt);
  }

  /// «محادثة جديدة».
  void newConversation() {
    if (state.busy) return;
    _titles.clear();
    state = const OpsChatState();
  }

  /// A suggestion → a new conversation + the model's first turn.
  Future<void> startFromSuggestion(OpsSuggestion s) async {
    if (state.busy) return;
    _titles.clear();
    state = OpsChatState(
      busy: true,
      taskChosen: true,
      entries: [
        OpsUserEntry(
          _id(),
          '${OpsTexts.eventStarted} ${s.title}: ${s.text}',
        ),
      ],
    );
    try {
      final turn = await _gateway.startFromSuggestion(s);
      if (!mounted) return;
      state = state.copyWith(
        conversationId:
            turn.conversationId.isEmpty ? null : turn.conversationId,
      );
      _add(_render(turn.replies));
    } catch (e) {
      _fail(e);
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }

  OpsProposalEntry? _proposal(int entryId) {
    for (final e in state.entries) {
      if (e is OpsProposalEntry && e.id == entryId) return e;
    }
    return null;
  }

  void _replace(OpsEntry updated) {
    state = state.copyWith(
      entries: [
        for (final e in state.entries) e.id == updated.id ? updated : e,
      ],
    );
  }

  /// «تأكيد» — the ONLY path that executes. Returns the one-time secrets to
  /// show (the caller opens the dialog; nothing is stored here).
  Future<List<OpsSecret>> confirm(int entryId) async {
    final entry = _proposal(entryId);
    final cid = state.conversationId;
    if (state.busy ||
        entry == null ||
        entry.state != OpsProposalState.pending ||
        cid == null) {
      return const [];
    }
    _replace(entry.withState(OpsProposalState.confirming));
    state = state.copyWith(busy: true);
    try {
      final out = await _gateway.confirm(
        conversationId: cid,
        proposal: entry.proposal,
        idempotencyKey: entry.idempotencyKey,
      );
      if (!mounted) return out.secrets;
      _replace(entry.withState(OpsProposalState.confirmed));
      _add([OpsReportEntry(_id(), out.report, Map.of(_titles))]);
      return out.secrets;
    } catch (e) {
      final err = mapOpsError(e);
      // A lost response / busy server: the card stays confirmable and a
      // retry carries the SAME Idempotency-Key (the executor replays, it
      // never executes twice). A lost conversation cannot be confirmed.
      if (mounted) {
        _replace(
          entry.withState(
            err.conversationLost || err.unavailable
                ? OpsProposalState.cancelled
                : OpsProposalState.pending,
          ),
        );
      }
      _fail(err);
      return const [];
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }

  /// «إلغاء» — records the cancel in the transcript; nothing executes.
  Future<void> cancelProposal(int entryId) async {
    final entry = _proposal(entryId);
    if (state.busy ||
        entry == null ||
        entry.state != OpsProposalState.pending) {
      return;
    }
    _replace(entry.withState(OpsProposalState.cancelled));
    final cid = state.conversationId;
    if (cid != null) {
      try {
        await _gateway.cancel(cid);
      } catch (_) {/* the card is cancelled locally either way (web) */}
    }
    _add([OpsBotEntry(_id(), OpsTexts.cancelled)]);
  }
}

/// The chat survives navigating away (the operator checks a page and
/// comes back) and resets on a login / server switch.
final opsChatControllerProvider =
    StateNotifierProvider<OpsChatController, OpsChatState>((ref) {
  ref.watch(authControllerProvider.select((s) => s.admin?.id));
  return OpsChatController(
    ref.watch(opsAssistantGatewayProvider),
    onUnavailable: () => ref.invalidate(opsStatusProvider),
  );
});
