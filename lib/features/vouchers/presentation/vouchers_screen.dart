import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/visible_error_message.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../plans/data/plans_repository.dart';
import '../../plans/domain/plan_model.dart';
import '../data/vouchers_repository.dart';
import '../domain/voucher_model.dart';

const _statusOptions = [
  (value: '', label: 'كل الحالات'),
  (value: 'active', label: 'نشطة'),
  (value: 'used', label: 'مستخدمة'),
  (value: 'revoked', label: 'ملغاة'),
  (value: 'expired', label: 'منتهية'),
];

final _vouchersProvider =
    FutureProvider.autoDispose.family<VoucherPage, String>((ref, status) {
  return ref.watch(vouchersRepositoryProvider).list(status: status);
});

final _plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

class VouchersScreen extends ConsumerStatefulWidget {
  const VouchersScreen({super.key});

  @override
  ConsumerState<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends ConsumerState<VouchersScreen> {
  String _status = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_vouchersProvider(_status));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'الكوبونات',
          subtitle:
              'توليد كوبونات الشحن، متابعة حالتها، وإلغاء الكوبونات النشطة من نفس عقد الويب.',
          leading: const Icon(
            Icons.confirmation_number_outlined,
            color: AppTokens.brand,
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(_vouchersProvider(_status)),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
            FilledButton.icon(
              onPressed: _generateVouchers,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('توليد كوبونات'),
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
            title: 'تعذر تحميل الكوبونات',
            subtitle: visibleErrorMessage(error),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'لا توجد كوبونات بهذه الفلترة',
                subtitle: _status.isEmpty
                    ? 'ولّد دفعة جديدة ليتم استخدامها في الشحن أو الربط مع باقة محددة.'
                    : 'غيّر الفلتر أو ولّد دفعة جديدة إذا كنت تحتاج كوبونات جاهزة.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VoucherStatsGrid(stats: page.stats, visibleCount: page.count),
                const SizedBox(height: AppTokens.s12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 880) {
                      return Column(
                        children: [
                          for (final voucher in page.items) ...[
                            _VoucherCard(
                              voucher: voucher,
                              onRevoke: _revokeVoucher,
                            ),
                            const SizedBox(height: AppTokens.s12),
                          ],
                        ],
                      );
                    }
                    return _VouchersTable(
                      items: page.items,
                      onRevoke: _revokeVoucher,
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

  void _refresh() {
    ref.invalidate(_vouchersProvider(_status));
  }

  Future<void> _generateVouchers() async {
    final plans = await ref.read(_plansProvider.future).catchError(
          (_) => <Plan>[],
        );
    if (!mounted) return;
    final draft = await _voucherDialog(context, plans: plans);
    if (draft == null) return;
    try {
      final result = await ref.read(vouchersRepositoryProvider).generate(draft);
      _refresh();
      if (!mounted) return;
      _snack(context, 'تم توليد ${result.count} كوبون بنجاح');
      await _showGeneratedVouchers(context, result.items);
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    }
  }

  Future<void> _revokeVoucher(VoucherRecord voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء كوبون'),
        content: Text(
          'هل تريد إلغاء الكوبون ${voucher.code}؟ لن يعود متاحًا للاستخدام بعد ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إلغاء الكوبون'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(vouchersRepositoryProvider).revoke(voucher.id);
      _refresh();
      if (!mounted) return;
      _snack(context, 'تم إلغاء الكوبون ${voucher.code}');
    } catch (error) {
      if (mounted) _snack(context, visibleErrorMessage(error));
    }
  }
}

class _VoucherStatsGrid extends StatelessWidget {
  const _VoucherStatsGrid({required this.stats, required this.visibleCount});

  final VoucherStats stats;
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
          childAspectRatio: constraints.maxWidth < 720 ? 2.3 : 2.8,
          children: [
            _StatCard(
              icon: Icons.savings_outlined,
              title: 'القيمة الإجمالية',
              value: _money(stats.totalAmount),
              tone: PillTone.green,
            ),
            _StatCard(
              icon: Icons.confirmation_number_outlined,
              title: 'نشطة',
              value: '${stats.active}',
              tone: PillTone.brand,
            ),
            _StatCard(
              icon: Icons.check_circle_outline,
              title: 'مستخدمة',
              value: '${stats.used}',
              tone: PillTone.blue,
            ),
            _StatCard(
              icon: Icons.filter_list,
              title: 'المعروضة',
              value: '$visibleCount من ${stats.totalCount}',
              tone: PillTone.amber,
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

class _VouchersTable extends StatelessWidget {
  const _VouchersTable({required this.items, required this.onRevoke});

  final List<VoucherRecord> items;
  final Future<void> Function(VoucherRecord voucher) onRevoke;

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
            DataColumn(label: Text('الكود')),
            DataColumn(label: Text('القيمة')),
            DataColumn(label: Text('الباقة')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('تنتهي في')),
            DataColumn(label: Text('أُنشئت في')),
            DataColumn(label: Text('الإجراء')),
          ],
          rows: [
            for (final voucher in items)
              DataRow(
                cells: [
                  DataCell(Text('${voucher.id}')),
                  DataCell(
                    SelectableText(
                      voucher.code,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  DataCell(Text(_money(voucher.amount))),
                  DataCell(Text(voucher.planLabel)),
                  DataCell(
                    StatusPill(
                      text: voucher.statusLabel,
                      tone: _statusTone(voucher.status),
                      dot: true,
                    ),
                  ),
                  DataCell(Text(_fmt(voucher.expireAt))),
                  DataCell(Text(_fmt(voucher.createdAt))),
                  DataCell(
                    voucher.canRevoke
                        ? TextButton.icon(
                            onPressed: () => onRevoke(voucher),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('إلغاء'),
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

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.voucher, required this.onRevoke});

  final VoucherRecord voucher;
  final Future<void> Function(VoucherRecord voucher) onRevoke;

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
                  Icons.confirmation_number_outlined,
                  color: AppTokens.brandInk,
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      voucher.code,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTokens.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'كوبون رقم ${voucher.id}',
                      style: const TextStyle(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusPill(
                text: voucher.statusLabel,
                tone: _statusTone(voucher.status),
                dot: true,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          _InfoLine(label: 'القيمة', value: _money(voucher.amount)),
          _InfoLine(label: 'الباقة', value: voucher.planLabel),
          _InfoLine(label: 'تنتهي في', value: _fmt(voucher.expireAt)),
          _InfoLine(label: 'أُنشئت في', value: _fmt(voucher.createdAt)),
          if (voucher.usedBySubscriberId != null)
            _InfoLine(
              label: 'استخدمه مشترك',
              value: 'مشترك رقم ${voucher.usedBySubscriberId}',
            ),
          const SizedBox(height: AppTokens.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _copyVoucher(context, voucher.code),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('نسخ'),
              ),
              const SizedBox(width: AppTokens.s8),
              if (voucher.canRevoke)
                TextButton.icon(
                  onPressed: () => onRevoke(voucher),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('إلغاء'),
                ),
            ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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

Future<VoucherGenerateDraft?> _voucherDialog(
  BuildContext context, {
  required List<Plan> plans,
}) async {
  final amount = TextEditingController(text: '5');
  final count = TextEditingController(text: '20');
  int? planId;
  DateTime? expireAt;

  return showDialog<VoucherGenerateDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('توليد كوبونات'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: count,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الكوبونات',
                  helperText: 'اختر عددًا بين 1 و 1000.',
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'القيمة لكل كوبون',
                  helperText: 'يجب أن تكون القيمة أكبر من صفر.',
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              DropdownButtonFormField<int?>(
                initialValue: planId,
                decoration: const InputDecoration(labelText: 'الباقة'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('بدون ربط بباقة'),
                  ),
                  for (final plan in plans.where((plan) => plan.id != null))
                    DropdownMenuItem<int?>(
                      value: plan.id,
                      child: Text(plan.name),
                    ),
                ],
                onChanged: (value) => setState(() => planId = value),
              ),
              const SizedBox(height: AppTokens.s8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    initialDate: expireAt ??
                        DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setState(() => expireAt = picked);
                },
                icon: const Icon(Icons.event),
                label: Text(
                  expireAt == null
                      ? 'تحديد تاريخ الانتهاء'
                      : 'تنتهي في ${_fmtDate(expireAt)}',
                ),
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
                  double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
              final parsedCount = int.tryParse(count.text.trim()) ?? 0;
              if (parsedAmount <= 0 || parsedCount <= 0) {
                _snack(context, 'أدخل عددًا وقيمة صحيحة قبل التوليد');
                return;
              }
              Navigator.pop(
                context,
                VoucherGenerateDraft(
                  amount: parsedAmount,
                  count: parsedCount,
                  planId: planId,
                  expireAt: expireAt,
                ),
              );
            },
            child: const Text('توليد'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showGeneratedVouchers(
  BuildContext context,
  List<VoucherRecord> items,
) {
  final codes = items.map((item) => item.code).join('\n');
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('الكوبونات الجديدة'),
      content: SizedBox(
        width: 520,
        child: items.isEmpty
            ? const Text('تم تنفيذ الطلب، ولا توجد أكواد لعرضها.')
            : SingleChildScrollView(
                child: SelectableText(codes),
              ),
      ),
      actions: [
        TextButton(
          onPressed: items.isEmpty ? null : () => _copyVoucher(context, codes),
          child: const Text('نسخ الكل'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تم'),
        ),
      ],
    ),
  );
}

void _copyVoucher(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  _snack(context, 'تم النسخ');
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

PillTone _statusTone(String status) {
  return switch (status) {
    'active' => PillTone.green,
    'used' => PillTone.blue,
    'revoked' => PillTone.red,
    'expired' => PillTone.amber,
    _ => PillTone.neutral,
  };
}

String _money(num value) {
  return NumberFormat('#,##0.##').format(value);
}

String _fmt(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}

String _fmtDate(DateTime? value) {
  if (value == null) return 'غير محدد';
  return DateFormat('yyyy-MM-dd').format(value.toLocal());
}
