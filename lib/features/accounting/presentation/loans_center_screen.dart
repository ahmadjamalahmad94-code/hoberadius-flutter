import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/idempotency.dart';
import '../../../core/api/paging.dart';
import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/hub_switch_row.dart';
import '../../../shared/widgets/load_more_footer.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../admin_control/application/admin_control_providers.dart';
import '../../subscribers/domain/subscriber_actions_model.dart'
    show parseLocalizedNumber;
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
    final draft = await _loanDialog(context, currency: currency);
    if (draft == null) return;
    if (draft.dryRun) {
      // «تجربة آمنة»: a local preview only. The loans endpoint recorded a
      // real loan for dry_run on older servers.
      if (mounted) _snack(context, _loanCenterPreviewText(draft, currency));
      return;
    }
    final key = _createKeys.keyFor('loan', draft.fingerprint);
    try {
      final loan = await ref.read(accountingRepositoryProvider).createLoan(
            username: draft.username,
            days: draft.days,
            hours: draft.hours,
            amount: draft.amount,
            reason: draft.reason,
            priceFromDays: draft.priceFromDays,
            applyToRadius: draft.applyToRadius,
            idempotencyKey: key,
          );
      _createKeys.reset();
      _refresh();
      if (!mounted) return;
      _snack(
        context,
        'تم تسجيل ${loan.amount > 0 ? 'الدين' : 'السلفة'} للمشترك ${loan.username}',
      );
    } catch (error) {
      if (mounted) _snack(context, visibleErrorWithRetryHint(error));
    }
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
        CountItem.text('الدين المفتوح', _money(debt), tone: PillTone.red),
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

Future<_LoanDraft?> _loanDialog(
  BuildContext context, {
  required String currency,
}) async {
  final username = TextEditingController();
  final days = TextEditingController(text: '0');
  final hours = TextEditingController(text: '2');
  final amount = TextEditingController(text: '0');
  final reason = TextEditingController();
  var priceFromDays = false;
  var applyToRadius = false;
  var dryRun = true;

  return showDialog<_LoanDraft>(
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
                          helperMaxLines: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    // The server records loans in its system currency; a
                    // free-text currency field wrote «JOD» on ILS tenants.
                    SizedBox(
                      width: 96,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'العملة'),
                        child: Text(currency.isEmpty ? '—' : currency),
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
                  subtitle:
                      'أبقها مغلقة إذا كنت تسجل الدين فقط دون تمديد فعلي.',
                ),
                HubSwitchRow(
                  dense: true,
                  value: dryRun,
                  onChanged: (value) => setState(() => dryRun = value),
                  label: 'تجربة آمنة (معاينة فقط)',
                  subtitle: 'تعرض ما سيُسجَّل دون تسجيل أي سلفة أو دين.',
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
              final parsedAmount = parseLocalizedNumber(amount.text) ?? 0;
              if (user.isEmpty || (parsedDays <= 0 && parsedHours <= 0)) {
                _snack(context, 'أدخل اسم المشترك ومدة السلفة أو الدين');
                return;
              }
              if (parsedAmount < 0 || parsedAmount > kMaxMoneyAmount) {
                _snack(
                  context,
                  'المبلغ بين 0 و ${kMaxMoneyAmount.toStringAsFixed(0)}.',
                );
                return;
              }
              Navigator.pop(
                context,
                _LoanDraft(
                  username: user,
                  days: parsedDays,
                  hours: parsedHours,
                  amount: parsedAmount,
                  currency: currency,
                  reason: reason.text.trim(),
                  priceFromDays: priceFromDays,
                  applyToRadius: applyToRadius,
                  dryRun: dryRun,
                ),
              );
            },
            child: Text(dryRun ? 'معاينة' : 'تسجيل'),
          ),
        ],
      ),
    ),
  );
}

/// Local text of the loans-center «تجربة آمنة» — nothing is sent.
String _loanCenterPreviewText(_LoanDraft d, String currency) {
  final span = [
    if (d.days > 0) '${d.days} يوم',
    if (d.hours > 0) '${d.hours} ساعة',
  ].join(' و ');
  final value = d.priceFromDays
      ? 'دين محسوب من سعر الباقة'
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
  final amount = TextEditingController(text: _money(loan.outstanding));
  final method = TextEditingController(text: 'manual');
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
            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: loan.currency.isEmpty
                    ? 'المبلغ المستلم'
                    : 'المبلغ المستلم (${loan.currency})',
                helperText: 'المتبقّي: ${_money(loan.outstanding)}',
              ),
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
            final parsedAmount = parseLocalizedNumber(amount.text) ?? 0;
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
      local.year == DateTime.now().year ? 'MM-dd HH:mm' : 'yyyy-MM-dd';
  return DateFormat(pattern).format(local);
}

String _fmt(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}
