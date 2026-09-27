import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/form_field_row.dart';
import '../../../shared/widgets/hub_layout.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
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
            subtitle: '@${item.distributor.name}',
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
  bool _busy = false;

  @override
  void dispose() {
    _batchId.dispose();
    _assignNotes.dispose();
    _amount.dispose();
    _settleNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontWeight: FontWeight.w800,
      color: AppTokens.sidebarBg,
    );
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'رقم الحزمة'),
                  ),
                  second: TextField(
                    controller: _assignNotes,
                    decoration: const InputDecoration(labelText: 'ملاحظة'),
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                const Text(
                  'استخدم رقم الحزمة الظاهر في شاشة الكروت.',
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
                const SizedBox(height: AppTokens.s8),
                FormFieldPair(
                  first: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
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
    final id = int.tryParse(_batchId.text);
    if (id == null || id <= 0) {
      _message('اكتب رقم حزمة صحيح');
      return;
    }
    await _run(() async {
      await ref.read(distributorsRepositoryProvider).assignBatch(
            widget.distributorId,
            batchId: id,
            notes: _assignNotes.text.trim(),
          );
      _batchId.clear();
      _assignNotes.clear();
      _message('تم ربط الحزمة');
    });
  }

  Future<void> _settle() async {
    final amount = num.tryParse(_amount.text);
    if (amount == null || amount <= 0) {
      _message('اكتب مبلغًا صحيحًا');
      return;
    }
    await _run(() async {
      await ref.read(distributorsRepositoryProvider).settle(
            widget.distributorId,
            amount: amount,
            direction: _direction,
            notes: _settleNotes.text.trim(),
          );
      _amount.clear();
      _settleNotes.clear();
      _message('تم تسجيل الحركة');
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(distributorSummaryProvider(widget.distributorId));
      ref.invalidate(distributorBatchesProvider(widget.distributorId));
      ref.invalidate(distributorsListProvider);
    } catch (e) {
      _message(visibleErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
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
