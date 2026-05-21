import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/lifecycle_repository.dart';
import '../domain/lifecycle_model.dart';

final lifecyclePoliciesProvider =
    FutureProvider.autoDispose<List<LifecyclePolicy>>((ref) {
  return ref.watch(lifecycleRepositoryProvider).listPolicies();
});

final lifecyclePreviewProvider =
    FutureProvider.autoDispose<LifecyclePreview>((ref) {
  return ref.watch(lifecycleRepositoryProvider).preview();
});

class LifecycleScreen extends ConsumerStatefulWidget {
  const LifecycleScreen({super.key});

  @override
  ConsumerState<LifecycleScreen> createState() => _LifecycleScreenState();
}

class _LifecycleScreenState extends ConsumerState<LifecycleScreen> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final policies = ref.watch(lifecyclePoliciesProvider);
    final preview = ref.watch(lifecyclePreviewProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'الأرشفة التلقائية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.navy900,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTokens.cyan500),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'هذه الصفحة تنقل الكروت والمشتركين المنتهين إلى سلة المحذوفات فقط. لا يوجد حذف نهائي ولا فصل RADIUS في هذه الشريحة.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        preview.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل معاينة الأرشفة',
            subtitle: '$e',
          ),
          data: (data) => _PreviewPanel(
            preview: data,
            running: _running,
            onRun: _runNow,
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        _CreatePolicyCard(onCreated: _refresh),
        const SizedBox(height: AppTokens.s12),
        policies.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل السياسات',
            subtitle: '$e',
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.rule_folder_outlined,
                title: 'لا توجد سياسات أرشفة',
                subtitle: 'أضف قاعدة للكروت المنتهية أو المشتركين المنتهين.',
              );
            }
            return Column(
              children: [
                for (final policy in items) ...[
                  _PolicyCard(policy: policy, onChanged: _refresh),
                  const SizedBox(height: AppTokens.s8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _refresh() {
    ref.invalidate(lifecyclePoliciesProvider);
    ref.invalidate(lifecyclePreviewProvider);
  }

  Future<void> _runNow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تشغيل الأرشفة الآن'),
        content: const Text(
          'سيتم نقل العناصر المؤهلة إلى سلة المحذوفات فقط. العدد الأصلي للحزم لن يتغير، ولا يتم تنفيذ أي RADIUS أو CoA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تشغيل'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _running = true);
    try {
      final result = await ref.read(lifecycleRepositoryProvider).run();
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت أرشفة ${result.changed} عنصر، تخطي ${result.skipped}، فشل ${result.failed}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.preview,
    required this.running,
    required this.onRun,
  });

  final LifecyclePreview preview;
  final bool running;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final totals = preview.totals;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppTokens.s8,
                mainAxisSpacing: AppTokens.s8,
                childAspectRatio: columns == 2 ? 2.0 : 1.75,
                children: [
                  _Metric('كروت ستؤرشف', totals.cards, Icons.credit_card),
                  _Metric('مشتركون سيؤرشفون', totals.subscribers, Icons.person),
                  _Metric(
                    'حزم متأثرة',
                    totals.batchesImpacted,
                    Icons.inventory,
                  ),
                  _Metric(
                    'بانتظار الأرشفة',
                    totals.pendingArchive,
                    Icons.timer,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              StatusPill(
                text: preview.dryRun ? 'معاينة فقط' : 'تنفيذ',
                tone: preview.dryRun ? PillTone.blue : PillTone.green,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: running ? null : onRun,
                icon: running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.archive_outlined),
                label: Text(running ? 'جار التنفيذ...' : 'تشغيل يدوي'),
              ),
            ],
          ),
          if (preview.policies.isNotEmpty) ...[
            const Divider(height: 24),
            for (final item in preview.policies.take(3)) ...[
              _PreviewPolicyRow(item: item),
              const SizedBox(height: AppTokens.s8),
            ],
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTokens.cyan100,
            child: Icon(icon, color: AppTokens.cyan500, size: 18),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: AppTokens.navy900,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
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

class _PreviewPolicyRow extends StatelessWidget {
  const _PreviewPolicyRow({required this.item});
  final LifecyclePolicyPreview item;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusPill(
          text: _entityLabel(item.policy.entityType),
          tone: item.supported ? PillTone.cyan : PillTone.neutral,
        ),
        Text(
          'كروت: ${item.cardsCount} · مشتركون: ${item.subscribersCount}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (!item.supported)
          const Text(
            'محفوظة كسياسة فقط ولا ينفذها العامل الحالي',
            style: TextStyle(color: AppTokens.textMuted),
          ),
      ],
    );
  }
}

class _CreatePolicyCard extends StatefulWidget {
  const _CreatePolicyCard({required this.onCreated});
  final VoidCallback onCreated;

  @override
  State<_CreatePolicyCard> createState() => _CreatePolicyCardState();
}

class _CreatePolicyCardState extends State<_CreatePolicyCard> {
  String _entityType = 'card';
  int _delayValue = 2;
  String _delayUnit = 'days';
  int _retentionValue = 90;
  String _retentionUnit = 'days';
  bool _enabled = true;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إضافة سياسة أرشفة',
                style: TextStyle(
                  color: AppTokens.navy900,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              Wrap(
                spacing: AppTokens.s12,
                runSpacing: AppTokens.s12,
                children: [
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _entityType,
                      decoration: const InputDecoration(labelText: 'النوع'),
                      items: const [
                        DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                        DropdownMenuItem(
                          value: 'subscriber',
                          child: Text('مشترك'),
                        ),
                        DropdownMenuItem(
                          value: 'external_file',
                          child: Text('ملف خارجي'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _entityType = value ?? 'card'),
                    ),
                  ),
                  _NumberField(
                    label: 'بعد انتهاء بمدة',
                    value: _delayValue,
                    onChanged: (value) => _delayValue = value,
                  ),
                  _UnitField(
                    label: 'وحدة التأخير',
                    value: _delayUnit,
                    onChanged: (value) =>
                        setState(() => _delayUnit = value ?? 'days'),
                  ),
                  _NumberField(
                    label: 'الاحتفاظ في السلة',
                    value: _retentionValue,
                    onChanged: (value) => _retentionValue = value,
                  ),
                  _UnitField(
                    label: 'وحدة الاحتفاظ',
                    value: _retentionUnit,
                    onChanged: (value) =>
                        setState(() => _retentionUnit = value ?? 'days'),
                  ),
                  FilterChip(
                    selected: _enabled,
                    label: const Text('مفعّلة'),
                    onSelected: (value) => setState(() => _enabled = value),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(ref),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_saving ? 'جار الحفظ...' : 'حفظ السياسة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(WidgetRef ref) async {
    setState(() => _saving = true);
    try {
      await ref.read(lifecycleRepositoryProvider).createPolicy(
            LifecyclePolicy(
              entityType: _entityType,
              triggerType: 'expired_at',
              delayValue: _delayValue,
              delayUnit: _delayUnit,
              action: 'archive',
              retentionValue: _retentionValue,
              retentionUnit: _retentionUnit,
              enabled: _enabled,
            ),
          );
      widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ سياسة الأرشفة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PolicyCard extends ConsumerWidget {
  const _PolicyCard({required this.policy, required this.onChanged});

  final LifecyclePolicy policy;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTokens.cyan100,
            child:
                Icon(_entityIcon(policy.entityType), color: AppTokens.cyan500),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _entityLabel(policy.entityType),
                      style: const TextStyle(
                        color: AppTokens.navy900,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    StatusPill(
                      text: policy.enabled ? 'مفعّلة' : 'معطّلة',
                      tone: policy.enabled ? PillTone.green : PillTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  'بعد ${policy.delayValue} ${_unitLabel(policy.delayUnit)} من الانتهاء · احتفاظ ${policy.retentionValue} ${_unitLabel(policy.retentionUnit)}',
                  style: const TextStyle(color: AppTokens.textMuted),
                ),
                if (policy.createdAt != null)
                  Text(
                    'أنشئت: ${DateFormat('yyyy-MM-dd HH:mm').format(policy.createdAt!)}',
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: !policy.enabled
                ? null
                : () async {
                    await ref
                        .read(lifecycleRepositoryProvider)
                        .disablePolicy(policy.id);
                    onChanged();
                  },
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text('تعطيل'),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onChanged: (value) => widget.onChanged(int.tryParse(value) ?? 0),
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: 'minutes', child: Text('دقائق')),
          DropdownMenuItem(value: 'hours', child: Text('ساعات')),
          DropdownMenuItem(value: 'days', child: Text('أيام')),
          DropdownMenuItem(value: 'months', child: Text('أشهر')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

String _entityLabel(String value) => switch (value) {
      'card' => 'الكروت المنتهية',
      'subscriber' => 'المشتركون المنتهون',
      'card_batch' => 'حزم البطاقات',
      'external_file' => 'ملف خارجي',
      _ => value,
    };

IconData _entityIcon(String value) => switch (value) {
      'card' => Icons.credit_card,
      'subscriber' => Icons.person_outline,
      'external_file' => Icons.file_present_outlined,
      _ => Icons.inventory_2_outlined,
    };

String _unitLabel(String value) => switch (value) {
      'minutes' => 'دقائق',
      'hours' => 'ساعات',
      'days' => 'أيام',
      'months' => 'أشهر',
      _ => value,
    };
