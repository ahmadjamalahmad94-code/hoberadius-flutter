import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../notifications/application/notifications_providers.dart';
import '../application/ops_assistant_providers.dart';
import '../domain/ops_labels.dart';
import '../domain/ops_models.dart';
import '../domain/ops_task_catalog.dart';
import 'widgets/ops_chat_shell.dart';
import 'widgets/ops_chat_widgets.dart';
import 'widgets/ops_task_sheet.dart';

/// «المساعد الذكي» — the app's twin of the web page
/// /admin/radius/ops-assistant: the admin writes in their own words, the
/// assistant prepares the action, and NOTHING executes before «تأكيد».
class OpsAssistantScreen extends ConsumerWidget {
  const OpsAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(opsStatusProvider);
    return status.when(
      skipLoadingOnRefresh: true,
      loading: () => const _Gate(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.s32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => _Gate(
        child: HubErrorState(
          title: OpsTexts.statusError,
          subtitle: visibleErrorMessage(e),
          onRetry: () => ref.invalidate(opsStatusProvider),
        ),
      ),
      data: (s) => s.available
          ? const OpsChatSurface()
          : _Gate(child: OpsUnavailablePanel(status: s)),
    );
  }
}

/// The header + «تجريبيّ» badge shown while the assistant is NOT usable
/// (flag off / password gate / older server / status error).
class _Gate extends ConsumerWidget {
  const _Gate({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child,
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

/// The whole chat screen of the owner's mockup: header, transcript, the
/// suggested-task chips and the composer.
class OpsChatSurface extends ConsumerStatefulWidget {
  const OpsChatSurface({super.key});

  @override
  ConsumerState<OpsChatSurface> createState() => _OpsChatSurfaceState();
}

class _OpsChatSurfaceState extends ConsumerState<OpsChatSurface> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  OpsChatController get _ctrl =>
      ref.read(opsChatControllerProvider.notifier);

  Future<void> _send() async {
    if (ref.read(opsChatControllerProvider).busy) return;
    final text = _input.text;
    if (text.trim().isNotEmpty) _input.clear();
    await _ctrl.send(text);
    if (mounted) _focus.requestFocus();
  }

  Future<void> _confirm(int entryId) async {
    final secrets = await _ctrl.confirm(entryId);
    if (!mounted || secrets.isEmpty) return;
    await showOpsSecretsDialog(context, secrets);
  }

  /// The round «+»: the full task list. Choosing a row closes the sheet and
  /// sends the sentence straight away (the owner's requirement).
  Future<void> _openTasks() async {
    if (ref.read(opsChatControllerProvider).busy) return;
    final pick = await showOpsTaskSheet(context);
    if (!mounted || pick == null) return;
    switch (pick) {
      case OpsTaskPick(:final task):
        await _ctrl.sendTask(task.prompt);
      case OpsSuggestionPick(:final suggestion):
        await _ctrl.startFromSuggestion(suggestion);
    }
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
            onCancel: () => _ctrl.cancelProposal(e.id),
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

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OpsChatHeader(),
        const SizedBox(height: AppTokens.s8),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            key: const ValueKey('ops-transcript'),
            controller: _scroll,
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
            children: [
              OpsMessageRow(
                bot: true,
                child: OpsGreetingBubble(
                  onExample: (t) {
                    _input.text = t;
                    _focus.requestFocus();
                  },
                ),
              ),
              for (final e in chat.entries) ...[
                const SizedBox(height: 10),
                KeyedSubtree(
                  key: ValueKey('ops-entry-${e.id}'),
                  child: OpsMessageRow(
                    bot: e is! OpsUserEntry,
                    at: e.at,
                    child: _entry(e, chat.busy),
                  ),
                ),
              ],
              if (chat.busy) ...[
                const SizedBox(height: 10),
                const OpsMessageRow(
                  key: ValueKey('ops-typing'),
                  bot: true,
                  child: OpsTypingIndicator(),
                ),
              ],
            ],
          ),
        ),
        // The chips retire once a task has been chosen; «+» stays.
        if (!chat.taskChosen)
          OpsQuickTaskRow(
            enabled: !chat.busy,
            onTask: (t) => _ctrl.sendTask(t.prompt),
            onMore: _openTasks,
          ),
        OpsComposer(
          controller: _input,
          focusNode: _focus,
          busy: chat.busy,
          onSend: _send,
          onPlus: _openTasks,
        ),
        const OpsHint(OpsTexts.noPasswordsShort),
      ],
    );

    // The app shell puts every page inside a SingleChildScrollView, so the
    // surface claims a viewport-sized box of its own: the transcript scrolls
    // inside it and the composer stays docked at the bottom.
    return LayoutBuilder(
      builder: (context, c) {
        if (c.hasBoundedHeight) return body;
        final h = (MediaQuery.sizeOf(context).height - 190).clamp(420.0, 900.0);
        return SizedBox(height: h, child: body);
      },
    );
  }
}

/// «المساعد الذكي» + the bell and the history button (the mockup header).
class OpsChatHeader extends ConsumerWidget {
  const OpsChatHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 19,
                    color: AppTokens.brand,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      OpsTexts.smartTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTokens.sidebarBg,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3),
              Text(
                OpsTexts.smartSubtitle,
                style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        _HeaderButton(
          buttonKey: const ValueKey('ops-history'),
          icon: Icons.history,
          tooltip: OpsTexts.historyTitle,
          onTap: () => showOpsHistorySheet(context, ref),
        ),
        const SizedBox(width: 6),
        _HeaderButton(
          buttonKey: const ValueKey('ops-bell'),
          icon: Icons.notifications_outlined,
          tooltip: OpsTexts.notifications,
          badge: unread,
          onTap: () => context.goNamed('notifications'),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tooltip(
          message: tooltip,
          child: InkWell(
            key: buttonKey,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTokens.card,
                borderRadius: BorderRadius.circular(AppTokens.r12),
                border: Border.all(color: AppTokens.borderStrong),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 21, color: AppTokens.sidebarBg),
            ),
          ),
        ),
        if (badge > 0)
          PositionedDirectional(
            top: -5,
            end: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppTokens.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppTokens.card, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                badge > 99 ? '+99' : '$badge',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The horizontally scrollable shortcut row above the composer.
class OpsQuickTaskRow extends StatelessWidget {
  const OpsQuickTaskRow({
    super.key,
    required this.enabled,
    required this.onTask,
    required this.onMore,
  });

  final bool enabled;
  final void Function(OpsTask task) onTask;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('ops-quick-tasks'),
      padding: const EdgeInsets.only(bottom: AppTokens.s8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in kOpsQuickTasks) ...[
              _QuickChip(
                chipKey: ValueKey('ops-chip-${t.id}'),
                icon: t.icon,
                label: t.label,
                onTap: enabled ? () => onTask(t) : null,
              ),
              const SizedBox(width: 6),
            ],
            _QuickChip(
              chipKey: const ValueKey('ops-chip-more'),
              icon: Icons.more_horiz,
              label: OpsTexts.tasksMore,
              onTap: enabled ? onMore : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.chipKey,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Key chipKey;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: chipKey,
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTokens.borderStrong),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTokens.brand),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «+» · the rounded field · the mic · the circular send button.
class OpsComposer extends StatelessWidget {
  const OpsComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.onSend,
    required this.onPlus,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final Future<void> Function() onSend;
  final Future<void> Function() onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The send button sits on the start (right) edge, as in the mockup.
        SizedBox(
          width: 46,
          height: 46,
          child: FilledButton(
            key: const ValueKey('ops-send'),
            onPressed: busy ? null : () => onSend(),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              backgroundColor: AppTokens.brand,
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Transform.flip(
                    flipX: true,
                    child: const Icon(Icons.send, size: 19),
                  ),
          ),
        ),
        const SizedBox(width: 4),
        // Voice input: the app has NO speech package (see pubspec) — the
        // button is rendered disabled rather than faked.
        const Tooltip(
          message: OpsTexts.micUnavailable,
          child: IconButton(
            key: ValueKey('ops-mic'),
            onPressed: null,
            icon: Icon(Icons.mic_none, size: 22),
          ),
        ),
        Expanded(
          child: CallbackShortcuts(
            // Enter sends, Shift+Enter is a new line (web parity).
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): onSend,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): onSend,
            },
            child: TextField(
              key: const ValueKey('ops-input'),
              controller: controller,
              focusNode: focusNode,
              enabled: !busy,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: OpsTexts.composerHint,
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: AppTokens.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTokens.borderStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTokens.borderStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppTokens.brand),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        SizedBox(
          width: 46,
          height: 46,
          child: FilledButton(
            key: const ValueKey('ops-tasks-open'),
            onPressed: busy ? null : () => onPlus(),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              backgroundColor: AppTokens.brand,
            ),
            child: const Icon(Icons.add, size: 24),
          ),
        ),
      ],
    );
  }
}

/// «المحادثات السابقة».
///
/// There is NO server endpoint that lists an admin's past conversations: the
/// web's /ops-assistant/history replays ONE conversation by its id, and the
/// app's bearer API (/api/v1/ops/assistant/*) has no history route at all.
/// So the button shows the conversation that is open now — and says so —
/// plus «محادثة جديدة». No endpoint was invented.
Future<void> showOpsHistorySheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTokens.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, sheetRef, _) {
        final chat = sheetRef.watch(opsChatControllerProvider);
        final lines = [
          for (final e in chat.entries)
            switch (e) {
              OpsUserEntry(:final text) => (true, text),
              OpsBotEntry(:final text) => (false, text),
              _ => null,
            },
        ].whereType<(bool, String)>().toList();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 6),
                  child: Text(
                    OpsTexts.historyTitle,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.textPrimary,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Text(
                    OpsTexts.historyOnlyCurrent,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: AppTokens.textMuted,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: lines.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text(
                            OpsTexts.historyEmpty,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTokens.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: lines.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                lines[i].$1
                                    ? Icons.person_outline
                                    : Icons.smart_toy_outlined,
                                size: 16,
                                color: AppTokens.textMuted,
                              ),
                              const SizedBox(width: AppTokens.s8),
                              Expanded(
                                child: Text(
                                  lines[i].$2,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: OutlinedButton.icon(
                    key: const ValueKey('ops-new'),
                    onPressed: chat.busy
                        ? null
                        : () {
                            sheetRef
                                .read(opsChatControllerProvider.notifier)
                                .newConversation();
                            Navigator.of(sheetContext).pop();
                          },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(OpsTexts.newChat),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
