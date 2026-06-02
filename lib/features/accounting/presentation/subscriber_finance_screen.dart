import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../subscribers/data/subscribers_repository.dart';
import '../application/subscriber_finance_data.dart';
import '../data/accounting_repository.dart';
import '../domain/accounting_model.dart';
import 'widgets/finance_forms.dart';
import 'widgets/finance_summary_card.dart';
import 'widgets/finance_tables.dart';

class SubscriberFinanceScreen extends ConsumerStatefulWidget {
  const SubscriberFinanceScreen({super.key, required this.username});

  final String username;

  @override
  ConsumerState<SubscriberFinanceScreen> createState() =>
      _SubscriberFinanceScreenState();
}

class _SubscriberFinanceScreenState
    extends ConsumerState<SubscriberFinanceScreen> {
  late Future<SubscriberFinanceData> _future;
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

  Future<SubscriberFinanceData> _load() async {
    final sub =
        await ref.read(subscribersRepositoryProvider).get(widget.username);
    final repo = ref.read(accountingRepositoryProvider);
    final sid = sub.id;
    final payments = await repo.listPayments(subscriberId: sid);
    final loans = await repo.listLoans(subscriberId: sid);
    final ledger = await repo.listLedger(subscriberId: sid);
    return SubscriberFinanceData(sub, payments, loans, ledger);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
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
          ? 'تمت المعاينة بدون تنفيذ'
          : result['applied_to_radius'] == true
              ? 'تم التطبيق على الريدياس'
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

  Future<void> _voidPayment(PaymentTransaction payment) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عكس الدفعة؟'),
        content: const Text(
          'سيتم إنشاء قيد عكسي في السجل المالي بدون حذف الدفعة الأصلية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد العكس'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    return _run(() async {
      await ref.read(accountingRepositoryProvider).voidPayment(
            paymentId: payment.id,
            reason: 'تصحيح من تطبيق الإدارة',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء قيد عكسي للدفعة')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SubscriberFinanceData>(
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
                          color: AppTokens.sidebarBg,
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
            FinanceSummaryCard(
              payments: data.payments,
              loans: data.loans,
              currency: data.payments.isNotEmpty
                  ? data.payments.first.currency
                  : (data.loans.isNotEmpty ? data.loans.first.currency : ''),
            ),
            const SizedBox(height: AppTokens.s12),
            const FinanceNotice(),
            const SizedBox(height: AppTokens.s16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                final payment = PaymentFormCard(
                  amount: _paymentAmount,
                  notes: _paymentNotes,
                  applyToRadius: _applyPayment,
                  dryRun: _dryRunPayment,
                  busy: _busy,
                  onApplyChanged: (v) => setState(() => _applyPayment = v),
                  onDryRunChanged: (v) => setState(() => _dryRunPayment = v),
                  onSubmit: _createPayment,
                );
                final loan = LoanFormCard(
                  hours: _loanHours,
                  amount: _loanAmount,
                  reason: _loanReason,
                  applyToRadius: _applyLoan,
                  dryRun: _dryRunLoan,
                  busy: _busy,
                  onApplyChanged: (v) => setState(() => _applyLoan = v),
                  onDryRunChanged: (v) => setState(() => _dryRunLoan = v),
                  onSubmit: _createLoan,
                );
                if (!wide) {
                  return Column(
                    children: [
                      payment,
                      const SizedBox(height: AppTokens.s12),
                      loan,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: payment),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(child: loan),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTokens.s16),
            LoansTable(
              items: data.loans,
              onSettle: _busy ? null : _settleLoan,
            ),
            const SizedBox(height: AppTokens.s16),
            PaymentsTable(
              items: data.payments,
              onVoid: _busy ? null : _voidPayment,
            ),
            const SizedBox(height: AppTokens.s16),
            LedgerTable(items: data.ledger),
          ],
        );
      },
    );
  }
}
