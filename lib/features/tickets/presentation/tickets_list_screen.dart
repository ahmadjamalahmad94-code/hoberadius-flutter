import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../subscribers/data/subscribers_repository.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../application/tickets_providers.dart';
import '../data/tickets_repository.dart';
import '../domain/ticket_model.dart';

final _ticketSubscribersProvider =
    FutureProvider.autoDispose<List<Subscriber>>((ref) {
  return ref.watch(subscribersRepositoryProvider).list(limit: 300);
});

class TicketsListScreen extends ConsumerWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(ticketsPageProvider);
    final status = ref.watch(ticketStatusFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'تذاكر الدعم وطلبات الخدمة',
          actions: [
            DropdownButton<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: '', child: Text('كل الحالات')),
                DropdownMenuItem(value: 'open', child: Text('مفتوحة')),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text('بانتظار متابعة'),
                ),
                DropdownMenuItem(value: 'closed', child: Text('مغلقة')),
              ],
              onChanged: (value) {
                ref.read(ticketStatusFilterProvider.notifier).state =
                    value ?? '';
              },
            ),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(ticketsPageProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCreateTicketDialog(context, ref),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('تذكرة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        tickets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => HubErrorState(
            title: 'تعذر جلب التذاكر',
            subtitle: '$error',
            onRetry: () => ref.invalidate(ticketsPageProvider),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return EmptyState(
                icon: Icons.support_agent_outlined,
                title: 'لا توجد تذاكر مطابقة',
                action: ElevatedButton.icon(
                  onPressed: () => _showCreateTicketDialog(context, ref),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('فتح تذكرة'),
                ),
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  if (!wide) {
                    return Column(
                      children: [
                        for (final ticket in page.items)
                          _TicketTile(ticket: ticket),
                      ],
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('التذكرة')),
                        DataColumn(label: Text('المشترك')),
                        DataColumn(label: Text('الأولوية')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('آخر تحديث')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final ticket in page.items)
                          DataRow(
                            cells: [
                              DataCell(_TicketTitle(ticket: ticket)),
                              DataCell(Text('#${ticket.subscriberId}')),
                              DataCell(_Priority(ticket: ticket)),
                              DataCell(_Status(ticket: ticket)),
                              DataCell(Text(_dateLabel(ticket.updatedAt))),
                              DataCell(
                                IconButton(
                                  tooltip: 'فتح التذكرة',
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: () => context.goNamed(
                                    'ticket-detail',
                                    pathParameters: {'id': '${ticket.id}'},
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.goNamed(
        'ticket-detail',
        pathParameters: {'id': '${ticket.id}'},
      ),
      title: _TicketTitle(ticket: ticket),
      subtitle: Text(
        'مشترك #${ticket.subscriberId} · ${_dateLabel(ticket.updatedAt)}',
      ),
      trailing: _Status(ticket: ticket),
    );
  }
}

class _TicketTitle extends StatelessWidget {
  const _TicketTitle({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Text(
      ticket.subject.isEmpty ? 'تذكرة #${ticket.id}' : ticket.subject,
      style: const TextStyle(fontWeight: FontWeight.w800),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.ticket});

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

class _Priority extends StatelessWidget {
  const _Priority({required this.ticket});

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

Future<void> _showCreateTicketDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final subscribers = await ref.read(_ticketSubscribersProvider.future);
  if (!context.mounted) return;
  if (subscribers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('لا يوجد مشتركون لربط التذكرة بهم'),
      ),
    );
    return;
  }

  final subject = TextEditingController();
  final body = TextEditingController();
  var subscriberId = subscribers.first.id;
  var category = 'general';
  var priority = 'normal';
  var busy = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if (subscriberId == null || subject.text.trim().isEmpty) return;
          setState(() => busy = true);
          try {
            final ticket = await ref.read(ticketsRepositoryProvider).create(
                  subscriberId: subscriberId!,
                  subject: subject.text.trim(),
                  category: category,
                  priority: priority,
                  body: body.text.trim(),
                );
            ref.invalidate(ticketsPageProvider);
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            context.goNamed(
              'ticket-detail',
              pathParameters: {'id': '${ticket.id}'},
            );
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
          title: const Text('فتح تذكرة دعم'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: subscriberId,
                  decoration: const InputDecoration(labelText: 'المشترك'),
                  items: [
                    for (final subscriber in subscribers)
                      if (subscriber.id != null)
                        DropdownMenuItem(
                          value: subscriber.id,
                          child: Text(_subscriberLabel(subscriber)),
                        ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) => setState(() => subscriberId = value),
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الطلب',
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'النوع'),
                        items: const [
                          DropdownMenuItem(
                            value: 'general',
                            child: Text('عام'),
                          ),
                          DropdownMenuItem(
                            value: 'service',
                            child: Text('خدمة'),
                          ),
                          DropdownMenuItem(
                            value: 'payment',
                            child: Text('دفع'),
                          ),
                          DropdownMenuItem(
                            value: 'technical',
                            child: Text('فني'),
                          ),
                        ],
                        onChanged: busy
                            ? null
                            : (value) => setState(
                                  () => category = value ?? 'general',
                                ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration:
                            const InputDecoration(labelText: 'الأولوية'),
                        items: const [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('منخفضة'),
                          ),
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('عادية'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('مرتفعة'),
                          ),
                          DropdownMenuItem(
                            value: 'urgent',
                            child: Text('عاجلة'),
                          ),
                        ],
                        onChanged: busy
                            ? null
                            : (value) => setState(
                                  () => priority = value ?? 'normal',
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: body,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'التفاصيل'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: busy ? null : submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('فتح التذكرة'),
            ),
          ],
        );
      },
    ),
  );
}

String _subscriberLabel(Subscriber subscriber) {
  final name =
      subscriber.fullName.isEmpty ? subscriber.username : subscriber.fullName;
  return '$name · ${subscriber.username}';
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'غير مسجل';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
