import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../subscribers/data/subscribers_repository.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../data/invoices_repository.dart';
import '../domain/invoice_model.dart';

const _statusOptions = [
  (value: '', label: 'كل الحالات'),
  (value: 'paid', label: 'مدفوعة'),
  (value: 'pending', label: 'معلقة'),
  (value: 'failed', label: 'فشلت'),
  (value: 'refunded', label: 'مسترجعة'),
  (value: 'canceled', label: 'ملغاة'),
];

const _directionOptions = [
  (value: 'charge', label: 'تحصيل'),
  (value: 'refund', label: 'إرجاع'),
  (value: 'deposit', label: 'إيداع'),
  (value: 'withdraw', label: 'سحب'),
  (value: 'credit', label: 'رصيد'),
];

const _paymentMethodOptions = [
  (value: 'cash', label: 'نقدًا'),
  (value: 'transfer', label: 'حوالة'),
  (value: 'card', label: 'بطاقة'),
  (value: 'online', label: 'دفع إلكتروني'),
  (value: 'manual', label: 'يدوي'),
];

const _serviceTypeOptions = [
  (value: 'Hotspot', label: 'بوابة الدخول'),
  (value: 'PPPoE', label: 'برودباند'),
  (value: 'Balance', label: 'رصيد'),
];

final _invoicesProvider =
    FutureProvider.autoDispose.family<InvoicePage, String>((ref, status) {
  return ref.watch(invoicesRepositoryProvider).list(status: status);
});

final _subscribersProvider =
    FutureProvider.autoDispose<List<Subscriber>>((ref) {
  return ref.watch(subscribersRepositoryProvider).list(limit: 250);
});

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_invoicesProvider(_status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الفواتير',
          subtitle:
              'إدارة فواتير المشتركين، مراجعة الحالة، وتسجيل تحصيل أو إرجاع أو إيداع من التطبيق.',
          leading: const Icon(
            Icons.receipt_long_outlined,
            color: AppTokens.brand,
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(_invoicesProvider(_status)),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            FilledButton.icon(
              onPressed: _createInvoice,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('فاتورة جديدة'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'الحالة:',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              DropdownButton<String>(
                value: _status,
                items: _statusOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value ?? ''),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل الفواتير',
            subtitle: visibleErrorMessage(error),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return _EmptyInvoices(status: _status);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InvoiceStatsGrid(stats: page.stats, visibleCount: page.count),
                const SizedBox(height: AppTokens.s12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 860) {
                      return Column(
                        children: [
                          for (final invoice in page.items) ...[
                            _InvoiceCard(
                              invoice: invoice,
                              onStatusChanged: () =>
                                  ref.invalidate(_invoicesProvider(_status)),
                            ),
                            const SizedBox(height: AppTokens.s12),
                          ],
                        ],
                      );
                    }
                    return _InvoicesTable(
                      items: page.items,
                      onStatusChanged: () =>
                          ref.invalidate(_invoicesProvider(_status)),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createInvoice() async {
    final subscribers = await ref.read(_subscribersProvider.future).catchError(
          (_) => <Subscriber>[],
        );
    if (!mounted) return;
    final draft = await _invoiceDialog(context, subscribers: subscribers);
    if (draft == null) return;
    try {
      final created = await ref.read(invoicesRepositoryProvider).create(draft);
      ref.invalidate(_invoicesProvider(_status));
      if (!mounted) return;
      _snack(context, 'تم إنشاء الفاتورة ${created.displayNumber}');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    }
  }
}

class _InvoiceStatsGrid extends StatelessWidget {
  const _InvoiceStatsGrid({required this.stats, required this.visibleCount});

  final InvoiceStats stats;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 2 : 4;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTokens.s8,
          crossAxisSpacing: AppTokens.s8,
          childAspectRatio: constraints.maxWidth < 720 ? 2.35 : 2.8,
          children: [
            _StatCard(
              icon: Icons.summarize_outlined,
              title: 'إجمالي القيمة',
              value: _money(stats.total),
              tone: PillTone.green,
            ),
            _StatCard(
              icon: Icons.check_circle_outline,
              title: 'مدفوعة',
              value: _money(stats.paid),
              tone: PillTone.brand,
            ),
            _StatCard(
              icon: Icons.schedule_outlined,
              title: 'معلقة',
              value: _money(stats.pending),
              tone: PillTone.amber,
            ),
            _StatCard(
              icon: Icons.receipt_long_outlined,
              title: 'النتائج المعروضة',
              value: '$visibleCount من ${stats.count}',
              tone: PillTone.blue,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String value;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          StatusPill(text: '', tone: tone, icon: icon),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesTable extends StatelessWidget {
  const _InvoicesTable({required this.items, required this.onStatusChanged});

  final List<InvoiceRecord> items;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('الفاتورة')),
            DataColumn(label: Text('المشترك')),
            DataColumn(label: Text('الباقة')),
            DataColumn(label: Text('الاتجاه')),
            DataColumn(label: Text('المبلغ')),
            DataColumn(label: Text('طريقة الدفع')),
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('إجراء')),
          ],
          rows: [
            for (final invoice in items)
              DataRow(
                cells: [
                  DataCell(Text('${invoice.id}')),
                  DataCell(Text(invoice.displayNumber)),
                  DataCell(Text(invoice.username)),
                  DataCell(Text(_orUnset(invoice.planName))),
                  DataCell(
                    StatusPill(
                      text: invoice.directionLabel,
                      tone: _directionTone(invoice.direction),
                    ),
                  ),
                  DataCell(Text(_money(invoice.amount))),
                  DataCell(Text(invoice.paymentMethodLabel)),
                  DataCell(Text(_fmt(invoice.createdAt))),
                  DataCell(
                    StatusPill(
                      text: invoice.statusLabel,
                      tone: _statusTone(invoice.status),
                    ),
                  ),
                  DataCell(
                    TextButton.icon(
                      onPressed: () =>
                          _updateInvoiceStatus(context, invoice).then(
                        (changed) {
                          if (changed == true) onStatusChanged();
                        },
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('تحديث'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onStatusChanged,
  });

  final InvoiceRecord invoice;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppTokens.brand),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.displayNumber,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      invoice.username,
                      style: const TextStyle(color: AppTokens.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: invoice.statusLabel,
                tone: _statusTone(invoice.status),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              StatusPill(
                text: invoice.directionLabel,
                tone: _directionTone(invoice.direction),
              ),
              StatusPill(text: invoice.paymentMethodLabel, tone: PillTone.blue),
              StatusPill(
                text: invoice.serviceTypeLabel,
                tone: PillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _InfoLine(label: 'المبلغ', value: _money(invoice.amount)),
          _InfoLine(label: 'الباقة', value: _orUnset(invoice.planName)),
          _InfoLine(label: 'التاريخ', value: _fmt(invoice.createdAt)),
          if (invoice.note.trim().isNotEmpty)
            _InfoLine(label: 'ملاحظة', value: invoice.note),
          const SizedBox(height: AppTokens.s12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _updateInvoiceStatus(context, invoice).then(
                (changed) {
                  if (changed == true) onStatusChanged();
                },
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تحديث الحالة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppTokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvoices extends StatelessWidget {
  const _EmptyInvoices({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'لا توجد فواتير بهذه الفلترة',
      subtitle: status.isEmpty
          ? 'أنشئ أول فاتورة من زر فاتورة جديدة في الأعلى.'
          : 'غيّر الفلتر أو أنشئ فاتورة جديدة بهذه الحالة.',
    );
  }
}

Future<bool?> _updateInvoiceStatus(
  BuildContext context,
  InvoiceRecord invoice,
) async {
  final ref = ProviderScope.containerOf(context);
  final update = await _statusDialog(context, invoice);
  if (update == null) return false;
  try {
    await ref.read(invoicesRepositoryProvider).updateStatus(invoice.id, update);
    if (context.mounted) _snack(context, 'تم تحديث حالة الفاتورة');
    return true;
  } catch (error) {
    if (context.mounted) _snack(context, visibleErrorMessage(error));
    return false;
  }
}

Future<InvoiceStatusUpdate?> _statusDialog(
  BuildContext context,
  InvoiceRecord invoice,
) async {
  final note = TextEditingController(text: invoice.note);
  var status = invoice.status;
  final result = await showDialog<InvoiceStatusUpdate>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('تحديث حالة الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              invoice.displayNumber,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppTokens.s12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: _statusOptions
                  .where((option) => option.value.isNotEmpty)
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => status = value ?? 'pending'),
            ),
            const SizedBox(height: AppTokens.s12),
            TextFormField(
              controller: note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظة المراجعة',
                helperText: 'تضاف للملاحظة الحالية عند الحاجة.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              InvoiceStatusUpdate(status: status, note: note.text),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
  note.dispose();
  return result;
}

Future<InvoiceDraft?> _invoiceDialog(
  BuildContext context, {
  required List<Subscriber> subscribers,
}) async {
  final formKey = GlobalKey<FormState>();
  final subscriberId = TextEditingController();
  final username = TextEditingController();
  final amount = TextEditingController(text: '0');
  final planId = TextEditingController();
  final planName = TextEditingController();
  final note = TextEditingController();
  var serviceType = 'Hotspot';
  var direction = 'charge';
  var paymentMethod = 'cash';
  var status = 'paid';
  DateTime? expirationAt;

  final result = await showDialog<InvoiceDraft>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('فاتورة جديدة'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subscribers.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'اختيار مشترك',
                    ),
                    items: subscribers
                        .where((subscriber) => subscriber.id != null)
                        .map(
                          (subscriber) => DropdownMenuItem(
                            value: subscriber.id,
                            child: Text(
                              subscriber.fullName.trim().isEmpty
                                  ? subscriber.username
                                  : '${subscriber.username} - ${subscriber.fullName}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      Subscriber? selected;
                      for (final subscriber in subscribers) {
                        if (subscriber.id == value) {
                          selected = subscriber;
                          break;
                        }
                      }
                      if (selected == null || selected.id == null) return;
                      final selectedId = selected.id!;
                      final selectedUsername = selected.username;
                      final selectedPlanId = selected.planId;
                      setState(() {
                        subscriberId.text = '$selectedId';
                        username.text = selectedUsername;
                        if (selectedPlanId != null) {
                          planId.text = '$selectedPlanId';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppTokens.s12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: subscriberId,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رقم المشترك',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'اختر المشترك أو أدخل رقمه';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: TextFormField(
                        controller: username,
                        decoration: const InputDecoration(
                          labelText: 'اسم الدخول',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'أدخل اسم الدخول';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed < 0) {
                      return 'أدخل مبلغًا صحيحًا';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: planId,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رقم الباقة',
                          helperText: 'اختياري',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: TextFormField(
                        controller: planName,
                        decoration: const InputDecoration(
                          labelText: 'اسم الباقة',
                          helperText: 'اختياري',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                _SelectField(
                  label: 'نوع الخدمة',
                  value: serviceType,
                  options: _serviceTypeOptions,
                  onChanged: (value) =>
                      setState(() => serviceType = value ?? 'Hotspot'),
                ),
                const SizedBox(height: AppTokens.s12),
                _SelectField(
                  label: 'الاتجاه',
                  value: direction,
                  options: _directionOptions,
                  onChanged: (value) =>
                      setState(() => direction = value ?? 'charge'),
                ),
                const SizedBox(height: AppTokens.s12),
                _SelectField(
                  label: 'طريقة الدفع',
                  value: paymentMethod,
                  options: _paymentMethodOptions,
                  onChanged: (value) =>
                      setState(() => paymentMethod = value ?? 'cash'),
                ),
                const SizedBox(height: AppTokens.s12),
                _SelectField(
                  label: 'الحالة',
                  value: status,
                  options:
                      _statusOptions.where((option) => option.value.isNotEmpty),
                  onChanged: (value) =>
                      setState(() => status = value ?? 'paid'),
                ),
                const SizedBox(height: AppTokens.s12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: expirationAt ?? DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => expirationAt = picked);
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    expirationAt == null
                        ? 'تحديد تاريخ انتهاء اختياري'
                        : 'تنتهي في ${_fmt(expirationAt)}',
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  controller: note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                InvoiceDraft(
                  subscriberId: int.parse(subscriberId.text.trim()),
                  username: username.text.trim(),
                  amount: double.parse(amount.text.trim().replaceAll(',', '.')),
                  planId: int.tryParse(planId.text.trim()),
                  planName: planName.text.trim(),
                  serviceType: serviceType,
                  direction: direction,
                  paymentMethod: paymentMethod,
                  status: status,
                  expirationAt: expirationAt,
                  note: note.text.trim(),
                ),
              );
            },
            child: const Text('إنشاء الفاتورة'),
          ),
        ],
      ),
    ),
  );
  subscriberId.dispose();
  username.dispose();
  amount.dispose();
  planId.dispose();
  planName.dispose();
  note.dispose();
  return result;
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Iterable<({String label, String value})> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

PillTone _statusTone(String status) {
  return switch (status) {
    'paid' => PillTone.green,
    'pending' => PillTone.amber,
    'failed' => PillTone.red,
    'refunded' => PillTone.blue,
    'canceled' => PillTone.neutral,
    _ => PillTone.neutral,
  };
}

PillTone _directionTone(String direction) {
  return switch (direction) {
    'charge' => PillTone.blue,
    'refund' => PillTone.amber,
    'deposit' => PillTone.green,
    'withdraw' => PillTone.red,
    'credit' => PillTone.brand,
    _ => PillTone.neutral,
  };
}

String _money(num value) {
  return NumberFormat('#,##0.##').format(value);
}

String _fmt(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd').format(value);
}

String _orUnset(String value) {
  return value.trim().isEmpty ? 'غير محدد' : value;
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
