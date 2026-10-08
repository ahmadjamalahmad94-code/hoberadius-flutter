import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../application/ops_assistant_providers.dart';
import '../../data/ops_assistant_repository.dart';
import '../../domain/ops_labels.dart';
import '../../domain/ops_models.dart';
import '../../domain/ops_task_catalog.dart';

/// The sheet's answer: a suggested task, or a level-4 system suggestion.
/// `null` (a dismissed sheet) means the admin chose nothing.
sealed class OpsSheetPick {
  const OpsSheetPick();
}

class OpsTaskPick extends OpsSheetPick {
  const OpsTaskPick(this.task);
  final OpsTask task;
}

class OpsSuggestionPick extends OpsSheetPick {
  const OpsSuggestionPick(this.suggestion);
  final OpsSuggestion suggestion;
}

/// «المهام المقترحة» — the full list behind the round «+» button.
///
/// Tapping a row POPS the sheet with that pick: the list disappears and the
/// caller writes the sentence into the chat (the owner's requirement).
Future<OpsSheetPick?> showOpsTaskSheet(BuildContext context) {
  return showModalBottomSheet<OpsSheetPick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTokens.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const OpsTaskSheet(),
  );
}

class OpsTaskSheet extends ConsumerWidget {
  const OpsTaskSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(opsSuggestionsProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Grabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppTokens.brand,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  const Expanded(
                    child: Text(
                      OpsTexts.tasksTitle,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('ops-tasks-close'),
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(
                OpsTexts.tasksHint,
                style: TextStyle(fontSize: 12.5, color: AppTokens.textMuted),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                key: const ValueKey('ops-tasks-list'),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                children: [
                  // Level-4 detector events keep their own section: the same
                  // «ابدأ محادثة» behaviour, now gathered with the tasks.
                  const _SectionTitle(OpsTexts.eventsTitle),
                  suggestions.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: OpsSheetHint('جارٍ التحميل…'),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OpsSheetHint(
                        e is OpsError && e.message.isNotEmpty
                            ? e.message
                            : OpsTexts.eventsError,
                      ),
                    ),
                    data: (list) => list.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: OpsSheetHint(OpsTexts.eventsEmpty),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final s in list)
                                _SuggestionRow(
                                  suggestion: s,
                                  onTap: () => Navigator.of(context)
                                      .pop(OpsSuggestionPick(s)),
                                ),
                            ],
                          ),
                  ),
                  for (final g in kOpsTaskGroups) ...[
                    _SectionTitle(g.title),
                    for (final t in g.tasks)
                      _TaskRow(
                        task: t,
                        onTap: () =>
                            Navigator.of(context).pop(OpsTaskPick(t)),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 44,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          decoration: BoxDecoration(
            color: AppTokens.slate200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppTokens.textMuted,
          ),
        ),
      );
}

class OpsSheetHint extends StatelessWidget {
  const OpsSheetHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: AppTokens.textMuted),
      );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onTap});

  final OpsTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey('ops-task-${task.id}'),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTokens.brandSoft,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                ),
                alignment: Alignment.center,
                child: Icon(task.icon, size: 18, color: AppTokens.brand),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new,
                size: 13,
                color: AppTokens.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, required this.onTap});

  final OpsSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey(
          'ops-start-${suggestion.eventType}-${suggestion.index}',
        ),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppTokens.amberSoft,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            border: Border.all(color: AppTokens.warningMed),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppTokens.amberInk,
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.amberInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.text,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
