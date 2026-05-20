import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../subscribers/data/subscribers_repository.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../data/accounting_repository.dart';
import '../domain/accounting_model.dart';

class SubscriberFinanceScreen extends ConsumerStatefulWidget {
  const SubscriberFinanceScreen({super.key, required this.username});

  final String username;

  @override
  ConsumerState<SubscriberFinanceScreen> createState() =>
      _SubscriberFinanceScreenState();
}

class _SubscriberFinanceScreenState
    extends ConsumerState<SubscriberFinanceScreen> {
  late Future<_FinanceData> _future;
  final _paymentAmount = TextEditingController();
  final _paymentNotes = TextEditingController();
  final _loanHours = TextEditingController(text: '2');
  final _loanAmount = TextEditingController(text: '0');
  final _loanReason = TextEditingController();
  bool _applyPayment = false;
  bool _dryRunPayment = true;
  bool _applyLoan = false;
  bool _dryRunLoan = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _paymentAmount.dispose();
    _paymentNotes.dispose();
    _loanHours.dispose();
    _loanAmount.dispose();
    _loanReason.dispose();
    super.dispose();
  }

  Future<_FinanceData> _load() async {
    final sub =
        await ref.read(subscribersRepositoryProvider).get(widget.username);
    final repo = ref.read(accountingRepositoryProvider);
    final sid = sub.id;
    final payments = await repo.listPayments(subscriberId: sid);
    final loans = await repo.listLoans(subscriberId: sid);
    final ledger = await repo.listLedger(subscriberId: sid);
    return _FinanceData(sub, payments, loans, ledger);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPayment() {
    final amount = num.tryParse(_paymentAmount.text.trim()) ?? 0;
    return _run(() async {
      if (amount <= 0) throw Exception('أدخل مبلغًا صحيحًا');
      final payment =
          await ref.read(accountingRepositoryProvider).createPayment(
                username: widget.username,
                amount: amount,
                notes: _paymentNotes.text.trim(),
                applyToRadius: _applyPayment,
                dryRun: _dryRunPayment,
              );
      _paymentAmount.clear();
      _paymentNotes.clear();
      final result = payment.activationResult;
      final label = result['dry_run'] == true
          ? 'تمت كتجربة فقط'
          : result['applied_to_radius'] == true
              ? 'تم التطبيق على RADIUS'
              : 'تم التسجيل المالي';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(label)));
      }
    });
  }

  Future<void> _createLoan() {
    final hours = int.tryParse(_loanHours.text.trim()) ?? 0;
    final amount = num.tryParse(_loanAmount.text.trim()) ?? 0;
    return _run(() async {
      if (hours <= 0) throw Exception('أدخل مدة السلفة بالساعات');
      await ref.read(accountingRepositoryProvider).createLoan(
            username: widget.username,
            hours: hours,
            amount: amount,
            reason: _loanReason.text.trim(),
            applyToRadius: _applyLoan,
            dryRun: _dryRunLoan,
          );
      _loanReason.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل السلفة')),
        );
      }
    });
  }

  Future<void> _settleLoan(LoanEntry loan) {
    return _run(() async {
      await ref.read(accountingRepositoryProvider).settleLoan(
            loanId: loan.id,
            amount: loan.amount,
            notes: 'تسوية من التطبيق',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت تسوية السلفة')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FinanceData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر جلب البيانات المالية',
            subtitle: '${snapshot.error}',
          );
        }
        final data = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.goNamed(
                    'subscriber-edit',
                    pathParameters: {'username': widget.username},
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    'دفعات وسلف ${data.subscriber.username}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTokens.navy900,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'تحديث',
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            _Notice(),
            const SizedBox(height: AppTokens.s16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                final forms = [
                  _PaymentCard(
                    amount: _paymentAmount,
                    notes: _paymentNotes,
                    applyToRadius: _applyPayment,
                    dryRun: _dryRunPayment,
                    busy: _busy,
                    onApplyChanged: (v) => setState(() => _applyPayment = v),
                    onDryRunChanged: (v) => setState(() => _dryRunPayment = v),
                    onSubmit: _createPayment,
                  ),
                  _LoanCard(
                    hours: _loanHours,
                    amount: _loanAmount,
                    reason: _loanReason,
                    applyToRadius: _applyLoan,
                    dryRun: _dryRunLoan,
                    busy: _busy,
                    onApplyChanged: (v) => setState(() => _applyLoan = v),
                    onDryRunChanged: (v) => setState(() => _dryRunLoan = v),
                    onSubmit: _createLoan,
                  ),
                ];
                if (!wide) {
                  return Column(
                    children: [
                      forms[0],
                      const SizedBox(height: AppTokens.s12),
                      forms[1],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: forms[0]),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(child: forms[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTokens.s16),
            _LoansTable(
              items: data.loans,
              onSettle: _busy ? null : _settleLoan,
            ),
            const SizedBox(height: AppTokens.s16),
            _PaymentsTable(items: data.payments),
            const SizedBox(height: AppTokens.s16),
            _LedgerTable(items: data.ledger),
          ],
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTokens.cyan500),
          SizedBox(width: AppTokens.s8),
          Expanded(
            child: Text(
              'تجربة فقط لا تغير حساب RADIUS. التطبيق الفعلي يمدد/يفعل الحساب حسب نتيجة الخادم.',
              style: TextStyle(color: AppTokens.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.amount,
    required this.notes,
    required this.applyToRadius,
    required this.dryRun,
    required this.busy,
    required this.onApplyChanged,
    required this.onDryRunChanged,
    required this.onSubmit,
  });

  final TextEditingController amount;
  final TextEditingController notes;
  final bool applyToRadius;
  final bool dryRun;
  final bool busy;
  final ValueChanged<bool> onApplyChanged;
  final ValueChanged<bool> onDryRunChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تسجيل دفعة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ'),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            controller: notes,
            decoration: const InputDecoration(labelText: 'ملاحظات'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تطبيق على RADIUS'),
            subtitle: const Text('يمدد الحساب حسب المدة المستحقة'),
            value: applyToRadius,
            onChanged: busy ? null : onApplyChanged,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تجربة فقط'),
            value: dryRun,
            onChanged: busy ? null : (v) => onDryRunChanged(v ?? true),
          ),
          ElevatedButton.icon(
            onPressed: busy ? null : onSubmit,
            icon: const Icon(Icons.add),
            label: const Text('تسجيل الدفعة'),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.hours,
    required this.amount,
    required this.reason,
    required this.applyToRadius,
    required this.dryRun,
    required this.busy,
    required this.onApplyChanged,
    required this.onDryRunChanged,
    required this.onSubmit,
  });

  final TextEditingController hours;
  final TextEditingController amount;
  final TextEditingController reason;
  final bool applyToRadius;
  final bool dryRun;
  final bool busy;
  final ValueChanged<bool> onApplyChanged;
  final ValueChanged<bool> onDryRunChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'منح سلفة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: AppTokens.s12),
          TextField(
            controller: hours,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد الساعات'),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'قيمة السلفة'),
          ),
          const SizedBox(height: AppTokens.s8),
          TextField(
            controller: reason,
            decoration: const InputDecoration(labelText: 'سبب السلفة'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تطبيق مؤقت على RADIUS'),
            value: applyToRadius,
            onChanged: busy ? null : onApplyChanged,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تجربة فقط'),
            value: dryRun,
            onChanged: busy ? null : (v) => onDryRunChanged(v ?? true),
          ),
          ElevatedButton.icon(
            onPressed: busy ? null : onSubmit,
            icon: const Icon(Icons.schedule),
            label: const Text('منح السلفة'),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTable extends StatelessWidget {
  const _PaymentsTable({required this.items});

  final List<PaymentTransaction> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        title: 'لا توجد دفعات بعد',
      );
    }
    return _SectionTable(
      title: 'آخر الدفعات',
      columns: const ['#', 'المبلغ', 'المدة', 'الحالة', 'التاريخ'],
      rows: items
          .map(
            (p) => [
              '${p.id}',
              '${p.amount} ${p.currency}',
              '${p.earnedMinutes} دقيقة',
              p.status,
              _fmt(p.createdAt),
            ],
          )
          .toList(),
    );
  }
}

class _LoansTable extends StatelessWidget {
  const _LoansTable({required this.items, required this.onSettle});

  final List<LoanEntry> items;
  final Future<void> Function(LoanEntry loan)? onSettle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'لا توجد سلف بعد',
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppTokens.s16),
            child: Text(
              'السلف والتسويات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          ...items.map(
            (loan) => ListTile(
              title: Text(
                '${loan.durationMinutes} دقيقة • ${loan.amount} ${loan.currency}',
              ),
              subtitle:
                  Text(loan.reason.isEmpty ? 'بدون سبب مسجل' : loan.reason),
              trailing: loan.status == 'open'
                  ? TextButton(
                      onPressed:
                          onSettle == null ? null : () => onSettle!(loan),
                      child: const Text('تسوية'),
                    )
                  : const Text('تمت التسوية'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTable extends StatelessWidget {
  const _LedgerTable({required this.items});

  final List<LedgerEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.scale_outlined,
        title: 'لا توجد قيود مالية',
      );
    }
    return _SectionTable(
      title: 'سجل القيود',
      columns: const ['#', 'النوع', 'المبلغ', 'المصدر', 'التاريخ'],
      rows: items
          .map(
            (e) => [
              '${e.id}',
              e.entryType,
              '${e.amount} ${e.currency}',
              e.sourceType.isEmpty ? '—' : e.sourceType,
              _fmt(e.createdAt),
            ],
          )
          .toList(),
    );
  }
}

class _SectionTable extends StatelessWidget {
  const _SectionTable({
    required this.title,
    required this.columns,
    required this.rows,
  });

  final String title;
  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
              rows: rows
                  .map(
                    (r) => DataRow(
                      cells: r.map((cell) => DataCell(Text(cell))).toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceData {
  _FinanceData(this.subscriber, this.payments, this.loans, this.ledger);

  final Subscriber subscriber;
  final List<PaymentTransaction> payments;
  final List<LoanEntry> loans;
  final List<LedgerEntry> ledger;
}

String _fmt(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy-MM-dd').format(value);
}
