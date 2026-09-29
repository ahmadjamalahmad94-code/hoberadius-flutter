import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../features/admin_control/application/admin_control_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/currency_field.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/tickets_providers.dart';
import '../data/tickets_repository.dart';
import '../domain/ticket_model.dart';
import 'ticket_tones.dart';

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
        subtitle: visibleErrorMessage(error),
        onRetry: () => ref.invalidate(ticketDetailProvider(ticketId)),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: data.ticket.subject,
            subtitle: 'مشترك #${data.ticket.subscriberId}',
            inlineActions: true,
            leading: IconButton(
              tooltip: 'كل التذاكر',
              onPressed: () => context.goNamed('tickets'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: () => ref.invalidate(ticketDetailProvider(ticketId)),
                icon: const Icon(
                  Icons.refresh,
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          ActionBar(
            items: [
              ActionItem(
                icon: Icons.reply_outlined,
                label: 'إضافة رد',
                primary: true,
                onPressed: () => _showReplyDialog(context, ref, ticketId),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final info = _InfoPanel(ticket: data.ticket);
              final thread = _RepliesPanel(
                ticket: data.ticket,
                replies: data.replies,
              );
              final status = _StatusPanel(ticket: data.ticket);
              final servicePanel = data.ticket.category == 'service_request'
                  ? _ServiceRequestPanel(ticket: data.ticket)
                  : null;
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: AppTokens.s12),
                    status,
                    if (servicePanel != null) ...[
                      const SizedBox(height: AppTokens.s12),
                      servicePanel,
                    ],
                    const SizedBox(height: AppTokens.s12),
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
                        if (servicePanel != null) ...[
                          const SizedBox(height: AppTokens.s16),
                          servicePanel,
                        ],
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusPill(ticket: ticket),
              _PriorityPill(ticket: ticket),
              StatusPill(
                text: ticket.categoryLabel,
                tone: PillTone.brand,
                icon: Icons.label_outline,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          InfoGrid(
            columns: 3,
            items: [
              InfoItem(
                icon: Icons.tag,
                label: 'رقم التذكرة',
                value: '#${ticket.id}',
              ),
              InfoItem(
                icon: Icons.event_outlined,
                label: 'تاريخ الفتح',
                value: _dateLabel(ticket.createdAt),
              ),
              InfoItem(
                icon: Icons.update,
                label: 'آخر تحديث',
                value: _dateLabel(ticket.updatedAt),
              ),
              if (ticket.closedAt != null)
                InfoItem(
                  icon: Icons.event_available_outlined,
                  label: 'تاريخ الإغلاق',
                  value: _dateLabel(ticket.closedAt),
                ),
            ],
          ),
          if (ticket.body.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s12),
            Text(
              ticket.body,
              style: const TextStyle(height: 1.5),
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: const [
                DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text('بانتظار متابعة'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('قيد التنفيذ'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('تم الحل')),
                DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _status = value ?? 'open'),
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          SizedBox(
            width: 124,
            child: HubActionButton(
              item: ActionItem(
                icon: Icons.save_outlined,
                label: 'حفظ الحالة',
                primary: true,
                onPressed:
                    _busy || _status == widget.ticket.status ? null : _save,
              ),
            ),
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
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ServiceRequestPanel extends ConsumerStatefulWidget {
  const _ServiceRequestPanel({required this.ticket});

  final SupportTicket ticket;

  @override
  ConsumerState<_ServiceRequestPanel> createState() =>
      _ServiceRequestPanelState();
}

class _ServiceRequestPanelState extends ConsumerState<_ServiceRequestPanel> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'إدارة طلب الخدمة',
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'قرارات الإدارة تفتح طلب دفع أو تجربة مؤقتة عند الحاجة، بدون أوامر مباشرة على الراوتر.',
            style: TextStyle(
              color: AppTokens.textMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          ActionBar(
            maxPerRow: 2,
            items: [
              ActionItem(
                icon: Icons.check_circle_outline,
                label: 'موافقة مبدئية',
                primary: true,
                onPressed: _busy
                    ? null
                    : () => _showDecisionDialog(
                          decision: 'approve',
                          title: 'موافقة مبدئية',
                        ),
              ),
              ActionItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'طلب دفع',
                onPressed: _busy
                    ? null
                    : () => _showDecisionDialog(
                          decision: 'request_payment',
                          title: 'طلب دفع',
                          withPayment: true,
                        ),
              ),
              ActionItem(
                icon: Icons.timer_outlined,
                label: 'فتح تجريبي',
                tone: PillTone.blue,
                onPressed: _busy
                    ? null
                    : () => _showDecisionDialog(
                          decision: 'trial',
                          title: 'فتح تجريبي',
                        ),
              ),
              ActionItem(
                icon: Icons.cancel_outlined,
                label: 'رفض',
                tone: PillTone.red,
                onPressed: _busy
                    ? null
                    : () => _showDecisionDialog(
                          decision: 'reject',
                          title: 'رفض الطلب',
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDecisionDialog({
    required String decision,
    required String title,
    bool withPayment = false,
  }) async {
    final note = TextEditingController();
    final amount = TextEditingController();
    final trialDays = TextEditingController(text: '7');
    final withTrial = decision == 'trial';
    final currency = ref.read(tenantCurrencyProvider);
    var dialogBusy = false;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit() async {
            // Same-frame double taps: the button disables only on the next
            // frame, so the handler itself refuses a second run.
            if (dialogBusy) return;
            double? paymentAmount;
            if (withPayment) {
              final money = readMoneyInput(amount.text);
              paymentAmount = money.value;
              if (paymentAmount == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(money.error!)),
                );
                return;
              }
            }
            int? trialDaysValue;
            if (withTrial) {
              trialDaysValue = int.tryParse(trialDays.text.trim());
              if (trialDaysValue == null ||
                  trialDaysValue < 1 ||
                  trialDaysValue > 60) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('مدة التجربة يجب أن تكون بين 1 و60 يوم'),
                  ),
                );
                return;
              }
            }

            setDialogState(() => dialogBusy = true);
            setState(() => _busy = true);
            try {
              final result = await ref
                  .read(ticketsRepositoryProvider)
                  .decideServiceRequest(
                    ticketId: widget.ticket.id,
                    decision: decision,
                    // what the operator saw → 409 if decided meanwhile
                    expectedStatus: widget.ticket.status,
                    note: note.text.trim(),
                    amount: paymentAmount,
                    trialDays: trialDaysValue,
                    currency: currency,
                  );
              ref.invalidate(ticketDetailProvider(widget.ticket.id));
              ref.invalidate(ticketsPageProvider);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              final payment = result.paymentRequest;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    payment == null
                        ? result.trialMessage
                        : 'تم فتح طلب دفع بقيمة ${payment.amountLabel}',
                  ),
                ),
              );
            } catch (error) {
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(visibleErrorMessage(error))),
              );
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => dialogBusy = false);
              }
              if (mounted) setState(() => _busy = false);
            }
          }

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (withPayment) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: amount,
                            enabled: !dialogBusy,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'المبلغ',
                              helperText: kMaxMoneyHelper,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Expanded(
                          child: CurrencyField(currency: currency),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                  ],
                  if (withTrial) ...[
                    TextField(
                      controller: trialDays,
                      enabled: !dialogBusy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'مدة التجربة بالأيام',
                        helperText: 'من يوم واحد إلى 60 يوم',
                      ),
                    ),
                    const SizedBox(height: AppTokens.s12),
                  ],
                  TextField(
                    controller: note,
                    enabled: !dialogBusy,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة الإدارة',
                      hintText: 'اكتب سبب القرار أو تفاصيل الاتفاق',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    dialogBusy ? null : () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: dialogBusy ? null : submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ القرار'),
              ),
            ],
          );
        },
      ),
    );
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: replies.isEmpty
          ? const Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 18,
                  color: AppTokens.textMuted,
                ),
                SizedBox(width: AppTokens.s8),
                Text(
                  'لا توجد ردود بعد',
                  style: TextStyle(
                    color: AppTokens.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < replies.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppTokens.s8),
                  _ReplyBubble(reply: replies[i]),
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
          const SizedBox(height: AppTokens.s4),
          Text(reply.body, style: const TextStyle(height: 1.45)),
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
      tone: ticketStatusTone(ticket.status),
      dot: true,
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
      tone: ticketPriorityTone(ticket.priority),
      icon: Icons.flag_outlined,
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
    useRootNavigator: true,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          // Same-frame double taps: the button disables only on the next
          // frame, so the handler itself refuses a second run.
          if (busy) return;
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
              SnackBar(content: Text(visibleErrorMessage(error))),
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

String _dateLabel(DateTime? date) {
  if (date == null) return 'غير مسجل';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
