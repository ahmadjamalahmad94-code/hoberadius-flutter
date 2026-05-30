import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/tickets_providers.dart';
import '../data/tickets_repository.dart';
import '../domain/ticket_model.dart';

class TicketDetailScreen extends ConsumerWidget {
  const TicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(ticketDetailProvider(ticketId));
    return detail.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => HubErrorState(
        title: 'تعذر فتح التذكرة',
        subtitle: '$error',
        onRetry: () => ref.invalidate(ticketDetailProvider(ticketId)),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: data.ticket.subject,
            subtitle: 'مشترك #${data.ticket.subscriberId}',
            leading: IconButton(
              onPressed: () => context.goNamed('tickets'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(ticketDetailProvider(ticketId)),
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث'),
              ),
              ElevatedButton.icon(
                onPressed: () => _showReplyDialog(context, ref, ticketId),
                icon: const Icon(Icons.reply_outlined),
                label: const Text('إضافة رد'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final info = _InfoPanel(ticket: data.ticket);
              final thread = _RepliesPanel(
                ticket: data.ticket,
                replies: data.replies,
              );
              final status = _StatusPanel(ticket: data.ticket);
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: AppTokens.s16),
                    status,
                    const SizedBox(height: AppTokens.s16),
                    thread,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 340,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        info,
                        const SizedBox(height: AppTokens.s16),
                        status,
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.s16),
                  Expanded(child: thread),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'تفاصيل التذكرة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              _StatusPill(ticket: ticket),
              _PriorityPill(ticket: ticket),
              StatusPill(
                text: _categoryLabel(ticket.category),
                tone: PillTone.cyan,
              ),
            ],
          ),
          const Divider(height: AppTokens.s24),
          _Line(label: 'رقم التذكرة', value: '#${ticket.id}'),
          _Line(
            label: 'تاريخ الفتح',
            value: _dateLabel(ticket.createdAt),
          ),
          _Line(
            label: 'آخر تحديث',
            value: _dateLabel(ticket.updatedAt),
          ),
          if (ticket.closedAt != null)
            _Line(
              label: 'تاريخ الإغلاق',
              value: _dateLabel(ticket.closedAt),
            ),
          if (ticket.body.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Text(
              ticket.body,
              style: const TextStyle(height: 1.55),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPanel extends ConsumerStatefulWidget {
  const _StatusPanel({required this.ticket});

  final SupportTicket ticket;

  @override
  ConsumerState<_StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends ConsumerState<_StatusPanel> {
  late String _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _status = widget.ticket.status;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'إدارة الحالة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'الحالة'),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
              DropdownMenuItem(value: 'pending', child: Text('بانتظار متابعة')),
              DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
            ],
            onChanged: _busy
                ? null
                : (value) => setState(() => _status = value ?? 'open'),
          ),
          const SizedBox(height: AppTokens.s12),
          ElevatedButton.icon(
            onPressed: _busy || _status == widget.ticket.status ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ الحالة'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(ticketsRepositoryProvider).updateStatus(
            widget.ticket.id,
            _status,
          );
      ref.invalidate(ticketDetailProvider(widget.ticket.id));
      ref.invalidate(ticketsPageProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة التذكرة')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _RepliesPanel extends StatelessWidget {
  const _RepliesPanel({required this.ticket, required this.replies});

  final SupportTicket ticket;
  final List<TicketReply> replies;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'المحادثة',
      child: replies.isEmpty
          ? const EmptyState(
              icon: Icons.forum_outlined,
              title: 'لا توجد ردود بعد',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final reply in replies) ...[
                  _ReplyBubble(reply: reply),
                  const SizedBox(height: AppTokens.s12),
                ],
              ],
            ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.reply});

  final TicketReply reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: reply.authorType == 'admin'
            ? AppTokens.brandSoft
            : AppTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                reply.authorLabel,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                _dateLabel(reply.createdAt),
                style:
                    const TextStyle(color: AppTokens.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(reply.body, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      text: ticket.statusLabel,
      tone: ticket.status == 'closed'
          ? PillTone.neutral
          : ticket.status == 'pending'
              ? PillTone.orange
              : PillTone.green,
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      text: ticket.priorityLabel,
      tone: ticket.priority == 'urgent' || ticket.priority == 'high'
          ? PillTone.red
          : PillTone.cyan,
    );
  }
}

Future<void> _showReplyDialog(
  BuildContext context,
  WidgetRef ref,
  int ticketId,
) async {
  final body = TextEditingController();
  var busy = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if (body.text.trim().isEmpty) return;
          setState(() => busy = true);
          try {
            await ref.read(ticketsRepositoryProvider).addReply(
                  ticketId,
                  body.text.trim(),
                );
            ref.invalidate(ticketDetailProvider(ticketId));
            ref.invalidate(ticketsPageProvider);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (error) {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text('$error')),
            );
          } finally {
            if (dialogContext.mounted) setState(() => busy = false);
          }
        }

        return AlertDialog(
          title: const Text('إضافة رد على التذكرة'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: body,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(labelText: 'نص الرد'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: busy ? null : submit,
              icon: const Icon(Icons.send_outlined),
              label: const Text('إرسال'),
            ),
          ],
        );
      },
    ),
  );
}

String _categoryLabel(String category) => switch (category) {
      'service' => 'خدمة',
      'payment' => 'دفع',
      'technical' => 'فني',
      _ => 'عام',
    };

String _dateLabel(DateTime? date) {
  if (date == null) return 'غير مسجل';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
