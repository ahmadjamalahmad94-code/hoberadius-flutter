import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

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
                  child: Text('معلّقة'),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('قيد المعالجة'),
                ),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text('محلولة'),
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
            FilledButton.icon(
              onPressed: () => _showServiceRequestDialog(context, ref),
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
              label: const Text('طلب خدمة'),
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
            subtitle: visibleErrorMessage(error),
            onRetry: () => ref.invalidate(ticketsPageProvider),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return EmptyState(
                icon: Icons.support_agent_outlined,
                title: 'لا توجد تذاكر مطابقة',
                action: ElevatedButton.icon(
                  onPressed: () => _showServiceRequestDialog(context, ref),
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: const Text('طلب خدمة'),
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
      tone: _ticketStatusTone(ticket.status),
    );
  }
}

PillTone _ticketStatusTone(String status) => switch (status) {
      'open' => PillTone.orange,
      'pending' => PillTone.orange,
      'in_progress' => PillTone.blue,
      'resolved' => PillTone.green,
      'closed' => PillTone.neutral,
      _ => PillTone.neutral,
    };

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

class _ServiceOption {
  const _ServiceOption(this.key, this.label);

  final String key;
  final String label;
}

class _RequestTypeOption {
  const _RequestTypeOption(this.key, this.label);

  final String key;
  final String label;
}

const _serviceOptions = [
  _ServiceOption('subscribers', 'المشتركون'),
  _ServiceOption('sessions', 'الجلسات'),
  _ServiceOption('cards', 'الكروت'),
  _ServiceOption('cards_recharge', 'شحن الكروت'),
  _ServiceOption('distributors', 'الموزعون'),
  _ServiceOption('payment_collection', 'تحصيل المدفوعات'),
  _ServiceOption('finance_center', 'المركز المالي'),
  _ServiceOption('ip_change_vpn', 'خدمة تغيير IP / VPN'),
  _ServiceOption('customer_portal', 'بوابة العميل'),
  _ServiceOption('customer_support', 'الدعم الفني'),
  _ServiceOption('communications', 'التواصل والحملات'),
  _ServiceOption('network_policy', 'سياسات الشبكة'),
  _ServiceOption('nas', 'أجهزة الشبكة'),
  _ServiceOption('integration_bridge', 'جسر الربط'),
  _ServiceOption('integration_tokens', 'مفاتيح الربط'),
  _ServiceOption('reports', 'التقارير'),
  _ServiceOption('other', 'خدمة أخرى'),
];

const _requestTypeOptions = [
  _RequestTypeOption('activation', 'تفعيل'),
  _RequestTypeOption('upgrade', 'ترقية'),
  _RequestTypeOption('trial', 'فتح تجريبي'),
  _RequestTypeOption('renewal', 'تجديد'),
  _RequestTypeOption('support', 'مراجعة فنية'),
];

Future<void> _showServiceRequestDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final subscribers = await ref.read(_ticketSubscribersProvider.future);
  if (!context.mounted) return;
  if (subscribers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يوجد مشتركون لربط الطلب بهم')),
    );
    return;
  }

  final notes = TextEditingController();
  final customServiceName = TextEditingController();
  final amount = TextEditingController();
  var subscriberId = subscribers.first.id;
  var service = _serviceOptions.first;
  var requestType = _requestTypeOptions.first;
  var createPayment = false;
  var currency = 'ILS';
  var busy = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if (subscriberId == null) return;
          final serviceName = service.key == 'other'
              ? customServiceName.text.trim()
              : service.label;
          if (serviceName.isEmpty) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(content: Text('اكتب اسم الخدمة المطلوبة')),
            );
            return;
          }

          double? paymentAmount;
          if (createPayment) {
            paymentAmount = double.tryParse(
              amount.text.trim().replaceAll(',', '.'),
            );
            if (paymentAmount == null || paymentAmount <= 0) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('أدخل مبلغ دفع صحيح')),
              );
              return;
            }
          }

          setState(() => busy = true);
          try {
            final result =
                await ref.read(ticketsRepositoryProvider).createServiceRequest(
                      subscriberId: subscriberId!,
                      serviceKey: service.key,
                      serviceName: serviceName,
                      requestType: requestType.key,
                      notes: notes.text.trim(),
                      amount: paymentAmount,
                      currency: currency,
                    );
            ref.invalidate(ticketsPageProvider);
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            if (context.mounted) {
              final hasPayment = result.paymentRequest != null;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hasPayment
                        ? 'تم فتح تذكرة وطلب دفع مرتبط بها'
                        : 'تم فتح تذكرة طلب الخدمة',
                  ),
                ),
              );
              context.goNamed(
                'ticket-detail',
                pathParameters: {'id': '${result.ticketId}'},
              );
            }
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
          title: const Text('طلب خدمة'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
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
                  const SizedBox(height: AppTokens.s12),
                  DropdownButtonFormField<_ServiceOption>(
                    initialValue: service,
                    decoration: const InputDecoration(labelText: 'الخدمة'),
                    items: [
                      for (final option in _serviceOptions)
                        DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => setState(
                              () => service = value ?? _serviceOptions.first,
                            ),
                  ),
                  if (service.key == 'other') ...[
                    const SizedBox(height: AppTokens.s12),
                    TextField(
                      controller: customServiceName,
                      enabled: !busy,
                      decoration:
                          const InputDecoration(labelText: 'اسم الخدمة'),
                    ),
                  ],
                  const SizedBox(height: AppTokens.s12),
                  DropdownButtonFormField<_RequestTypeOption>(
                    initialValue: requestType,
                    decoration: const InputDecoration(labelText: 'نوع الطلب'),
                    items: [
                      for (final option in _requestTypeOptions)
                        DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => setState(
                              () => requestType =
                                  value ?? _requestTypeOptions.first,
                            ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  TextField(
                    controller: notes,
                    enabled: !busy,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات الطلب',
                      hintText: 'اكتب الاتفاق أو تفاصيل الترقية المطلوبة',
                    ),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SwitchListTile.adaptive(
                    value: createPayment,
                    onChanged: busy
                        ? null
                        : (value) => setState(() => createPayment = value),
                    title: const Text('إنشاء طلب دفع الآن'),
                    subtitle: const Text(
                      'يبقى الطلب بانتظار إثبات الدفع ومراجعة الإدارة.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (createPayment) ...[
                    const SizedBox(height: AppTokens.s8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: amount,
                            enabled: !busy,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(labelText: 'المبلغ'),
                          ),
                        ),
                        const SizedBox(width: AppTokens.s8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: currency,
                            decoration:
                                const InputDecoration(labelText: 'العملة'),
                            items: const [
                              DropdownMenuItem(
                                value: 'ILS',
                                child: Text('شيكل'),
                              ),
                              DropdownMenuItem(
                                value: 'USD',
                                child: Text('دولار'),
                              ),
                              DropdownMenuItem(
                                value: 'JOD',
                                child: Text('دينار'),
                              ),
                            ],
                            onChanged: busy
                                ? null
                                : (value) => setState(
                                      () => currency = value ?? 'ILS',
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: busy ? null : submit,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('فتح الطلب'),
            ),
          ],
        );
      },
    ),
  );
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
              SnackBar(content: Text(visibleErrorMessage(error))),
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
                            value: 'service_request',
                            child: Text('طلب خدمة'),
                          ),
                          DropdownMenuItem(
                            value: 'complaint',
                            child: Text('شكوى'),
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
