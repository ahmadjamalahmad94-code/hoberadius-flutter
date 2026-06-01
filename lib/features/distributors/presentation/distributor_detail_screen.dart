import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/empty_state.dart';
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
          Row(
            children: [
              Expanded(
                child: Text(
                  item.distributor.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTokens.sidebarBg,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.goNamed('distributors'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('كل الموزعين'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          _SummaryGrid(summary: item),
          const SizedBox(height: AppTokens.s16),
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
                    height: wide ? 0 : AppTokens.s16,
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
    return Wrap(
      spacing: AppTokens.s12,
      runSpacing: AppTokens.s12,
      children: [
        _Metric(label: 'حزم مربوطة', value: '${summary.assignedBatches}'),
        _Metric(label: 'الرصيد', value: summary.balance.toStringAsFixed(2)),
        _Metric(label: 'الدين', value: summary.debtBalance.toStringAsFixed(2)),
        _Metric(
          label: 'حد الائتمان',
          value: summary.creditLimit.toStringAsFixed(2),
        ),
        Card(
          child: SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(
                        text:
                            distributor.isActive
                                ? 'مفعّل'
                                : distributorStatusLabel(distributor.status),
                        tone: distributor.isActive
                            ? PillTone.green
                            : PillTone.orange,
                      ),
                      const Spacer(),
                      Text(
                        '@${distributor.name}',
                        style: const TextStyle(color: AppTokens.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final p in distributor.permissions.take(4))
                        StatusPill(
                          text: distributorPermissionLabel(p),
                          tone: PillTone.cyan,
                        ),
                      if (distributor.permissions.isEmpty)
                        const StatusPill(
                          text: 'صلاحيات غير محددة',
                          tone: PillTone.neutral,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTokens.sidebarBg,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppTokens.textMuted)),
            ],
          ),
        ),
      ),
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
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ربط حزمة كروت',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _batchId,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'رقم الحزمة',
                    helperText: 'استخدم رقم الحزمة الظاهر في شاشة الكروت.',
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: _assignNotes,
                  decoration: const InputDecoration(labelText: 'ملاحظة'),
                ),
                const SizedBox(height: AppTokens.s12),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _assign,
                  icon: const Icon(Icons.link),
                  label: const Text('ربط الحزمة'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تسوية يدوية',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                const SizedBox(height: AppTokens.s8),
                DropdownButtonFormField<String>(
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
                TextField(
                  controller: _settleNotes,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
                const SizedBox(height: AppTokens.s12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _settle,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('تسجيل الحركة'),
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
      _message('تعذر تنفيذ العملية: $e');
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
                          tone: PillTone.cyan,
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
