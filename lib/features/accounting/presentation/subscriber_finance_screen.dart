import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/idempotency.dart';
import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../subscribers/data/subscriber_actions_repository.dart';
import '../../subscribers/data/subscribers_repository.dart';
import '../../subscribers/domain/subscriber_actions_model.dart';
import '../application/subscriber_finance_data.dart';
import '../data/accounting_repository.dart';
import '../domain/accounting_model.dart';
import 'widgets/finance_forms.dart';
import 'widgets/finance_summary_card.dart';
import 'widgets/finance_tables.dart';

/// «الدفعات والسلف» of ONE subscriber.
///
/// Everything here is keyed by [username]: the router gives the page a
/// `ValueKey(username)` and [didUpdateWidget] resets the state too, so
/// changing only the username in the URL can never show (and settle!) the
/// previous subscriber's loans with the previous inputs.
///
/// «معاينة بدون تنفيذ» is computed locally from the subscriber's price and
/// NEVER calls a money endpoint (the payments endpoint stores a payment even
/// with `dry_run`, and older servers stored loans too).
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
  String? _paymentError;
  String? _paymentPreview;
  String? _loanError;
  String? _loanPreview;
  String? _tableError;
  final _paymentKeys = IdempotencyKeeper();
  final _loanKeys = IdempotencyKeeper();
  final _settleKeys = IdempotencyKeeper();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant SubscriberFinanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.username != widget.username) _resetFor();
  }

  /// Another subscriber: drop every typed value, message and key, reload.
  void _resetFor() {
    _paymentAmount.clear();
    _paymentNotes.clear();
    _loanHours.text = '2';
    _loanAmount.text = '0';
    _loanReason.clear();
    _paymentKeys.reset();
    _loanKeys.reset();
    _settleKeys.reset();
    setState(() {
      _applyPayment = false;
      _dryRunPayment = true;
      _applyLoan = false;
      _dryRunLoan = true;
      _paymentError = _paymentPreview = null;
      _loanError = _loanPreview = null;
      _tableError = null;
      _future = _load();
    });
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
    final username = widget.username;
    final sub = await ref.read(subscribersRepositoryProvider).get(username);
    final repo = ref.read(accountingRepositoryProvider);
    final sid = sub.id;
    final payments = await repo.listPayments(subscriberId: sid);
    final loans = await repo.listLoans(subscriberId: sid);
    final ledger = await repo.listLedger(subscriberId: sid);
    SubscriberActionsContext? ctx;
    try {
      ctx = await ref
          .read(subscriberActionsRepositoryProvider)
          .actionsContext(username);
    } catch (_) {
      ctx = null; // older server: no price/currency context
    }
    return SubscriberFinanceData(sub, payments, loans, ledger, context: ctx);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Runs a money action for the subscriber the page showed when the
  /// operator tapped: if the route changed meanwhile, nothing is refreshed
  /// into the new page.
  Future<bool> _run(
    Future<void> Function() action, {
    required void Function(String? error) onError,
  }) async {
    final forUser = widget.username;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted || forUser != widget.username) return false;
      onError(null);
      _refresh();
      return true;
    } catch (e) {
      if (!mounted || forUser != widget.username) return false;
      final msg = visibleErrorWithRetryHint(e);
      setState(() => onError(msg));
      _toast(msg);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPayment(SubscriberFinanceData data) async {
    final amount = parseLocalizedNumber(_paymentAmount.text);
    final problem = validateMoneyAmount(amount);
    if (problem != null) {
      setState(() {
        _paymentError = problem;
        _paymentPreview = null;
      });
      return;
    }
    if (_dryRunPayment) {
      setState(() {
        _paymentError = null;
        _paymentPreview = paymentPreviewText(
          amount: amount!,
          context: data.context,
          currency: data.currency,
          applyToRadius: _applyPayment,
        );
      });
      return;
    }
    final body = {
      'u': widget.username,
      'a': amount,
      'n': _paymentNotes.text.trim(),
      'r': _applyPayment,
    };
    final key = _paymentKeys.keyFor('payment', body);
    final ok = await _run(
      () async {
        final payment =
            await ref.read(accountingRepositoryProvider).createPayment(
                  username: widget.username,
                  amount: amount!,
                  notes: _paymentNotes.text.trim(),
                  applyToRadius: _applyPayment,
                  idempotencyKey: key,
                );
        final applied = payment.activationResult['applied_to_radius'] == true;
        _toast(
            applied ? 'تم التسجيل والتطبيق على الريدياس' : 'تم التسجيل المالي');
      },
      onError: (e) => _paymentError = e,
    );
    if (ok) {
      _paymentKeys.reset();
      _paymentAmount.clear();
      _paymentNotes.clear();
      setState(() => _paymentPreview = null);
    }
  }

  Future<void> _createLoan(SubscriberFinanceData data) async {
    final hours = (parseLocalizedNumber(_loanHours.text) ?? 0).floor();
    final amount = parseLocalizedNumber(_loanAmount.text) ?? 0;
    final problem = validateFinanceLoan(hours: hours, amount: amount);
    if (problem != null) {
      setState(() {
        _loanError = problem;
        _loanPreview = null;
      });
      return;
    }
    if (_dryRunLoan) {
      setState(() {
        _loanError = null;
        _loanPreview = loanPreviewText(
          hours: hours,
          amount: amount,
          currency: data.currency,
          applyToRadius: _applyLoan,
        );
      });
      return;
    }
    final body = {
      'u': widget.username,
      'h': hours,
      'a': amount,
      'r': _loanReason.text.trim(),
      'x': _applyLoan,
    };
    final key = _loanKeys.keyFor('loan', body);
    final ok = await _run(
      () async {
        await ref.read(accountingRepositoryProvider).createLoan(
              username: widget.username,
              hours: hours,
              amount: amount,
              reason: _loanReason.text.trim(),
              applyToRadius: _applyLoan,
              idempotencyKey: key,
            );
        _toast('تم تسجيل السلفة');
      },
      onError: (e) => _loanError = e,
    );
    if (ok) {
      _loanKeys.reset();
      _loanReason.clear();
      setState(() => _loanPreview = null);
    }
  }

  Future<void> _settleLoan(LoanEntry loan, SubscriberFinanceData data) async {
    // Never settle a loan that is not this page's subscriber's.
    if (data.subscriber.id != null &&
        loan.subscriberId != 0 &&
        loan.subscriberId != data.subscriber.id) {
      setState(() => _tableError = 'هذه السلفة لا تخصّ ${widget.username}.');
      return;
    }
    final currency = loan.currency.isEmpty ? data.currency : loan.currency;
    final approved = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text('تسوية السلفة #${loan.id}؟'),
        content: Text(
          'المشترك: ${widget.username}\n'
          'المتبقّي: ${formatMoney(loan.outstanding.toDouble(), currency)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد التسوية'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    final key = _settleKeys.keyFor('settle', {'id': loan.id});
    final ok = await _run(
      () async {
        await ref.read(accountingRepositoryProvider).settleLoan(
              loanId: loan.id,
              amount: loan.outstanding,
              notes: 'تسوية من التطبيق',
              idempotencyKey: key,
            );
        _toast('تمت تسوية السلفة');
      },
      onError: (e) => _tableError = e,
    );
    if (ok) _settleKeys.reset();
  }

  Future<void> _voidPayment(PaymentTransaction payment) async {
    final approved = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
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
    await _run(
      () async {
        await ref.read(accountingRepositoryProvider).voidPayment(
              paymentId: payment.id,
              reason: 'تصحيح من تطبيق الإدارة',
            );
        _toast('تم إنشاء قيد عكسي للدفعة');
      },
      onError: (e) => _tableError = e,
    );
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
            subtitle: visibleErrorMessage(snapshot.error),
          );
        }
        final data = snapshot.data!;
        // A load that finished for a previous username is never shown.
        if (data.subscriber.username.isNotEmpty &&
            data.subscriber.username != widget.username) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'دفعات وسلف ${data.subscriber.username}',
              leading: IconButton(
                tooltip: 'رجوع',
                onPressed: () => context.goNamed(
                  'subscriber-edit',
                  pathParameters: {'username': widget.username},
                ),
                icon: const Icon(Icons.arrow_back),
              ),
              inlineActions: true,
              actions: [
                IconButton(
                  tooltip: 'تحديث',
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(
                    Icons.refresh,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            FinanceSummaryCard(
              payments: data.payments,
              loans: data.loans,
              currency: data.currency,
            ),
            const SizedBox(height: AppTokens.s8),
            const FinanceNotice(),
            const SizedBox(height: AppTokens.s12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                final payment = PaymentFormCard(
                  amount: _paymentAmount,
                  notes: _paymentNotes,
                  applyToRadius: _applyPayment,
                  dryRun: _dryRunPayment,
                  busy: _busy,
                  currency: data.currency,
                  error: _paymentError,
                  preview: _paymentPreview,
                  onApplyChanged: (v) => setState(() => _applyPayment = v),
                  onDryRunChanged: (v) => setState(() {
                    _dryRunPayment = v;
                    _paymentPreview = null;
                  }),
                  onSubmit: () => _createPayment(data),
                );
                final loan = LoanFormCard(
                  hours: _loanHours,
                  amount: _loanAmount,
                  reason: _loanReason,
                  applyToRadius: _applyLoan,
                  dryRun: _dryRunLoan,
                  busy: _busy,
                  currency: data.currency,
                  error: _loanError,
                  preview: _loanPreview,
                  onApplyChanged: (v) => setState(() => _applyLoan = v),
                  onDryRunChanged: (v) => setState(() {
                    _dryRunLoan = v;
                    _loanPreview = null;
                  }),
                  onSubmit: () => _createLoan(data),
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
            if (_tableError != null) ...[
              const SizedBox(height: AppTokens.s12),
              FinanceErrorBox(message: _tableError!),
            ],
            const SizedBox(height: AppTokens.s12),
            LoansTable(
              items: data.loans,
              currency: data.currency,
              onSettle: _busy ? null : (loan) => _settleLoan(loan, data),
            ),
            const SizedBox(height: AppTokens.s12),
            PaymentsTable(
              items: data.payments,
              onVoid: _busy ? null : _voidPayment,
            ),
            const SizedBox(height: AppTokens.s12),
            LedgerTable(items: data.ledger),
          ],
        );
      },
    );
  }
}

/// Finance-page loan guard: a positive number of hours and a value between
/// 0 and [kMaxMoneyAmount].
String? validateFinanceLoan({required int hours, required num amount}) {
  if (hours <= 0) return 'أدخل مدة السلفة بالساعات.';
  if (!amount.isFinite || amount < 0) return 'قيمة السلفة لا تكون سالبة.';
  if (amount > kMaxMoneyAmount) {
    return 'قيمة السلفة كبيرة جدًا — الحدّ الأعلى ${kMaxMoneyAmount.toStringAsFixed(0)}.';
  }
  return null;
}

/// Local «معاينة بدون تنفيذ» of a payment: nothing is sent to the server.
String paymentPreviewText({
  required double amount,
  required SubscriberActionsContext? context,
  required String currency,
  required bool applyToRadius,
}) {
  final money = formatMoney(amount, currency);
  final cover = context == null
      ? ''
      : coverageText(amount, context.effectivePrice, context.planMinutes);
  final time = !applyToRadius
      ? 'بدون تمديد للحساب (التطبيق على الريدياس مُطفأ).'
      : cover.isEmpty
          ? 'المدّة تُحسب على الخادم عند التنفيذ.'
          : 'يُمدِّد الحساب بـ ≈ $cover.';
  return 'معاينة فقط — لم يُسجَّل شيء. دفعة $money: $time';
}

/// Local «معاينة بدون تنفيذ» of a loan: nothing is sent to the server.
String loanPreviewText({
  required int hours,
  required double amount,
  required String currency,
  required bool applyToRadius,
}) {
  final value = amount > 0
      ? 'دين بقيمة ${formatMoney(amount, currency)}'
      : 'سلفة مجانية بدون قيمة';
  final radius =
      applyToRadius ? 'وتُطبَّق المدّة على الحساب' : 'دون تطبيق على الحساب';
  return 'معاينة فقط — لم يُسجَّل شيء. ${arDuration(hours * 60)}: $value $radius.';
}
