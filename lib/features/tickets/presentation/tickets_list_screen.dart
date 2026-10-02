import 'package:hoberadius_app/core/format/money_limits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/theme/tokens.dart';
import '../../../features/admin_control/application/admin_control_providers.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/currency_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../subscribers/presentation/widgets/subscriber_search_field.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../application/tickets_providers.dart';
import '../data/tickets_repository.dart';
import '../domain/ticket_model.dart';
import 'ticket_tones.dart';

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
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(ticketsPageProvider),
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        ActionBar(
          items: [
            ActionItem(
              icon: Icons.add_comment_outlined,
              label: 'تذكرة جديدة',
              primary: true,
              // web tk_create = settings.edit
              onPressed: ref.watch(permissionsProvider).can('settings.edit')
                  ? () => _showCreateTicketDialog(context, ref)
                  : null,
              tooltip: ref.watch(permissionsProvider).can('settings.edit')
                  ? null
                  : ref
                      .watch(permissionsProvider)
                      .deniedReason(perm: 'settings.edit'),
            ),
            ActionItem(
              icon: Icons.playlist_add_check_circle_outlined,
              label: 'طلب خدمة',
              onPressed: () => _showServiceRequestDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        _StatusFilterChips(
          selected: status,
          onSelected: (value) =>
              ref.read(ticketStatusFilterProvider.notifier).state = value,
        ),
        const SizedBox(height: AppTokens.s12),
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
                  final footer = LoadMoreFooter(
                    hasMore: page.hasMore,
                    loading: page.loadingMore,
                    error: page.loadMoreError,
                    shown: page.items.length,
                    onLoadMore: () =>
                        ref.read(ticketsPageProvider.notifier).loadMore(),
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        for (var i = 0; i < page.items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _TicketTile(ticket: page.items[i]),
                        ],
                        footer,
                      ],
                    );
                  }
                  return Column(
                    children: [
                      SingleChildScrollView(
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
                      ),
                      footer,
                    ],
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

/// Status filter as a row of colour-coded chips (was a bare dropdown lost
/// among the header buttons).
class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _options = [
    ('', 'كل الحالات'),
    ('open', 'مفتوحة'),
    ('pending', 'معلّقة'),
    ('in_progress', 'قيد المعالجة'),
    ('resolved', 'محلولة'),
    ('closed', 'مغلقة'),
  ];

  @override
  Widget build(BuildContext context) {
    // Wraps onto a second line instead of scrolling: at 390 px «محلولة» and
    // «مغلقة» sat off-screen with no hint that the row scrolls (R09 N13).
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (value, label) in _options) _chip(value, label),
      ],
    );
  }

  Widget _chip(String value, String label) {
    final isSelected = selected == value;
    final tone = value.isEmpty ? PillTone.brand : ticketStatusTone(value);
    final (bg, fg, border) = pillToneColors(tone);
    return Material(
      color: isSelected ? bg : AppTokens.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? fg : AppTokens.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => onSelected(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? fg : AppTokens.textSecondary,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.goNamed(
        'ticket-detail',
        pathParameters: {'id': '${ticket.id}'},
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s8 + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TicketTitle(ticket: ticket),
                  const SizedBox(height: 2),
                  Text(
                    'مشترك #${ticket.subscriberId} · '
                    '${_dateLabel(ticket.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Status(ticket: ticket),
                const SizedBox(height: 4),
                _Priority(ticket: ticket),
              ],
            ),
          ],
        ),
      ),
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
      tone: ticketStatusTone(ticket.status),
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
      tone: ticketPriorityTone(ticket.priority),
      icon: Icons.flag_outlined,
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
  final notes = TextEditingController();
  final customServiceName = TextEditingController();
  final amount = TextEditingController();
  // No pre-selected subscriber: the operator searches the whole tenant.
  int? subscriberId;
  var service = _serviceOptions.first;
  var requestType = _requestTypeOptions.first;
  var createPayment = false;
  final currency = ref.read(tenantCurrencyProvider);
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
          if (subscriberId == null) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(content: Text('اختر المشترك أولًا')),
            );
            return;
          }
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
            final money = readMoneyInput(amount.text);
            paymentAmount = money.value;
            if (paymentAmount == null) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(money.error!)),
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
                  SubscriberSearchField(
                    enabled: !busy,
                    onChanged: (s) => setState(() => subscriberId = s?.id),
                  ),
                  const SizedBox(height: AppTokens.s12),
                  DropdownButtonFormField<_ServiceOption>(
                    isExpanded: true,
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
                    isExpanded: true,
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
                            decoration: InputDecoration(
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
  final subject = TextEditingController();
  final body = TextEditingController();
  // No pre-selected subscriber: the operator searches the whole tenant.
  int? subscriberId;
  var category = 'general';
  var priority = 'normal';
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
          if (subscriberId == null || subject.text.trim().isEmpty) {
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text(
                  subscriberId == null
                      ? 'اختر المشترك أولًا'
                      : 'اكتب عنوان الطلب',
                ),
              ),
            );
            return;
          }
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
                SubscriberSearchField(
                  enabled: !busy,
                  onChanged: (s) => setState(() => subscriberId = s?.id),
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
                        isExpanded: true,
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'النوع'),
                        // The web's list and labels (tickets_list.html) —
                        // «service» had no label, «payment/technical» were
                        // app-only (parity-b).
                        items: const [
                          DropdownMenuItem(
                            value: 'general',
                            child: Text('عام'),
                          ),
                          DropdownMenuItem(
                            value: 'billing',
                            child: Text('الفواتير والدفع'),
                          ),
                          DropdownMenuItem(
                            value: 'connection',
                            child: Text('الاتصال والخدمة'),
                          ),
                          DropdownMenuItem(
                            value: 'hardware',
                            child: Text('الأجهزة والمعدّات'),
                          ),
                          DropdownMenuItem(
                            value: 'complaint',
                            child: Text('شكوى'),
                          ),
                          DropdownMenuItem(
                            value: 'service_request',
                            child: Text('طلب خدمة'),
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
                        isExpanded: true,
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

String _dateLabel(DateTime? date) {
  if (date == null) return 'غير مسجل';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
