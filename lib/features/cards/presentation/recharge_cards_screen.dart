import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/hub_error_state.dart';
import '../../../shared/widgets/hub_skeleton_loader.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_pill.dart';
import '../application/recharge_cards_providers.dart';
import '../data/cards_repository.dart';
import '../domain/card_model.dart';

class RechargeCardsScreen extends ConsumerStatefulWidget {
  const RechargeCardsScreen({super.key});

  @override
  ConsumerState<RechargeCardsScreen> createState() =>
      _RechargeCardsScreenState();
}

class _RechargeCardsScreenState extends ConsumerState<RechargeCardsScreen> {
  final _packageName = TextEditingController();
  final _notes = TextEditingController();
  final List<_DenomDraft> _denoms = [
    _DenomDraft(value: '5', count: ''),
    _DenomDraft(value: '10', count: ''),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _packageName.dispose();
    _notes.dispose();
    for (final denom in _denoms) {
      denom.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(rechargeBatchesProvider);
    final filters = ref.watch(rechargeCardsFiltersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'كروت الشحن',
          subtitle:
              'توليد كروت رصيد للمحفظة يستخدمها صاحب بطاقة العميل من بوابة الكروت، بدون منح صلاحية دخول إنترنت مباشرة.',
          leading: const _HeaderIcon(),
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(rechargeBatchesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _CreateRechargeCard(
          packageName: _packageName,
          notes: _notes,
          denoms: _denoms,
          saving: _saving,
          onAddDenom: _addDenomination,
          onRemoveDenom: _removeDenomination,
          onSubmit: _createBatch,
        ),
        const SizedBox(height: AppTokens.s16),
        async.when(
          loading: () => AppCard(child: HubSkeletonLoader.list(count: 5)),
          error: (e, _) => HubErrorState(
            title: 'تعذّر جلب حزم الشحن',
            subtitle: visibleErrorMessage(e),
            showToastOnce: true,
            onRetry: () => ref.invalidate(rechargeBatchesProvider),
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return const EmptyState(
                icon: Icons.add_card_outlined,
                title: 'لا توجد حزم شحن بعد',
                subtitle:
                    'أنشئ أول حزمة شحن بفئات وقيم واضحة، ثم اطبعها أو سلّمها للعملاء حسب آلية البيع لديك.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RechargeSummary(page: page),
                const SizedBox(height: AppTokens.s12),
                AppCard(
                  title: 'حزم الشحن الحالية',
                  icon: Icons.inventory_2_outlined,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final batch in page.items)
                        _RechargeBatchRow(
                          batch: batch,
                          onOpen: () => _openBatch(batch),
                          onDelete: () => _deleteBatch(batch),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                _RechargePagination(page: page, filters: filters),
              ],
            );
          },
        ),
      ],
    );
  }

  void _addDenomination() {
    setState(() => _denoms.add(_DenomDraft(value: '', count: '')));
  }

  void _removeDenomination(_DenomDraft denom) {
    if (_denoms.length == 1) return;
    setState(() {
      _denoms.remove(denom);
      denom.dispose();
    });
  }

  Future<void> _createBatch() async {
    final packageName = _packageName.text.trim();
    final denominations = <RechargeDenomination>[];
    for (final item in _denoms) {
      final value = num.tryParse(item.value.text.trim());
      final count = int.tryParse(item.count.text.trim());
      if (value != null && count != null && value > 0 && count > 0) {
        denominations.add(RechargeDenomination(value: value, count: count));
      }
    }
    if (packageName.isEmpty || denominations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('اكتب اسم الحزمة وأدخل فئة واحدة على الأقل بقيمة وعدد.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result =
          await ref.read(cardsRepositoryProvider).createRechargeBatch(
                CreateRechargeBatchRequest(
                  packageName: packageName,
                  notes: _notes.text.trim(),
                  denominations: denominations,
                ),
              );
      ref.invalidate(rechargeBatchesProvider);
      if (!mounted) return;
      _packageName.clear();
      _notes.clear();
      for (final item in _denoms) {
        item.count.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم توليد ${result.insertedCount} كرت شحن بقيمة إجمالية ${_money(result.totalValue)}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openBatch(RechargeBatch batch) async {
    final id = batch.id;
    if (id == null) return;
    try {
      final detail =
          await ref.read(cardsRepositoryProvider).getRechargeBatch(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _RechargeDetailDialog(detail: detail),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    }
  }

  Future<void> _deleteBatch(RechargeBatch batch) async {
    final id = batch.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف حزمة الشحن'),
        content: Text(
          'سيتم نقل حزمة "${batch.displayName}" إلى الأرشيف ولن تظهر في قائمة كروت الشحن.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(cardsRepositoryProvider).deleteRechargeBatch(id);
      ref.invalidate(rechargeBatchesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف حزمة الشحن.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibleErrorMessage(error))),
      );
    }
  }
}

class _CreateRechargeCard extends StatelessWidget {
  const _CreateRechargeCard({
    required this.packageName,
    required this.notes,
    required this.denoms,
    required this.saving,
    required this.onAddDenom,
    required this.onRemoveDenom,
    required this.onSubmit,
  });

  final TextEditingController packageName;
  final TextEditingController notes;
  final List<_DenomDraft> denoms;
  final bool saving;
  final VoidCallback onAddDenom;
  final ValueChanged<_DenomDraft> onRemoveDenom;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'توليد حزمة شحن جديدة',
      icon: Icons.add_card_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s12,
            runSpacing: AppTokens.s12,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: packageName,
                  decoration: const InputDecoration(
                    labelText: 'اسم الحزمة',
                    hintText: 'مثال: شحن رمضان',
                  ),
                ),
              ),
              SizedBox(
                width: 360,
                child: TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات داخلية',
                    hintText: 'اختياري',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            'الفئات',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTokens.textPrimary,
                ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final denom in denoms) ...[
            _DenominationRow(
              draft: denom,
              canRemove: denoms.length > 1,
              onRemove: () => onRemoveDenom(denom),
            ),
            const SizedBox(height: AppTokens.s8),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: onAddDenom,
              icon: const Icon(Icons.add),
              label: const Text('إضافة فئة'),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: saving ? null : onSubmit,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flash_on_outlined),
              label: Text(saving ? 'جارٍ التوليد' : 'توليد حزمة الشحن'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DenominationRow extends StatelessWidget {
  const _DenominationRow({
    required this.draft,
    required this.canRemove,
    required this.onRemove,
  });

  final _DenomDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 160,
          child: TextField(
            controller: draft.value,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'قيمة الشحن'),
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: draft.count,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'عدد الكروت'),
          ),
        ),
        IconButton(
          onPressed: canRemove ? onRemove : null,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: 'حذف الفئة',
        ),
      ],
    );
  }
}

class _RechargeSummary extends StatelessWidget {
  const _RechargeSummary({required this.page});

  final RechargeBatchesPage page;

  @override
  Widget build(BuildContext context) {
    final cards = page.items.fold<int>(0, (sum, item) => sum + item.count);
    final value = page.items.fold<num>(0, (sum, item) => sum + item.totalValue);
    return Wrap(
      spacing: AppTokens.s12,
      runSpacing: AppTokens.s12,
      children: [
        _MetricCard(label: 'الحزم', value: '${page.total}'),
        _MetricCard(label: 'الكروت في الصفحة', value: '$cards'),
        _MetricCard(label: 'قيمة الصفحة', value: _money(value)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: AppCard(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTokens.textMuted)),
            const SizedBox(height: AppTokens.s4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTokens.sidebarBg,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RechargeBatchRow extends StatelessWidget {
  const _RechargeBatchRow({
    required this.batch,
    required this.onOpen,
    required this.onDelete,
  });

  final RechargeBatch batch;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final denominations = batch.denominations
        .map((item) => '${_money(item.value)} × ${item.count}')
        .join('، ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final main = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          batch.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTokens.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      StatusPill(
                        text: batch.usedCount > 0 ? 'مستخدمة جزئيًا' : 'جاهزة',
                        tone: batch.usedCount > 0
                            ? PillTone.amber
                            : PillTone.green,
                        dot: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    denominations.isEmpty
                        ? 'لا توجد فئات محفوظة'
                        : denominations,
                    style: const TextStyle(color: AppTokens.textSecondary),
                  ),
                ],
              );
              final stats = Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  _TinyStat('الكروت', '${batch.count}'),
                  _TinyStat('المتبقي', '${batch.remainingCount}'),
                  _TinyStat('القيمة', _money(batch.totalValue)),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'حذف الحزمة',
                  ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    main,
                    const SizedBox(height: AppTokens.s12),
                    stats,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: main),
                  const SizedBox(width: AppTokens.s16),
                  stats,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r8),
        border: Border.all(color: AppTokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: AppTokens.textMuted)),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RechargeDetailDialog extends StatelessWidget {
  const _RechargeDetailDialog({required this.detail});

  final RechargeBatchDetail detail;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(detail.batch.displayName),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                children: [
                  _TinyStat('عدد الكروت', '${detail.totalCards}'),
                  _TinyStat('قيمة الحزمة', _money(detail.batch.totalValue)),
                  _TinyStat('المستخدم', '${detail.batch.usedCount}'),
                ],
              ),
              const SizedBox(height: AppTokens.s16),
              for (final card in detail.cards.take(25))
                ListTile(
                  dense: true,
                  leading: StatusPill(
                    text: card.used ? 'مستخدم' : 'متاح',
                    tone: card.used ? PillTone.amber : PillTone.green,
                  ),
                  title: Text(card.username),
                  subtitle: Text('كلمة المرور: ${card.password}'),
                  trailing: Text(
                    _money(card.walletValue),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              if (detail.totalCards > detail.cards.length)
                const Padding(
                  padding: EdgeInsets.only(top: AppTokens.s8),
                  child: Text(
                    'تم عرض أول البطاقات فقط. استخدم قوالب الطباعة لتصدير الحزمة كاملة.',
                    style: TextStyle(color: AppTokens.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTokens.brandSoft,
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.add_card_outlined, color: AppTokens.brand),
    );
  }
}

class _DenomDraft {
  _DenomDraft({required String value, required String count})
      : value = TextEditingController(text: value),
        count = TextEditingController(text: count);

  final TextEditingController value;
  final TextEditingController count;

  void dispose() {
    value.dispose();
    count.dispose();
  }
}

class _RechargePagination extends ConsumerWidget {
  const _RechargePagination({required this.page, required this.filters});

  final RechargeBatchesPage page;
  final RechargeCardsFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          'صفحة ${page.page} من ${page.pages} • ${page.total} حزمة',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: filters.perPage,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
            DropdownMenuItem(value: 100, child: Text('100')),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref.read(rechargeCardsFiltersProvider.notifier).state =
                filters.copyWith(page: 1, perPage: value);
          },
        ),
        IconButton(
          tooltip: 'السابق',
          onPressed: page.page <= 1
              ? null
              : () {
                  ref.read(rechargeCardsFiltersProvider.notifier).state =
                      filters.copyWith(page: page.page - 1);
                },
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'التالي',
          onPressed: page.page >= page.pages
              ? null
              : () {
                  ref.read(rechargeCardsFiltersProvider.notifier).state =
                      filters.copyWith(page: page.page + 1);
                },
          icon: const Icon(Icons.chevron_left),
        ),
      ],
    );
  }
}

String _money(num value) {
  final text =
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  return '$text ₪';
}
