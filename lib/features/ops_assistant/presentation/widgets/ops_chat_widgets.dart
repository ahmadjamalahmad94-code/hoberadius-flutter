import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/ops_assistant_providers.dart';
import '../../domain/ops_labels.dart';
import '../../domain/ops_models.dart';
import 'ops_chat_shell.dart';

// The chat's building blocks — the web's `.ops-msg` / `.ops-card` family.
// Every text the model or the server sent is rendered with [Text] (plain
// text, never markup), like the web's `textContent`.

enum OpsBubbleKind { user, bot, empty, error, wait }

/// One message bubble. In RTL the admin's bubbles sit on the start (right)
/// side and the assistant's on the end (left) side, as on the web.
class OpsBubble extends StatelessWidget {
  const OpsBubble({super.key, required this.text, required this.kind});

  final String text;
  final OpsBubbleKind kind;

  @override
  Widget build(BuildContext context) {
    final user = kind == OpsBubbleKind.user;
    final (bg, fg, border) = switch (kind) {
      OpsBubbleKind.user => (AppTokens.brand, Colors.white, AppTokens.brand),
      OpsBubbleKind.error => (
          AppTokens.redSoft,
          AppTokens.redInk,
          AppTokens.dangerMed,
        ),
      OpsBubbleKind.wait => (
          Colors.transparent,
          AppTokens.textMuted,
          Colors.transparent,
        ),
      _ => (AppTokens.brandSoft, AppTokens.textPrimary, AppTokens.brandLine),
    };
    const r = Radius.circular(14);
    const tail = Radius.circular(4);
    return Align(
      alignment: user
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: LayoutBuilder(
        builder: (context, c) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: c.maxWidth * 0.88),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadiusDirectional.only(
                topStart: r,
                topEnd: r,
                bottomStart: user ? tail : r,
                bottomEnd: user ? r : tail,
              ),
              border: kind == OpsBubbleKind.empty
                  ? Border.all(color: AppTokens.slate200)
                  : Border.all(color: border),
            ),
            child: kind == OpsBubbleKind.wait
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Text(
                        text,
                        style: TextStyle(
                          color: fg,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: kind == OpsBubbleKind.empty
                          ? AppTokens.textSecondary
                          : fg,
                      fontSize: 14,
                      height: 1.75,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// `.ops-card`.
class OpsCardFrame extends StatelessWidget {
  const OpsCardFrame({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          ...children,
        ],
      ),
    );
  }
}

/// `.ops-kv` — label / value rows.
class OpsKeyValues extends StatelessWidget {
  const OpsKeyValues({super.key, required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    k,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.slate500,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Text(
                    v,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTokens.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// `.ops-note` (amber) / `.ops-note.is-danger` (red).
class OpsNote extends StatelessWidget {
  const OpsNote({super.key, required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.s8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: danger ? AppTokens.redSoft : AppTokens.amberSoft,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(
          color: danger ? AppTokens.dangerMed : AppTokens.warningMed,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.6,
          color: danger ? AppTokens.redInk : AppTokens.amberInk,
        ),
      ),
    );
  }
}

class OpsHint extends StatelessWidget {
  const OpsHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTokens.textMuted),
        ),
      );
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({required this.n, required this.text});
  final Object? n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${n ?? ''}. ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
        style: const TextStyle(fontSize: 13, color: AppTokens.textPrimary),
      ),
    );
  }
}

/// A CHOICES list — the same items the model sees.
class OpsChoicesCard extends StatelessWidget {
  const OpsChoicesCard({super.key, required this.reply});
  final OpsReply reply;

  @override
  Widget build(BuildContext context) {
    return OpsCardFrame(
      title: OpsTexts.choicesTitle,
      children: [
        for (final it in reply.items)
          _NumberedLine(n: it['n'], text: opsChoiceLine(it)),
        if (reply.truncated) const OpsHint(OpsTexts.choicesMore),
      ],
    );
  }
}

/// A read-only INFO answer (batch status / subscriber info / online now).
class OpsInfoCard extends StatelessWidget {
  const OpsInfoCard({super.key, required this.reply});
  final OpsReply reply;

  @override
  Widget build(BuildContext context) {
    final title = OpsTexts.infoTitleFor(reply.source);
    if (reply.error.isNotEmpty) {
      return OpsCardFrame(
        title: title,
        children: [
          OpsNote(text: OpsTexts.infoError(reply.error), danger: true),
        ],
      );
    }
    final data = reply.data ?? const <String, dynamic>{};
    final rows = opsInfoRows(data);
    final items = data['items'] is List
        ? [
            for (final e in data['items'] as List)
              if (e is Map) e.map((k, v) => MapEntry(k.toString(), v)),
          ]
        : const <Map<String, dynamic>>[];
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isNotEmpty) OpsKeyValues(rows: rows),
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s8),
          for (final it in items)
            _NumberedLine(n: it['n'], text: opsOnlineLine(it)),
        ],
        if (data['truncated'] == true) const OpsHint(OpsTexts.infoMore),
      ],
    );
    final hasDetails =
        rows.isNotEmpty || items.isNotEmpty || data['truncated'] == true;
    // «النتيجة جاهزة» + the summary line; the rows open behind
    // «عرض التفاصيل» so a long result does not bury the conversation.
    return OpsResultFrame(
      summary: title,
      child: hasDetails
          ? OpsExpandableDetails(
              toggleKey: const ValueKey('ops-details-toggle'),
              child: details,
            )
          : null,
    );
  }
}

/// A read-only answer: the green check, «النتيجة جاهزة», the summary line and
/// (optionally) the expandable details row.
class OpsResultFrame extends StatelessWidget {
  const OpsResultFrame({super.key, required this.summary, this.child});

  final String summary;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: AppTokens.green,
              ),
              SizedBox(width: 6),
              Text(
                OpsTexts.resultReady,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.greenInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: AppTokens.textPrimary,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// One step block of the confirmation card.
class OpsStepBlock extends StatelessWidget {
  const OpsStepBlock({super.key, required this.step, required this.multi});

  final OpsStep step;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final rows = opsStepRows(
      values: step.values,
      display: step.display,
      names: step.names,
      pendingRefs: step.pendingRefs,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          multi ? '${OpsTexts.step} ${step.n}: ${step.title}' : step.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: AppTokens.textPrimary,
          ),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 4),
          OpsKeyValues(rows: rows),
        ],
        if (step.password != null) const OpsNote(text: OpsTexts.passwordNote),
        if (step.danger == 'L3')
          const OpsNote(text: OpsTexts.danger, danger: true),
        if (!step.executable)
          const OpsNote(text: OpsTexts.notExec, danger: true),
      ],
    );
  }
}

/// The executor's confirmation card + «تأكيد» / «إلغاء».
class OpsProposalCard extends StatelessWidget {
  const OpsProposalCard({
    super.key,
    required this.entry,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
  });

  final OpsProposalEntry entry;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = entry.proposal;
    final open = entry.state == OpsProposalState.pending && !busy;
    return OpsCardFrame(
      title: p.isPlan ? OpsTexts.planTitle : OpsTexts.proposalTitle,
      children: [
        for (var i = 0; i < p.steps.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.s8),
              child: Divider(height: 1, color: AppTokens.borderStrong),
            ),
          OpsStepBlock(step: p.steps[i], multi: p.isPlan),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: ValueKey('ops-confirm-${entry.id}'),
              onPressed: open ? onConfirm : null,
              icon: entry.state == OpsProposalState.confirming
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text(OpsTexts.confirm),
            ),
            OutlinedButton(
              key: ValueKey('ops-cancel-${entry.id}'),
              onPressed: open ? onCancel : null,
              child: const Text(OpsTexts.cancel),
            ),
            if (entry.state == OpsProposalState.confirmed)
              const StatusPill(text: OpsTexts.stDone, tone: PillTone.green),
            if (entry.state == OpsProposalState.cancelled)
              const StatusPill(text: OpsTexts.cancel, tone: PillTone.neutral),
          ],
        ),
      ],
    );
  }
}

/// The execution report: per step done / failed / not run.
class OpsReportCard extends StatelessWidget {
  const OpsReportCard({super.key, required this.entry});
  final OpsReportEntry entry;

  static PillTone _tone(String s) => switch (s) {
        'done' => PillTone.green,
        'failed' => PillTone.red,
        _ => PillTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final r = entry.report;
    return OpsCardFrame(
      title: '${OpsTexts.resultTitle} — ${OpsTexts.reportStatus(r.status)}',
      children: [
        if (r.replayed) const OpsNote(text: OpsTexts.replayed),
        for (final s in r.steps)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppTokens.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      text: OpsTexts.stepStatus(s.status),
                      tone: _tone(s.status),
                    ),
                    Text(
                      '${OpsTexts.step} ${s.n} · '
                      '${entry.titles[s.action] ?? s.action}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (s.errorMessage.isNotEmpty) OpsHint(s.errorMessage),
              ],
            ),
          ),
      ],
    );
  }
}

/// «كلمة مرور تُعرض مرّة واحدة» — the secrets live only in this dialog;
/// closing it drops them (web: removed from the DOM on close).
Future<void> showOpsSecretsDialog(
  BuildContext context,
  List<OpsSecret> secrets,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => OpsSecretsDialog(secrets: secrets),
  );
}

class OpsSecretsDialog extends StatefulWidget {
  const OpsSecretsDialog({super.key, required this.secrets});
  final List<OpsSecret> secrets;

  @override
  State<OpsSecretsDialog> createState() => _OpsSecretsDialogState();
}

class _OpsSecretsDialogState extends State<OpsSecretsDialog> {
  final Set<int> _copied = {};

  Future<void> _copy(int i) async {
    await Clipboard.setData(ClipboardData(text: widget.secrets[i].password));
    if (mounted) setState(() => _copied.add(i));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.key, color: AppTokens.brandInk),
          SizedBox(width: AppTokens.s8),
          Expanded(child: Text(OpsTexts.secretTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OpsNote(text: OpsTexts.secretWarning, danger: true),
            for (var i = 0; i < widget.secrets.length; i++)
              Container(
                margin: const EdgeInsets.only(top: AppTokens.s8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                  border: Border.all(color: AppTokens.borderStrong),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.secrets[i].username),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: SelectableText(
                              widget.secrets[i].password,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      key: ValueKey('ops-copy-$i'),
                      onPressed: () => _copy(i),
                      icon: Icon(
                        _copied.contains(i) ? Icons.check : Icons.copy,
                        size: 16,
                      ),
                      label: Text(
                        _copied.contains(i) ? OpsTexts.copied : OpsTexts.copy,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(OpsTexts.secretClose),
        ),
      ],
    );
  }
}

/// The opening bubble: the welcome line, two tappable example prompts as
/// chips, and the «سأجهّز الإجراء» promise.
class OpsGreetingBubble extends StatelessWidget {
  const OpsGreetingBubble({super.key, this.onExample});

  /// Tapping an example writes it into the composer.
  final void Function(String text)? onExample;

  static const examples = [OpsTexts.exampleRenew, OpsTexts.exampleCards];

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        borderRadius: const BorderRadiusDirectional.only(
          topStart: r,
          topEnd: r,
          bottomStart: r,
          bottomEnd: Radius.circular(4),
        ),
        border: Border.all(color: AppTokens.brandLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            OpsTexts.greetingLead,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: AppTokens.textPrimary,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final e in examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OpsExampleChip(
                  key: ValueKey('ops-example-${examples.indexOf(e)}'),
                  text: e,
                  onTap: onExample == null ? null : () => onExample!(e),
                ),
              ),
            ),
          const SizedBox(height: 2),
          const Text(
            OpsTexts.greetingTail,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: AppTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
