import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/idempotency.dart';
import '../../../core/api/paging.dart';
import '../../../core/api/visible_error_message.dart';
import '../../../core/format/number_input.dart';
import '../../../core/format/panel_time.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/hub_switch_row.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/number_text_field.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../core/format/currency.dart';
import '../../admin_control/application/admin_control_providers.dart';
import '../../subscribers/domain/subscriber_actions_model.dart'
    show kPaymentMethods, priceForMinutes;
import '../../subscribers/data/subscriber_actions_repository.dart';
import '../data/accounting_repository.dart';
import '../domain/accounting_model.dart';

const _statusOptions = [
  (value: '', label: 'كل الحالات'),
  (value: 'open', label: 'مفتوحة'),
  (value: 'settled', label: 'مسددة'),
  (value: 'voided', label: 'ملغاة'),
];

/// Loans center list: server paging (limit/offset + «تحميل المزيد») and the
/// server's totals for the WHOLE filter. The summary used to add up only the
/// first 100 loans on the phone (13,166 shown vs 184,770 real).
class LoansCenterState {
  const LoansCenterState({required this.list, this.totals});

  final PagedList<LoanEntry> list;
  final LoanTotals? totals;

  LoansCenterState copyWith({PagedList<LoanEntry>? list, LoanTotals? totals}) =>
      LoansCenterState(list: list ?? this.list, totals: totals ?? this.totals);
}

class LoansCenterController
    extends AutoDisposeFamilyAsyncNotifier<LoansCenterState, String> {
  static const pageSize = 100;

  @override
  Future<LoansCenterState> build(String arg) async {
    final page = await ref
        .watch(accountingRepositoryProvider)
        .listLoansPage(status: arg, limit: pageSize);
    return LoansCenterState(
      list: PagedList<LoanEntry>(
        items: page.items,
        hasMore: page.hasMore && page.items.isNotEmpty,
        total: page.totalCount,
        nextOffset: page.items.length,
      ),
      totals: page.totals,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.list.hasMore || current.list.loadingMore) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        list: current.list.copyWith(loadingMore: true, loadMoreError: null),
      ),
    );
    try {
      final page = await ref.read(accountingRepositoryProvider).listLoansPage(
            status: arg,
            limit: pageSize,
            offset: current.list.nextOffset,
          );
      final (merged, added) =
          mergeUniqueBy(current.list.items, page.items, (l) => l.id);
      state = AsyncData(
        LoansCenterState(
          list: current.list.copyWith(
            items: merged,
            hasMore: page.hasMore && added > 0,
            total: page.totalCount ?? current.list.total,
            nextOffset: current.list.nextOffset + page.items.length,
            loadingMore: false,
          ),
          totals: page.totals ?? current.totals,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          list: current.list.copyWith(loadingMore: false, loadMoreError: e),
        ),
      );
    }
  }
}

final _loansProvider = AsyncNotifierProvider.autoDispose
    .family<LoansCenterController, LoansCenterState, String>(
  LoansCenterController.new,
);

class LoansCenterScreen extends ConsumerStatefulWidget {
  const LoansCenterScreen({super.key});

  @override
  ConsumerState<LoansCenterScreen> createState() => _LoansCenterScreenState();
}

class _LoansCenterScreenState extends ConsumerState<LoansCenterScreen> {
  String _status = 'open';
  final _createKeys = IdempotencyKeeper();
  final _settleKeys = IdempotencyKeeper();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_loansProvider(_status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'السلف والديون',
          subtitle: 'سلف وديون المشتركين وتسويتها.',
          leading: const Icon(
            Icons.handshake_outlined,
            color: AppTokens.brand,
          ),
          inlineActions: true,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh, color: AppTokens.textSecondary),
              onPressed: () => ref.invalidate(_loansProvider(_status)),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        AppCard(
          padding: const EdgeInsets.all(AppTokens.s12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
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
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: HubActionButton(
                  item: ActionItem(
                    icon: Icons.add_circle_outline,
                    label: 'تسجيل سلفة أو دين',
                    primary: true,
                    onPressed: _createLoan,
                  ),
                ),
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
          data: (loaded) {
            final items = loaded.list.items;
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
                _LoansSummary(items: items, totals: loaded.totals),
                const SizedBox(height: AppTokens.s12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          for (final loan in items) ...[
                            _LoanCard(loan: loan, onSettle: _settleLoan),
                            const SizedBox(height: AppTokens.s8),
                          ],
                        ],
                      );
                    }
                    return _LoansTable(items: items, onSettle: _settleLoan);
                  },
                ),
                LoadMoreFooter(
                  hasMore: loaded.list.hasMore,
                  loading: loaded.list.loadingMore,
                  error: loaded.list.loadMoreError,
                  shown: items.length,
                  total: loaded.list.total,
                  onLoadMore: () =>
                      ref.read(_loansProvider(_status).notifier).loadMore(),
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
    final currency = ref.read(tenantCurrencyProvider);
    final created = await _loanDialog(
      context,
      currency: currency,
      // «احتساب الدين من عدد الأيام»: the value the server will record,
      // from the subscriber's own price (a read, never a money call).
      estimate: (username, minutes) async {
        final c = await ref
            .read(subscriberActionsRepositoryProvider)
            .actionsContext(username);
        return priceForMinutes(
          effectivePrice: c.effectivePrice,
          planMinutes: c.planMinutes,
          minutes: minutes,
        );
      },
      // Runs INSIDE the dialog: an error keeps it open with every input
      // (it used to close and lose them behind a generic snackbar).
      submit: (draft) async {
        final key = _createKeys.keyFor('loan', draft.fingerprint);
        final outcome = await ref
            .read(accountingRepositoryProvider)
            .createLoanWithOutcome(
              username: draft.username,
              days: draft.days,
              hours: draft.hours,
              amount: draft.amount,
              currency: draft.currency,
              reason: draft.reason,
              priceFromDays: draft.priceFromDays,
              applyToRadius: draft.applyToRadius,
              idempotencyKey: key,
            );
        _createKeys.reset();
        return outcome;
      },
    );
    if (created == null) return;
    _refresh();
    if (!mounted) return;
    _snack(context, loanCreatedMessage(created));
  }

  Future<void> _settleLoan(LoanEntry loan) async {
    final settlement = await _settlementDialog(context, loan);
    if (settlement == null) return;
    final key = _settleKeys.keyFor('settle', {
      'id': loan.id,
      'a': settlement.amount,
      'm': settlement.method,
      'n': settlement.notes,
    });
    try {
      await ref.read(accountingRepositoryProvider).settleLoan(
            loanId: loan.id,
            amount: settlement.amount,
            method: settlement.method,
            notes: settlement.notes,
            idempotencyKey: key,
          );
      _settleKeys.reset();
      _refresh();
      if (!mounted) return;
      _snack(context, 'تمت تسوية السلفة رقم ${loan.id}');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorWithRetryHint(error));
    }
  }
}

class _LoansSummary extends StatelessWidget {
  const _LoansSummary({required this.items, this.totals});

  final List<LoanEntry> items;

  /// Server totals of the whole filter; null on older servers (then the
  /// loaded rows are summed, as before).
  final LoanTotals? totals;

  @override
  Widget build(BuildContext context) {
    final open = items.where((item) => item.status == 'open').toList();
    final debt = totals?.outstanding ??
        open.fold<num>(0, (sum, item) => sum + item.outstanding);
    final minutes =
        open.fold<int>(0, (sum, item) => sum + item.durationMinutes);
    return CountGrid(
      columns: 4,
      items: [
        CountItem('عدد السجلات', totals?.count ?? items.length),
        CountItem(
          'مفتوحة',
          totals?.openCount ?? open.length,
          tone: PillTone.amber,
        ),
        CountItem.text(
          'الدين المفتوح',
          // mixed currencies: one number per currency, never a sum
          (totals?.mixedCurrency ?? false) &&
                  totals!.outstandingByCurrency.isNotEmpty
              ? formatByCurrency(totals!.outstandingByCurrency)
              : _money(debt),
          tone: PillTone.red,
        ),
        CountItem.text(
          'مدة مفتوحة',
          _shortDuration(minutes),
          tone: PillTone.brand,
        ),
      ],
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
                  DataCell(Text(_loanAmountLabel(loan))),
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
    final reason = loan.reason.trim();
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTokens.brandSoft,
                  borderRadius: BorderRadius.circular(AppTokens.r10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.handshake_outlined,
                  color: AppTokens.brandInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.username.isEmpty
                          ? 'مشترك رقم ${loan.subscriberId}'
                          : loan.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTokens.sidebarBg,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'سجل رقم ${loan.id}',
                      style: const TextStyle(
                        color: AppTokens.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              StatusPill(
                text: loan.statusLabel,
                tone: _statusTone(loan.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          InfoGrid(
            items: [
              InfoItem(
                icon: Icons.schedule_outlined,
                label: 'المدة',
                value: _shortDuration(loan.durationMinutes),
              ),
              InfoItem(
                icon: Icons.payments_outlined,
                label: 'المبلغ',
                value: _loanAmountLabel(loan),
              ),
              InfoItem(
                icon: Icons.verified_outlined,
                label: 'الاعتماد',
                value: loan.approvalStatusLabel,
              ),
              InfoItem(
                icon: Icons.play_circle_outline,
                label: 'البداية',
                value: _fmtShort(loan.startsAt),
              ),
              InfoItem(
                icon: Icons.event_outlined,
                label: 'النهاية',
                value: _fmtShort(loan.endsAt),
              ),
              if (reason.isNotEmpty)
                InfoItem(
                  icon: Icons.notes_outlined,
                  label: 'السبب',
                  value: reason,
                ),
            ],
          ),
          if (loan.isOpen) ...[
            const SizedBox(height: AppTokens.s8),
            ActionBar(
              items: [
                ActionItem(
                  icon: Icons.done_all,
                  label: 'تسوية',
                  tone: PillTone.green,
                  onPressed: () => onSettle(loan),
                ),
              ],
            ),
          ],
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

  /// Same draft submitted again (a retry) → same Idempotency-Key.
  Map<String, Object> get fingerprint => {
        'c': currency,
        'u': username,
        'd': days,
        'h': hours,
        'a': amount,
        'r': reason,
        'p': priceFromDays,
        'x': applyToRadius,
      };
}

class _SettlementDraft {
  const _SettlementDraft({
    required this.amount,
    required this.method,
    required this.notes,
  });

  final num amount;
  final String method;
  final String notes;
}

/// The toast after POST /loans: the server's approval result and the amount
/// it actually recorded (computed by the server for «من عدد الأيام»).
String loanCreatedMessage(LoanCreateOutcome o) {
  if (o.pendingApproval) {
    return o.message.isNotEmpty
        ? o.message
        : 'بانتظار موافقة المالك — أُرسلت السلفة للاعتماد ولم تُسجَّل بعد.';
  }
  final l = o.loan;
  final what = l.amount > 0
      ? 'الدين ${_money(l.amount)} ${l.currency}'.trim()
      : 'السلفة';
  return 'تم تسجيل $what للمشترك ${l.username}';
}

Future<LoanCreateOutcome?> _loanDialog(
  BuildContext context, {
  required String currency,
  required Future<LoanCreateOutcome> Function(_LoanDraft draft) submit,
  Future<double> Function(String username, int minutes)? estimate,
}) async {
  final username = TextEditingController();
  final days = TextEditingController(text: '0');
  final hours = TextEditingController(text: '2');
  final amount = TextEditingController(text: '0');
  final reason = TextEditingController();
  var priceFromDays = false;
  // ON by default: a loan recorded without it gives debt with no time.
  var applyToRadius = true;
  // Same-frame guard: two taps before the first rebuild = one request.
  var submitting = false;
  var dryRun = true;
  // Supported codes (web settings list), the system currency first/default.
  var chosenCurrency = currency.isEmpty ? kDefaultCurrency : currency;
  final currencies = {
    chosenCurrency,
    ...kSupportedCurrencies,
  }.toList();
  String? error;
  String? preview;
  var busy = false;

  return showDialog<LoanCreateOutcome>(
    context: context,
    useRootNavigator: true,
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
                      child: NumberTextField(
                        controller: days,
                        decimal: false,
                        decoration: const InputDecoration(labelText: 'أيام'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: NumberTextField(
                        controller: hours,
                        decimal: false,
                        decoration: const InputDecoration(labelText: 'ساعات'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: NumberTextField(
                        controller: amount,
                        enabled: !priceFromDays,
                        extraError: (v) => v > kMaxMoneyAmount
                            ? 'المبلغ كبير جدًا — الحدّ الأعلى $kMaxMoneyAmountLabel.'
                            : null,
                        decoration: InputDecoration(
                          labelText: 'المبلغ',
                          helperText: priceFromDays
                              ? 'يحسبه الخادم من سعر باقة المشترك × المدة.'
                              : 'ضع 0 للسلفة المجانية أو مبلغًا لتسجيل دين.',
                          helperMaxLines: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    // A list of the supported codes, the system currency by
                    // default (free text saved «ST13 LOA» as a currency).
                    SizedBox(
                      width: 110,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: chosenCurrency,
                        decoration: const InputDecoration(labelText: 'العملة'),
                        items: [
                          for (final c in currencies)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(
                                  () => chosenCurrency = v ?? chosenCurrency,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'السبب'),
                ),
                const SizedBox(height: AppTokens.s4),
                HubSwitchRow(
                  dense: true,
                  value: priceFromDays,
                  onChanged: (value) => setState(() => priceFromDays = value),
                  label: 'احتساب الدين من عدد الأيام',
                  subtitle:
                      'استخدمها عندما تريد تسجيل دين طويل بناءً على سعر الباقة.',
                ),
                HubSwitchRow(
                  dense: true,
                  value: applyToRadius,
                  onChanged: (value) => setState(() => applyToRadius = value),
                  label: 'تطبيق المدة على الريدياس',
                  subtitle: applyToRadius
                      ? 'تُمنح المدّة للحساب فورًا.'
                      : 'مُطفأ: يُسجَّل الدين فقط دون تمديد فعلي.',
                ),
                HubSwitchRow(
                  dense: true,
                  value: dryRun,
                  onChanged: (value) => setState(() => dryRun = value),
                  label: 'تجربة آمنة (معاينة فقط)',
                  subtitle: 'تعرض ما سيُسجَّل دون تسجيل أي سلفة أو دين.',
                ),
                if (preview != null) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    preview!,
                    style: const TextStyle(
                      color: AppTokens.blueInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: AppTokens.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
            onPressed: busy
                ? null
                : () async {
                    if (submitting) return;
                    final user = username.text.trim();
                    final parsedDays = parseIntInput(days.text) ?? 0;
                    final parsedHours = parseIntInput(hours.text) ?? 0;
                    final parsedAmount = priceFromDays
                        ? 0
                        : (parseDecimalInput(amount.text) ?? 0);
                    final problem = validateLoanCenterInput(
                      username: user,
                      daysText: days.text,
                      hoursText: hours.text,
                      amountText: priceFromDays ? '0' : amount.text,
                      priceFromDays: priceFromDays,
                    );
                    if (problem != null) {
                      setState(() {
                        error = problem;
                        preview = null;
                      });
                      return;
                    }
                    final draft = _LoanDraft(
                      username: user,
                      days: parsedDays,
                      hours: parsedHours,
                      amount: parsedAmount,
                      currency: chosenCurrency,
                      reason: reason.text.trim(),
                      priceFromDays: priceFromDays,
                      applyToRadius: applyToRadius,
                      dryRun: dryRun,
                    );
                    if (dryRun) {
                      // «تجربة آمنة»: local only — the loans endpoint
                      // recorded a real loan for dry_run on older servers.
                      double? est;
                      if (priceFromDays && estimate != null) {
                        try {
                          est = await estimate(
                            user,
                            parsedDays * 1440 + parsedHours * 60,
                          );
                        } catch (_) {
                          est = null;
                        }
                      }
                      if (!context.mounted) return;
                      setState(() {
                        error = null;
                        preview = _loanCenterPreviewText(
                          draft,
                          chosenCurrency,
                          estimated: est,
                        );
                      });
                      return;
                    }
                    submitting = true;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      final outcome = await submit(draft);
                      if (context.mounted) Navigator.pop(context, outcome);
                    } catch (e) {
                      submitting = false;
                      if (!context.mounted) return;
                      setState(() {
                        busy = false;
                        error = visibleErrorWithRetryHint(e);
                      });
                    }
                  },
            child: Text(dryRun ? 'معاينة' : 'تسجيل'),
          ),
        ],
      ),
    ),
  );
}

/// Loans-center dialog guard on the typed text (Arabic): «-1» or «1e3» are
/// errors — they used to be stripped/rewritten into a real loan.
String? validateLoanCenterInput({
  required String username,
  required String daysText,
  required String hoursText,
  required String amountText,
  bool priceFromDays = false,
}) {
  final d = readNumberInput(daysText, decimal: false);
  if (d.error != null) return 'الأيام: ${d.error}';
  final h = readNumberInput(hoursText, decimal: false);
  if (h.error != null) return 'الساعات: ${h.error}';
  final a = readNumberInput(amountText);
  if (a.error != null) return 'المبلغ: ${a.error}';
  final days = (d.value ?? 0).toInt();
  final hours = (h.value ?? 0).toInt();
  if (username.trim().isEmpty) return 'أدخل اسم المشترك.';
  if (days <= 0 && hours <= 0) return 'أدخل مدة السلفة أو الدين.';
  final span = validateExtendSpan(days * 1440 + hours * 60);
  if (span != null) return span;
  if (priceFromDays && days <= 0) {
    return '«احتساب الدين من عدد الأيام» يحتاج عدد أيام.';
  }
  final amount = a.value ?? 0;
  if (amount > kMaxMoneyAmount) {
    return 'المبلغ كبير جدًا — الحدّ الأعلى $kMaxMoneyAmountLabel.';
  }
  return null;
}

/// Local text of the loans-center «تجربة آمنة» — nothing is sent.
String _loanCenterPreviewText(
  _LoanDraft d,
  String currency, {
  double? estimated,
}) {
  final span = [
    if (d.days > 0) '${d.days} يوم',
    if (d.hours > 0) '${d.hours} ساعة',
  ].join(' و ');
  final value = d.priceFromDays
      ? (estimated != null && estimated > 0
          ? 'دين محسوب من سعر الباقة ≈ ${_money(estimated)} $currency'.trim()
          : 'دين محسوب من سعر الباقة على الخادم')
      : d.amount > 0
          ? 'دين ${_money(d.amount)} ${currency.isEmpty ? '' : currency}'.trim()
          : 'سلفة مجانية';
  return 'معاينة فقط — لم يُسجَّل شيء: $span لـ ${d.username} ($value).';
}

String _loanAmountLabel(LoanEntry loan) {
  final base = '${_money(loan.amount)} ${loan.currency}'.trim();
  if (loan.isOpen && loan.outstanding > 0 && loan.outstanding < loan.amount) {
    return '$base (المتبقّي ${_money(loan.outstanding)})';
  }
  return base;
}

Future<_SettlementDraft?> _settlementDialog(
  BuildContext context,
  LoanEntry loan,
) {
  // Default = what is still owed (partial settles leave the rest open).
  final amount = TextEditingController(
    text: loan.outstanding.toStringAsFixed(2),
  );
  // A list with Arabic labels (the raw «manual» used to be typed/shown).
  var method = 'manual';
  final notes = TextEditingController();

  return showDialog<_SettlementDraft>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      title: const Text('تسوية سلفة أو دين'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NumberTextField(
              controller: amount,
              decoration: InputDecoration(
                labelText: loan.currency.isEmpty
                    ? 'المبلغ المستلم'
                    : 'المبلغ المستلم (${loan.currency})',
                helperText: 'المتبقّي: ${_money(loan.outstanding)}',
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: method,
              decoration: const InputDecoration(labelText: 'طريقة التسوية'),
              items: [
                for (final (v, label) in kPaymentMethods)
                  DropdownMenuItem(value: v, child: Text(label)),
              ],
              onChanged: (v) => method = v ?? 'manual',
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
            final read = readNumberInput(amount.text);
            if (read.error != null) {
              _snack(context, read.error!);
              return;
            }
            final parsedAmount = read.value ?? 0;
            final free = loan.amount <= 0;
            if (!free && parsedAmount <= 0) {
              _snack(context, 'أدخل مبلغ تسوية صحيح');
              return;
            }
            if (parsedAmount > loan.outstanding + 0.005) {
              _snack(
                context,
                'المبلغ يتجاوز المتبقّي على السلفة (${_money(loan.outstanding)}).',
              );
              return;
            }
            Navigator.pop(
              context,
              _SettlementDraft(
                amount: free ? 0 : parsedAmount,
                method: method,
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

/// Compact duration for counters and grid cells («26 ي 12 س»).
String _shortDuration(int minutes) {
  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  final mins = minutes % 60;
  final parts = <String>[
    if (days > 0) '$days ي',
    if (hours > 0) '$hours س',
    if (mins > 0 || (days == 0 && hours == 0)) '$mins د',
  ];
  return parts.join(' ');
}

/// Date for narrow grid cells: the year only when it is not this year.
String _fmtShort(DateTime? value) {
  if (value == null) return 'غير محدد';
  final local = value.toLocal();
  final pattern =
      local.year == panelNow().year ? 'MM-dd HH:mm' : 'yyyy-MM-dd';
  return DateFormat(pattern).format(local);
}

String _fmt(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}
