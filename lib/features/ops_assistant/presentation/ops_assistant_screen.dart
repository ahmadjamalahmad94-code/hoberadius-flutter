import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/ops_assistant_providers.dart';
import '../data/ops_assistant_repository.dart';
import '../domain/ops_labels.dart';
import '../domain/ops_models.dart';
import 'widgets/ops_chat_widgets.dart';

/// «مساعد العمليّات» (تجريبيّ) — the app's twin of the web page
/// /admin/radius/ops-assistant: the admin writes in their own words, the
/// assistant prepares the action, and NOTHING executes before «تأكيد».
class OpsAssistantScreen extends ConsumerWidget {
  const OpsAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(opsStatusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: OpsTexts.title,
          subtitle: OpsTexts.subtitle,
          inlineActions: true,
          actions: [
            const StatusPill(
              key: ValueKey('ops-experimental'),
              text: OpsTexts.experimental,
              tone: PillTone.orange,
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () {
                ref.invalidate(opsStatusProvider);
                ref.invalidate(opsSuggestionsProvider);
              },
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        status.when(
          skipLoadingOnRefresh: true,
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.s32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => HubErrorState(
            title: OpsTexts.statusError,
            subtitle: visibleErrorMessage(e),
            onRetry: () => ref.invalidate(opsStatusProvider),
          ),
          data: (s) => s.available
              ? const _OpsChatLayout()
              : OpsUnavailablePanel(status: s),
        ),
      ],
    );
  }
}

/// Why the assistant is not available (web parity: flag off / counts of
/// admins with default or temporary passwords / older server).
class OpsUnavailablePanel extends ConsumerWidget {
  const OpsUnavailablePanel({super.key, required this.status});
  final OpsStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(permissionsProvider.select((p) => p.isOwnerLike));
    final reason = status.unavailableReason;
    final pg = status.passwordGate ?? const OpsPasswordGate();
    const body = TextStyle(fontSize: 14, height: 1.8);
    return AppCard(
      key: const ValueKey('ops-unavailable'),
      title: OpsTexts.unavailableTitle,
      icon: Icons.error_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: switch (reason) {
          OpsUnavailableReason.weakAdminPasswords => [
              const Text(OpsTexts.weakPasswords, style: body),
              const SizedBox(height: AppTokens.s8),
              Text(
                '• ${OpsTexts.defaultPasswordAdmins} '
                '${pg.defaultPasswordCount}',
                style: body,
              ),
              Text(
                '• ${OpsTexts.mustChangeAdmins} ${pg.mustChangeCount}',
                style: body,
              ),
              const OpsHint(OpsTexts.weakPasswordsHint),
            ],
          OpsUnavailableReason.notSupported => [
              const Text(OpsTexts.notSupported, style: body),
            ],
          _ => [
              const Text(OpsTexts.disabled, style: body),
              OpsHint(
                owner ? OpsTexts.disabledOwnerHint : OpsTexts.disabledAskOwner,
              ),
            ],
        },
      ),
    );
  }
}

class _OpsChatLayout extends StatelessWidget {
  const _OpsChatLayout();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 980) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OpsChatPanel(),
              SizedBox(height: AppTokens.s16),
              OpsSuggestionsPanel(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: OpsChatPanel()),
            SizedBox(width: 18),
            SizedBox(width: 320, child: OpsSuggestionsPanel()),
          ],
        );
      },
    );
  }
}

/// The conversation + the composer.
class OpsChatPanel extends ConsumerStatefulWidget {
  const OpsChatPanel({super.key});

  @override
  ConsumerState<OpsChatPanel> createState() => _OpsChatPanelState();
}

class _OpsChatPanelState extends ConsumerState<OpsChatPanel> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _endKey = GlobalKey();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Keep the newest message and the composer in view (the shell scrolls).
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _endKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final ctrl = ref.read(opsChatControllerProvider.notifier);
    if (ref.read(opsChatControllerProvider).busy) return;
    final text = _input.text;
    if (text.trim().isNotEmpty) _input.clear();
    await ctrl.send(text);
    if (mounted) _focus.requestFocus();
  }

  Future<void> _confirm(int entryId) async {
    final secrets =
        await ref.read(opsChatControllerProvider.notifier).confirm(entryId);
    if (!mounted || secrets.isEmpty) return;
    await showOpsSecretsDialog(context, secrets);
  }

  Widget _entry(OpsEntry e, bool busy) => switch (e) {
        OpsUserEntry(:final text) =>
          OpsBubble(text: text, kind: OpsBubbleKind.user),
        OpsBotEntry(:final text, :final empty) => OpsBubble(
            text: text,
            kind: empty ? OpsBubbleKind.empty : OpsBubbleKind.bot,
          ),
        OpsErrorEntry(:final text) =>
          OpsBubble(text: text, kind: OpsBubbleKind.error),
        OpsChoicesEntry(:final reply) => OpsChoicesCard(reply: reply),
        OpsInfoEntry(:final reply) => OpsInfoCard(reply: reply),
        OpsProposalEntry() => OpsProposalCard(
            entry: e,
            busy: busy,
            onConfirm: () => _confirm(e.id),
            onCancel: () => ref
                .read(opsChatControllerProvider.notifier)
                .cancelProposal(e.id),
          ),
        OpsReportEntry() => OpsReportCard(entry: e),
      };

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(opsChatControllerProvider);
    ref.listen<OpsChatState>(opsChatControllerProvider, (prev, next) {
      if (prev?.entries.length != next.entries.length ||
          prev?.busy != next.busy) {
        _scrollToEnd();
      }
    });
    return AppCard(
      title: OpsTexts.chatTitle,
      icon: Icons.forum_outlined,
      padding: const EdgeInsets.all(AppTokens.s16),
      actions: const [
        Text(
          OpsTexts.chatMeta,
          style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OpsBubble(text: OpsTexts.greeting, kind: OpsBubbleKind.bot),
          for (final e in chat.entries) ...[
            const SizedBox(height: 10),
            KeyedSubtree(
              key: ValueKey('ops-entry-${e.id}'),
              child: _entry(e, chat.busy),
            ),
          ],
          if (chat.busy) ...[
            const SizedBox(height: 10),
            const OpsBubble(text: OpsTexts.thinking, kind: OpsBubbleKind.wait),
          ],
          const SizedBox(height: AppTokens.s12),
          const Divider(height: 1),
          const SizedBox(height: AppTokens.s12),
          Row(
            key: _endKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CallbackShortcuts(
                  // Enter sends, Shift+Enter is a new line (web parity).
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter): _send,
                    const SingleActivator(LogicalKeyboardKey.numpadEnter):
                        _send,
                  },
                  child: TextField(
                    key: const ValueKey('ops-input'),
                    controller: _input,
                    focusNode: _focus,
                    enabled: !chat.busy,
                    minLines: 2,
                    maxLines: 6,
                    maxLength: 2000,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: OpsTexts.inputHint,
                      labelText: OpsTexts.inputLabel,
                      counterText: '',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('ops-send'),
                      onPressed: chat.busy ? null : _send,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text(OpsTexts.send),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      key: const ValueKey('ops-new'),
                      onPressed: chat.busy
                          ? null
                          : () {
                              ref
                                  .read(opsChatControllerProvider.notifier)
                                  .newConversation();
                              _focus.requestFocus();
                            },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(OpsTexts.newChat),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const OpsHint(OpsTexts.noPasswordsHint),
        ],
      ),
    );
  }
}

/// Level-4 suggestions («اقتراحات») → «ابدأ محادثة».
class OpsSuggestionsPanel extends ConsumerWidget {
  const OpsSuggestionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(opsSuggestionsProvider);
    final busy = ref.watch(opsChatControllerProvider.select((s) => s.busy));
    return AppCard(
      title: OpsTexts.eventsTitle,
      icon: Icons.lightbulb_outline,
      padding: const EdgeInsets.all(AppTokens.s16),
      actions: const [
        Text(
          OpsTexts.eventsMeta,
          style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
        ),
      ],
      child: items.when(
        loading: () => const OpsHint('جارٍ التحميل…'),
        error: (e, _) => OpsHint(
          e is OpsError && e.message.isNotEmpty
              ? e.message
              : OpsTexts.eventsError,
        ),
        data: (list) => list.isEmpty
            ? const OpsHint(OpsTexts.eventsEmpty)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in list)
                    _SuggestionTile(
                      suggestion: s,
                      enabled: !busy,
                      onStart: () => ref
                          .read(opsChatControllerProvider.notifier)
                          .startFromSuggestion(s),
                    ),
                ],
              ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.enabled,
    required this.onStart,
  });

  final OpsSuggestion suggestion;
  final bool enabled;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            suggestion.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: AppTokens.slate500,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              key: ValueKey(
                'ops-start-${suggestion.eventType}-${suggestion.index}',
              ),
              onPressed: enabled ? onStart : null,
              child: const Text(OpsTexts.start),
            ),
          ),
        ],
      ),
    );
  }
}
