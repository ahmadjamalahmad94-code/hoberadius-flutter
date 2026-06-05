import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/accounting_repository.dart';
import '../domain/accounting_model.dart';

const _statusOptions = [
  (value: '', label: 'كل الحالات'),
  (value: 'open', label: 'مفتوحة'),
  (value: 'settled', label: 'مسددة'),
  (value: 'voided', label: 'ملغاة'),
];

final _loansProvider =
    FutureProvider.autoDispose.family<List<LoanEntry>, String>((ref, status) {
  return ref.watch(accountingRepositoryProvider).listLoans(status: status);
});

class LoansCenterScreen extends ConsumerStatefulWidget {
  const LoansCenterScreen({super.key});

  @override
  ConsumerState<LoansCenterScreen> createState() => _LoansCenterScreenState();
}

class _LoansCenterScreenState extends ConsumerState<LoansCenterScreen> {
  String _status = 'open';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_loansProvider(_status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'السلف والديون',
          subtitle:
              'متابعة السلف المفتوحة والديون المسجلة على المشتركين، مع إنشاء دين أو سلفة وتسويتها من التطبيق.',
          leading: const Icon(
            Icons.handshake_outlined,
            color: AppTokens.brand,
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(_loansProvider(_status)),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            FilledButton.icon(
              onPressed: _createLoan,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('تسجيل سلفة أو دين'),
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
                style: TextStyle(fontWeight: FontWeight.w900),
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
            title: 'تعذر تحميل السلف والديون',
            subtitle: visibleErrorMessage(error),
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.handshake_outlined,
                title: 'لا توجد سجلات بهذه الحالة',
                subtitle: _status == 'open'
                    ? 'لا توجد سلف أو ديون مفتوحة حاليًا. يمكنك تسجيل دين أو سلفة من الزر العلوي.'
                    : 'غيّر الفلتر أو راجع السجلات المالية إذا كنت تبحث عن قيد محدد.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LoansSummary(items: items),
                const SizedBox(height: AppTokens.s12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          for (final loan in items) ...[
                            _LoanCard(loan: loan, onSettle: _settleLoan),
                            const SizedBox(height: AppTokens.s12),
                          ],
                        ],
                      );
                    }
                    return _LoansTable(items: items, onSettle: _settleLoan);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _refresh() {
    ref.invalidate(_loansProvider(_status));
  }

  Future<void> _createLoan() async {
    final draft = await _loanDialog(context);
    if (draft == null) return;
    try {
      final loan = await ref.read(accountingRepositoryProvider).createLoan(
            username: draft.username,
            days: draft.days,
            hours: draft.hours,
            amount: draft.amount,
            currency: draft.currency,
            reason: draft.reason,
            priceFromDays: draft.priceFromDays,
            applyToRadius: draft.applyToRadius,
            dryRun: draft.dryRun,
          );
      _refresh();
      if (!mounted) return;
      _snack(
        context,
        'تم تسجيل ${loan.amount > 0 ? 'الدين' : 'السلفة'} للمشترك ${loan.username}',
      );
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    }
  }

  Future<void> _settleLoan(LoanEntry loan) async {
    final settlement = await _settlementDialog(context, loan);
    if (settlement == null) return;
    try {
      await ref.read(accountingRepositoryProvider).settleLoan(
            loanId: loan.id,
            amount: settlement.amount,
            currency: settlement.currency,
            method: settlement.method,
            notes: settlement.notes,
          );
      _refresh();
      if (!mounted) return;
      _snack(context, 'تمت تسوية السلفة رقم ${loan.id}');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    }
  }
}

class _LoansSummary extends StatelessWidget {
  const _LoansSummary({required this.items});

  final List<LoanEntry> items;

  @override
  Widget build(BuildContext context) {
    final open = items.where((item) => item.status == 'open').toList();
    final debt = open.fold<num>(0, (sum, item) => sum + item.amount);
    final minutes =
        open.fold<int>(0, (sum, item) => sum + item.durationMinutes);
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
              icon: Icons.list_alt_outlined,
              title: 'عدد السجلات',
              value: '${items.length}',
              tone: PillTone.blue,
            ),
            _StatCard(
              icon: Icons.hourglass_bottom_outlined,
              title: 'مفتوحة',
              value: '${open.length}',
              tone: PillTone.amber,
            ),
            _StatCard(
              icon: Icons.payments_outlined,
              title: 'الدين المفتوح',
              value: _money(debt),
              tone: PillTone.red,
            ),
            _StatCard(
              icon: Icons.schedule_outlined,
              title: 'دقائق مفتوحة',
              value: _duration(minutes),
              tone: PillTone.brand,
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Row(
        children: [
          StatusPill(text: '', icon: icon, tone: tone),
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
                    color: AppTokens.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTokens.textPrimary,
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

class _LoansTable extends StatelessWidget {
  const _LoansTable({required this.items, required this.onSettle});

  final List<LoanEntry> items;
  final Future<void> Function(LoanEntry loan) onSettle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: AppTokens.s20,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('المشترك')),
            DataColumn(label: Text('المدة')),
            DataColumn(label: Text('المبلغ')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('الاعتماد')),
            DataColumn(label: Text('البداية')),
            DataColumn(label: Text('النهاية')),
            DataColumn(label: Text('الإجراء')),
          ],
          rows: [
            for (final loan in items)
              DataRow(
                cells: [
                  DataCell(Text('${loan.id}')),
                  DataCell(
                    Text(
                      loan.username.isEmpty
                          ? '#${loan.subscriberId}'
                          : loan.username,
                    ),
                  ),
                  DataCell(Text(_duration(loan.durationMinutes))),
                  DataCell(Text('${_money(loan.amount)} ${loan.currency}')),
                  DataCell(
                    StatusPill(
                      text: loan.statusLabel,
                      tone: _statusTone(loan.status),
                      dot: true,
                    ),
                  ),
                  DataCell(Text(loan.approvalStatusLabel)),
                  DataCell(Text(_fmt(loan.startsAt))),
                  DataCell(Text(_fmt(loan.endsAt))),
                  DataCell(
                    loan.isOpen
                        ? TextButton.icon(
                            onPressed: () => onSettle(loan),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('تسوية'),
                          )
                        : const Text('لا يوجد إجراء'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.onSettle});

  final LoanEntry loan;
  final Future<void> Function(LoanEntry loan) onSettle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTokens.brandSoft,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.handshake_outlined,
                  color: AppTokens.brandInk,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.username.isEmpty
                          ? 'مشترك رقم ${loan.subscriberId}'
                          : loan.username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTokens.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'سجل رقم ${loan.id}',
                      style: const TextStyle(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: loan.statusLabel,
                tone: _statusTone(loan.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _InfoLine(label: 'المدة', value: _duration(loan.durationMinutes)),
          _InfoLine(
            label: 'المبلغ',
            value: '${_money(loan.amount)} ${loan.currency}',
          ),
          _InfoLine(label: 'الاعتماد', value: loan.approvalStatusLabel),
          _InfoLine(label: 'البداية', value: _fmt(loan.startsAt)),
          _InfoLine(label: 'النهاية', value: _fmt(loan.endsAt)),
          if (loan.reason.trim().isNotEmpty)
            _InfoLine(label: 'السبب', value: loan.reason),
          if (loan.isOpen) ...[
            const SizedBox(height: AppTokens.s8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onSettle(loan),
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('تسوية'),
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTokens.textSecondary,
                fontWeight: FontWeight.w800,
              ),
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

class _LoanDraft {
  const _LoanDraft({
    required this.username,
    required this.days,
    required this.hours,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.priceFromDays,
    required this.applyToRadius,
    required this.dryRun,
  });

  final String username;
  final int days;
  final int hours;
  final num amount;
  final String currency;
  final String reason;
  final bool priceFromDays;
  final bool applyToRadius;
  final bool dryRun;
}

class _SettlementDraft {
  const _SettlementDraft({
    required this.amount,
    required this.currency,
    required this.method,
    required this.notes,
  });

  final num amount;
  final String currency;
  final String method;
  final String notes;
}

Future<_LoanDraft?> _loanDialog(BuildContext context) async {
  final username = TextEditingController();
  final days = TextEditingController(text: '0');
  final hours = TextEditingController(text: '2');
  final amount = TextEditingController(text: '0');
  final currency = TextEditingController(text: 'JOD');
  final reason = TextEditingController();
  var priceFromDays = false;
  var applyToRadius = false;
  var dryRun = true;

  return showDialog<_LoanDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('تسجيل سلفة أو دين'),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: username,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    helperText: 'أدخل اسم المشترك كما هو في النظام.',
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: days,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'أيام'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: TextField(
                        controller: hours,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ساعات'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'المبلغ',
                          helperText:
                              'ضع 0 للسلفة المجانية أو مبلغًا لتسجيل دين.',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: currency,
                        decoration: const InputDecoration(labelText: 'العملة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'السبب'),
                ),
                SwitchListTile.adaptive(
                  value: priceFromDays,
                  onChanged: (value) => setState(() => priceFromDays = value),
                  title: const Text('احتساب الدين من عدد الأيام'),
                  subtitle: const Text(
                    'استخدمها عندما تريد تسجيل دين طويل بناءً على سعر الباقة.',
                  ),
                ),
                SwitchListTile.adaptive(
                  value: applyToRadius,
                  onChanged: (value) => setState(() => applyToRadius = value),
                  title: const Text('تطبيق المدة على الريدياس'),
                  subtitle: const Text(
                    'أبقها مغلقة إذا كنت تسجل الدين فقط دون تمديد فعلي.',
                  ),
                ),
                SwitchListTile.adaptive(
                  value: dryRun,
                  onChanged: applyToRadius
                      ? (value) => setState(() => dryRun = value)
                      : null,
                  title: const Text('تجربة آمنة بدون تطبيق نهائي'),
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
              final user = username.text.trim();
              final parsedDays = int.tryParse(days.text.trim()) ?? 0;
              final parsedHours = int.tryParse(hours.text.trim()) ?? 0;
              final parsedAmount =
                  num.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
              if (user.isEmpty || (parsedDays <= 0 && parsedHours <= 0)) {
                _snack(context, 'أدخل اسم المشترك ومدة السلفة أو الدين');
                return;
              }
              Navigator.pop(
                context,
                _LoanDraft(
                  username: user,
                  days: parsedDays,
                  hours: parsedHours,
                  amount: parsedAmount,
                  currency: currency.text.trim().isEmpty
                      ? 'JOD'
                      : currency.text.trim().toUpperCase(),
                  reason: reason.text.trim(),
                  priceFromDays: priceFromDays,
                  applyToRadius: applyToRadius,
                  dryRun: applyToRadius ? dryRun : true,
                ),
              );
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    ),
  );
}

Future<_SettlementDraft?> _settlementDialog(
  BuildContext context,
  LoanEntry loan,
) {
  final amount = TextEditingController(text: loan.amount.toString());
  final currency = TextEditingController(text: loan.currency);
  final method = TextEditingController(text: 'manual');
  final notes = TextEditingController();

  return showDialog<_SettlementDraft>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تسوية سلفة أو دين'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ المستلم'),
            ),
            const SizedBox(height: AppTokens.s8),
            TextField(
              controller: currency,
              decoration: const InputDecoration(labelText: 'العملة'),
            ),
            const SizedBox(height: AppTokens.s8),
            TextField(
              controller: method,
              decoration: const InputDecoration(labelText: 'طريقة التسوية'),
            ),
            const SizedBox(height: AppTokens.s8),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final parsedAmount =
                num.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
            if (parsedAmount <= 0) {
              _snack(context, 'أدخل مبلغ تسوية صحيح');
              return;
            }
            Navigator.pop(
              context,
              _SettlementDraft(
                amount: parsedAmount,
                currency: currency.text.trim().isEmpty
                    ? loan.currency
                    : currency.text.trim().toUpperCase(),
                method:
                    method.text.trim().isEmpty ? 'manual' : method.text.trim(),
                notes: notes.text.trim(),
              ),
            );
          },
          child: const Text('تسوية'),
        ),
      ],
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

PillTone _statusTone(String status) {
  return switch (status) {
    'open' => PillTone.amber,
    'settled' => PillTone.green,
    'voided' => PillTone.red,
    _ => PillTone.neutral,
  };
}

String _money(num value) {
  return NumberFormat('#,##0.##').format(value);
}

String _duration(int minutes) {
  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  final mins = minutes % 60;
  final parts = <String>[
    if (days > 0) '$days يوم',
    if (hours > 0) '$hours ساعة',
    if (mins > 0 || (days == 0 && hours == 0)) '$mins دقيقة',
  ];
  return parts.join(' و ');
}

String _fmt(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}
