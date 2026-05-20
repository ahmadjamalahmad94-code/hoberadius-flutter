import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../plans/data/plans_repository.dart';
import '../../plans/domain/plan_model.dart';
import '../data/bandwidth_schedules_repository.dart';
import '../domain/bandwidth_schedule_model.dart';

final bandwidthSchedulesProvider =
    FutureProvider.autoDispose<List<BandwidthSchedule>>((ref) {
  return ref.watch(bandwidthSchedulesRepositoryProvider).list();
});

final bandwidthPlansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

class BandwidthSchedulesScreen extends ConsumerStatefulWidget {
  const BandwidthSchedulesScreen({super.key});

  @override
  ConsumerState<BandwidthSchedulesScreen> createState() =>
      _BandwidthSchedulesScreenState();
}

class _BandwidthSchedulesScreenState
    extends ConsumerState<BandwidthSchedulesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _down = TextEditingController(text: '3000');
  final _up = TextEditingController(text: '1000');
  final _cirDown = TextEditingController(text: '0');
  final _cirUp = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String _starts = '22:00';
  String _ends = '06:00';
  String _restoreMode = 'profile_default';
  int? _planId;
  bool _enabled = true;
  bool _saving = false;
  bool _applying = false;

  @override
  void dispose() {
    _name.dispose();
    _down.dispose();
    _up.dispose();
    _cirDown.dispose();
    _cirUp.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(bandwidthSchedulesProvider);
    final plans = ref.watch(bandwidthPlansProvider);
    final planItems = plans.valueOrNull ?? const <Plan>[];
    final planNames = {
      for (final plan in planItems)
        if (plan.id != null) plan.id!: plan.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'جدولة السرعات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.navy900,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () {
                ref.invalidate(bandwidthSchedulesProvider);
                ref.invalidate(bandwidthPlansProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTokens.orange),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'هذه الشاشة تحفظ خطط تغيير السرعة وتنفذ تجربة تطبيق فقط. لا يوجد عامل تشغيل لحظي يغيّر RADIUS الآن، لذلك تظهر النتيجة applied_to_radius = false.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final children = [
              _FormCard(
                formKey: _formKey,
                plans: planItems,
                planId: _planId,
                name: _name,
                down: _down,
                up: _up,
                cirDown: _cirDown,
                cirUp: _cirUp,
                notes: _notes,
                starts: _starts,
                ends: _ends,
                restoreMode: _restoreMode,
                enabled: _enabled,
                saving: _saving,
                onPlanChanged: (v) => setState(() => _planId = v),
                onStartsChanged: (v) => setState(() => _starts = v),
                onEndsChanged: (v) => setState(() => _ends = v),
                onRestoreChanged: (v) => setState(() => _restoreMode = v),
                onEnabledChanged: (v) => setState(() => _enabled = v),
                onSubmit: _createSchedule,
              ),
              schedules.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'تعذر تحميل جداول السرعة',
                  subtitle: '$e',
                ),
                data: (items) => _SchedulesList(
                  items: items,
                  planNames: planNames,
                  applying: _applying,
                  onApply: _applySchedule,
                ),
              ),
            ];
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  children[0],
                  const SizedBox(height: AppTokens.s12),
                  children[1],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 410, child: children[0]),
                const SizedBox(width: AppTokens.s12),
                Expanded(child: children[1]),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _createSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(bandwidthSchedulesRepositoryProvider).create(
            planId: _planId!,
            name: _name.text.trim(),
            startsAtTime: _starts,
            endsAtTime: _ends,
            speedDownKbps: _toInt(_down.text),
            speedUpKbps: _toInt(_up.text),
            cirDownKbps: _toInt(_cirDown.text),
            cirUpKbps: _toInt(_cirUp.text),
            restoreMode: _restoreMode,
            enabled: _enabled,
            notes: _notes.text.trim(),
          );
      _name.clear();
      _notes.clear();
      ref.invalidate(bandwidthSchedulesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ جدول السرعة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _applySchedule(BandwidthSchedule item) async {
    setState(() => _applying = true);
    try {
      final result = await ref
          .read(bandwidthSchedulesRepositoryProvider)
          .applyDryRun(item.id);
      ref.invalidate(bandwidthSchedulesProvider);
      if (!mounted) return;
      final msg = result.appliedToRadius
          ? 'تم تطبيق الجدول على RADIUS'
          : 'تجربة فقط: لم يتم تغيير RADIUS فعليًا';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.plans,
    required this.planId,
    required this.name,
    required this.down,
    required this.up,
    required this.cirDown,
    required this.cirUp,
    required this.notes,
    required this.starts,
    required this.ends,
    required this.restoreMode,
    required this.enabled,
    required this.saving,
    required this.onPlanChanged,
    required this.onStartsChanged,
    required this.onEndsChanged,
    required this.onRestoreChanged,
    required this.onEnabledChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<Plan> plans;
  final int? planId;
  final TextEditingController name;
  final TextEditingController down;
  final TextEditingController up;
  final TextEditingController cirDown;
  final TextEditingController cirUp;
  final TextEditingController notes;
  final String starts;
  final String ends;
  final String restoreMode;
  final bool enabled;
  final bool saving;
  final ValueChanged<int?> onPlanChanged;
  final ValueChanged<String> onStartsChanged;
  final ValueChanged<String> onEndsChanged;
  final ValueChanged<String> onRestoreChanged;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'إضافة جدول سرعة',
      icon: Icons.speed_outlined,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'اسم الجدول',
                helperText: 'مثال: سرعة الليل أو وقت الذروة.',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'اكتب اسم الجدول' : null,
            ),
            const SizedBox(height: AppTokens.s12),
            DropdownButtonFormField<int>(
              initialValue: planId,
              items: [
                for (final plan in plans)
                  if (plan.id != null)
                    DropdownMenuItem(value: plan.id, child: Text(plan.name)),
              ],
              onChanged: onPlanChanged,
              decoration: const InputDecoration(
                labelText: 'الباقة',
                helperText: 'اختر الباقة التي سيُحفظ عليها الجدول.',
              ),
              validator: (v) => v == null ? 'اختر باقة' : null,
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Expanded(
                  child: _TimeDropDown(
                    label: 'من',
                    value: starts,
                    onChanged: onStartsChanged,
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: _TimeDropDown(
                    label: 'إلى',
                    value: ends,
                    onChanged: onEndsChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: down, label: 'تنزيل Kbps'),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: _NumberField(controller: up, label: 'رفع Kbps'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: cirDown, label: 'CIR تنزيل'),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: _NumberField(controller: cirUp, label: 'CIR رفع'),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            DropdownButtonFormField<String>(
              initialValue: restoreMode,
              items: const [
                DropdownMenuItem(
                  value: 'profile_default',
                  child: Text('رجوع لإعداد الباقة الأساسي'),
                ),
                DropdownMenuItem(
                  value: 'previous_value',
                  child: Text('رجوع للقيمة السابقة'),
                ),
                DropdownMenuItem(value: 'manual', child: Text('رجوع يدوي')),
              ],
              onChanged: (v) => onRestoreChanged(v ?? 'profile_default'),
              decoration: const InputDecoration(labelText: 'طريقة الرجوع'),
            ),
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                helperText: 'سبب الجدولة أو ملاحظة تشغيلية قصيرة.',
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onEnabledChanged,
              title: const Text('مفعّل'),
              subtitle:
                  const Text('تعطيله يبقي الجدول محفوظًا بدون استخدام لاحق.'),
            ),
            const SizedBox(height: AppTokens.s12),
            ElevatedButton.icon(
              onPressed: saving ? null : onSubmit,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'جاري الحفظ...' : 'حفظ الجدول'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulesList extends StatelessWidget {
  const _SchedulesList({
    required this.items,
    required this.planNames,
    required this.applying,
    required this.onApply,
  });

  final List<BandwidthSchedule> items;
  final Map<int, String> planNames;
  final bool applying;
  final ValueChanged<BandwidthSchedule> onApply;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.schedule_outlined,
          title: 'لا توجد جداول سرعة بعد',
          subtitle: 'أضف أول جدول من النموذج لتجربة العقد.',
        ),
      );
    }
    return AppCard(
      title: 'الجداول الحالية',
      icon: Icons.schedule_outlined,
      child: Column(
        children: [
          for (final item in items) ...[
            _ScheduleTile(
              item: item,
              planName: planNames[item.planId] ?? 'باقة #${item.planId}',
              applying: applying,
              onApply: () => onApply(item),
            ),
            if (item != items.last) const Divider(height: AppTokens.s24),
          ],
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.item,
    required this.planName,
    required this.applying,
    required this.onApply,
  });

  final BandwidthSchedule item;
  final String planName;
  final bool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                color: AppTokens.navy900,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            StatusPill(
              text: item.enabled ? 'مفعّل' : 'معطّل',
              tone: item.enabled ? PillTone.green : PillTone.neutral,
            ),
            const StatusPill(text: 'تجربة فقط', tone: PillTone.orange),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        Text(
          '$planName • ${item.startsAtTime} → ${item.endsAtTime}',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            _Metric(label: 'تنزيل', value: '${item.speedDownKbps} Kbps'),
            _Metric(label: 'رفع', value: '${item.speedUpKbps} Kbps'),
            _Metric(label: 'CIR تنزيل', value: '${item.cirDownKbps}'),
            _Metric(label: 'CIR رفع', value: '${item.cirUpKbps}'),
          ],
        ),
        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s8),
          Text(item.notes, style: const TextStyle(color: AppTokens.textMuted)),
        ],
        const SizedBox(height: AppTokens.s12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            onPressed: applying ? null : onApply,
            icon: const Icon(Icons.science_outlined),
            label: const Text('تجربة تطبيق'),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTokens.navy900,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final value = int.tryParse(v ?? '');
        if (value == null || value < 0) return 'رقم صحيح';
        return null;
      },
    );
  }
}

class _TimeDropDown extends StatelessWidget {
  const _TimeDropDown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hours = [
      for (var h = 0; h < 24; h++) '${h.toString().padLeft(2, '0')}:00',
    ];
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: [
        for (final hour in hours)
          DropdownMenuItem(value: hour, child: Text(hour)),
      ],
      onChanged: (v) => onChanged(v ?? value),
      decoration: InputDecoration(labelText: label),
    );
  }
}

int _toInt(String value) => int.tryParse(value.trim()) ?? 0;
