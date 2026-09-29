import 'package:hoberadius_app/shared/widgets/number_text_field.dart';
import 'package:hoberadius_app/core/format/number_input.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/idempotency.dart';
import '../../../core/format/currency.dart';
import '../../../core/format/money_limits.dart';
import '../../cards/data/cards_repository.dart';
import '../data/distributors_repository.dart';
import '../domain/distributor_model.dart';
import 'distributors_list_screen.dart';

final distributorSummaryProvider =
    FutureProvider.autoDispose.family<DistributorSummary, int>((ref, id) {
  return ref.watch(distributorsRepositoryProvider).summary(id);
});

final distributorBatchesProvider =
    FutureProvider.autoDispose.family<List<DistributorBatch>, int>((ref, id) {
  return ref.watch(distributorsRepositoryProvider).batches(id);
});

class DistributorDetailScreen extends ConsumerWidget {
  const DistributorDetailScreen({super.key, required this.distributorId});

  final int distributorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(distributorSummaryProvider(distributorId));
    final batches = ref.watch(distributorBatchesProvider(distributorId));
    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'تعذر جلب الموزع',
        subtitle: visibleErrorMessage(e),
        action: OutlinedButton.icon(
          onPressed: () =>
              ref.invalidate(distributorSummaryProvider(distributorId)),
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      ),
      data: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: item.distributor.title,
            subtitle: ltrIsolate('@${item.distributor.name}'),
            inlineActions: true,
            leading: IconButton(
              tooltip: 'كل الموزعين',
              onPressed: () => context.goNamed('distributors'),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: () {
                  ref.invalidate(distributorSummaryProvider(distributorId));
                  ref.invalidate(distributorBatchesProvider(distributorId));
                },
                icon: const Icon(
                  Icons.refresh,
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _SummaryGrid(summary: item),
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              final batchesWidget = _Batches(
                async: batches,
                distributorId: distributorId,
              );
              return Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: wide ? 360 : double.infinity,
                    child: _Actions(distributorId: distributorId),
                  ),
                  SizedBox(
                    width: wide ? AppTokens.s16 : 0,
                    height: wide ? 0 : AppTokens.s12,
                  ),
                  if (wide)
                    Expanded(child: batchesWidget)
                  else
                    SizedBox(width: double.infinity, child: batchesWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final DistributorSummary summary;

  @override
  Widget build(BuildContext context) {
    final distributor = summary.distributor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            StatusPill(
              text: distributor.isActive
                  ? 'مفعّل'
                  : distributorStatusLabel(distributor.status),
              tone: distributorStatusTone(distributor),
              dot: true,
            ),
            for (final p in distributor.permissions.take(4))
              StatusPill(
                text: distributorPermissionLabel(p),
                tone: PillTone.blue,
              ),
            if (distributor.permissions.isEmpty)
              const StatusPill(
                text: 'صلاحيات غير محددة',
                tone: PillTone.neutral,
              ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        // Four tight counters instead of four half-empty KPI cards.
        CountGrid(
          columns: 4,
          items: [
            CountItem(
              'حزم مربوطة',
              summary.assignedBatches,
              tone: PillTone.brand,
            ),
            CountItem.text(
              'الرصيد',
              summary.balance.toStringAsFixed(2),
              tone: PillTone.green,
            ),
            CountItem.text(
              'الدين',
              summary.debtBalance.toStringAsFixed(2),
              tone: summary.debtBalance > 0 ? PillTone.amber : PillTone.neutral,
            ),
            CountItem.text(
              'حد الائتمان',
              summary.creditLimit.toStringAsFixed(2),
              tone: PillTone.blue,
            ),
          ],
        ),
      ],
    );
  }
}

class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.distributorId});

  final int distributorId;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  final _batchId = TextEditingController();
  final _assignNotes = TextEditingController();
  final _amount = TextEditingController();
  final _settleNotes = TextEditingController();
  String _direction = 'credit';

  /// «إضافة للرصيد» / «خصم من الدين» — null until the admin picks (the
  /// default follows the debt: debt > 0 → «خصم من الدين»).
  String? _applyTo;
  bool _busy = false;

  /// Same-click guard: set synchronously, so two or three taps landing in
  /// the same frame (before `_busy` rebuilds the button) post ONE movement
  /// (r11 M-1: 3 taps → 3 entries).
  bool _submitting = false;
  final _idem = IdempotencyKeeper();

  @override
  void dispose() {
    _batchId.dispose();
    _assignNotes.dispose();
    _amount.dispose();
    _settleNotes.dispose();
    super.dispose();
  }

  /// Owner rule: default «خصم من الدين» when the distributor owes, else
  /// «إضافة للرصيد»; an explicit choice wins.
  String _effectiveApplyTo(DistributorSummary? summary) =>
      _applyTo ?? ((summary?.debtBalance ?? 0) > 0 ? 'debt' : 'balance');

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontWeight: FontWeight.w800,
      color: AppTokens.sidebarBg,
    );
    final summary =
        ref.watch(distributorSummaryProvider(widget.distributorId)).valueOrNull;
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ربط حزمة كروت', style: titleStyle),
                const SizedBox(height: AppTokens.s8),
                FormFieldPair(
                  first: TextField(
                    controller: _batchId,
                    decoration: const InputDecoration(
                      labelText: 'رقم أو كود الحزمة',
                      hintText: 'B-20260928-0052 أو 63',
                    ),
                  ),
                  second: TextField(
                    controller: _assignNotes,
                    decoration: const InputDecoration(labelText: 'ملاحظة'),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                const Text(
                  'اكتب كود الحزمة الظاهر في شاشة الكروت (B-…) أو رقمها.',
                  style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
                ),
                const SizedBox(height: AppTokens.s8),
                HubActionButton(
                  item: ActionItem(
                    icon: Icons.link,
                    label: 'ربط الحزمة',
                    primary: true,
                    onPressed: _busy ? null : _assign,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('تسوية يدوية', style: titleStyle),
                const SizedBox(height: AppTokens.s8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _direction,
                  decoration: const InputDecoration(labelText: 'الاتجاه'),
                  items: const [
                    DropdownMenuItem(
                      value: 'credit',
                      child: Text('تسديد / إنقاص الدين'),
                    ),
                    DropdownMenuItem(value: 'debit', child: Text('إضافة دين')),
                  ],
                  onChanged: (v) => setState(() => _direction = v ?? 'credit'),
                ),
                if (_direction == 'credit') ...[
                  const SizedBox(height: AppTokens.s8),
                  _PaymentTarget(
                    summary: summary,
                    value: _effectiveApplyTo(summary),
                    onChanged: (v) => setState(() => _applyTo = v),
                  ),
                ],
                const SizedBox(height: AppTokens.s8),
                FormFieldPair(
                  first: NumberTextField(
                    controller: _amount,
                    extraError: (v) => validateMoneyAmount(v),
                    decoration: const InputDecoration(labelText: 'المبلغ'),
                  ),
                  second: TextField(
                    controller: _settleNotes,
                    decoration: const InputDecoration(labelText: 'ملاحظات'),
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                HubActionButton(
                  item: ActionItem(
                    icon: Icons.receipt_long,
                    label: 'تسجيل الحركة',
                    primary: true,
                    onPressed: _busy ? null : _settle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _assign() async {
    final raw = _batchId.text.trim();
    if (raw.isEmpty) {
      _message('اكتب كود الحزمة أو رقمها');
      return;
    }
    await _run(() async {
      // The operator sees the batch CODE (B-YYYYMMDD-NNNN), not the internal
      // id the endpoint needs — resolve it through the batches search.
      final id = await resolveBatchId(ref.read(cardsRepositoryProvider), raw);
      if (id == null) {
        throw ApiException(
          code: 'not_found',
          message: 'لم يتم العثور على حزمة بالكود أو الرقم «$raw».',
          status: 404,
        );
      }
      await ref.read(distributorsRepositoryProvider).assignBatch(
            widget.distributorId,
            batchId: id,
            batchCode: int.tryParse(raw) == null ? raw : null,
            notes: _assignNotes.text.trim(),
          );
      _batchId.clear();
      _assignNotes.clear();
      _message('تم ربط الحزمة');
    });
  }

  Future<void> _settle() async {
    if (_submitting) return;
    final read = readNumberInput(_amount.text);
    final amount = read.value?.toDouble();
    final problem = read.error ?? validateMoneyAmount(amount);
    if (problem != null) {
      _message(problem);
      return;
    }
    final summary =
        ref.read(distributorSummaryProvider(widget.distributorId)).valueOrNull;
    final applyTo = _direction == 'credit' ? _effectiveApplyTo(summary) : null;
    final debt = summary?.debtBalance ?? 0;
    if (applyTo == 'debt' && amount! > debt + 0.005) {
      _message(
        'المبلغ أكبر من الدين المستحقّ على الموزّع '
        '(المتبقّي ${formatWithCurrency(debt, '')}). '
        'اختر «إضافة للرصيد» للزيادة.',
      );
      return;
    }
    final body = {
      'a': amount,
      'd': _direction,
      't': applyTo,
      'n': _settleNotes.text.trim(),
    };
    // One Idempotency-Key per submission: a retry of the same body reuses
    // it, the server answers the first result instead of a second entry.
    final key = _idem.keyFor('distributor-settle', body);
    await _run(() async {
      await ref.read(distributorsRepositoryProvider).settle(
            widget.distributorId,
            amount: amount!,
            direction: _direction,
            applyTo: applyTo,
            notes: _settleNotes.text.trim(),
            idempotencyKey: key,
          );
      _idem.reset();
      _amount.clear();
      _settleNotes.clear();
      setState(() => _applyTo = null);
      _message('تم تسجيل الحركة');
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_submitting) return;
    _submitting = true;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(distributorSummaryProvider(widget.distributorId));
      ref.invalidate(distributorBatchesProvider(widget.distributorId));
      ref.invalidate(distributorsListProvider);
    } catch (e) {
      _message(visibleErrorWithRetryHint(e));
    } finally {
      _submitting = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// «إضافة للرصيد» / «خصم من الدين» with the current balance and debt beside
/// them (owner rule: a payment has ONE effect, chosen here).
class _PaymentTarget extends StatelessWidget {
  const _PaymentTarget({
    required this.summary,
    required this.value,
    required this.onChanged,
  });

  final DistributorSummary? summary;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final balance = summary?.balance ?? 0;
    final debt = summary?.debtBalance ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'balance',
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text('إضافة للرصيد (${formatWithCurrency(balance, '')})'),
            ),
            ButtonSegment(
              value: 'debt',
              icon: const Icon(Icons.remove_circle_outline),
              label: Text('خصم من الدين (${formatWithCurrency(debt, '')})'),
              enabled: debt > 0,
            ),
          ],
          selected: {value},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          value == 'debt'
              ? 'تُخصم الدفعة من دين الموزّع فقط (لا تتجاوز الدين المتبقّي).'
              : 'تُضاف الدفعة إلى رصيد الموزّع فقط.',
          style: const TextStyle(color: AppTokens.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

/// A batch CODE («B-20260928-0052») or an internal id → the batch id.
Future<int?> resolveBatchId(CardsRepository cards, String raw) async {
  final text = raw.trim();
  final asId = int.tryParse(text);
  if (asId != null && asId > 0) return asId;
  // `code=` is an exact lookup on updated servers; `q=` keeps older ones
  // working (the exact code is then picked from the matches).
  final page =
      await cards.listBatchOperations(code: text, query: text, perPage: 25);
  for (final b in page.items) {
    if (b.batchCode.trim().toLowerCase() == text.toLowerCase()) return b.id;
  }
  return null;
}

class _Batches extends StatelessWidget {
  const _Batches({required this.async, required this.distributorId});

  final AsyncValue<List<DistributorBatch>> async;
  final int distributorId;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.s32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'تعذر جلب الحزم',
        subtitle: visibleErrorMessage(e),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد حزم مربوطة',
            subtitle: 'اربط حزمة كروت من صندوق الربط حتى تظهر هنا.',
          );
        }
        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('الحزمة')),
                DataColumn(label: Text('العدد')),
                DataColumn(label: Text('المتاح')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('تاريخ الربط')),
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    cells: [
                      DataCell(Text(item.batchCode)),
                      DataCell(Text('${item.count}')),
                      DataCell(Text('${item.available}')),
                      DataCell(
                        StatusPill(
                          text: distributorStatusLabel(item.status),
                          tone: toneForStatus(item.status),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.assignedAt.isEmpty ? '—' : item.assignedAt,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
