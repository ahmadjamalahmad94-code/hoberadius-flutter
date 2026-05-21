import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/wheel_picker_fields.dart';
import '../../cards/data/cards_repository.dart';
import '../../cards/domain/card_model.dart';
import '../../plans/data/plans_repository.dart';
import '../../plans/domain/plan_model.dart';
import '../../subscribers/data/subscribers_repository.dart';
import '../../subscribers/domain/subscriber_model.dart';
import '../data/bandwidth_schedules_repository.dart';
import '../domain/bandwidth_schedule_model.dart';

final bandwidthSchedulesProvider =
    FutureProvider.autoDispose<List<BandwidthSchedule>>((ref) {
  return ref.watch(bandwidthSchedulesRepositoryProvider).list();
});

final bandwidthPlansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).list();
});

final bandwidthSubscribersProvider =
    FutureProvider.autoDispose<List<Subscriber>>((ref) {
  return ref.watch(subscribersRepositoryProvider).list(limit: 500);
});

final bandwidthCardBatchesProvider =
    FutureProvider.autoDispose<List<CardBatch>>((ref) {
  return ref.watch(cardsRepositoryProvider).listBatches(limit: 500);
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
  final _priority = TextEditingController(text: '100');
  final _notes = TextEditingController();
  String _targetType = 'plan';
  String _starts = '22:00';
  String _ends = '06:00';
  String _restoreMode = 'profile_default';
  int? _planId;
  String? _subscriberUsername;
  int? _cardBatchId;
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
    _priority.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedules = ref.watch(bandwidthSchedulesProvider);
    final plans = ref.watch(bandwidthPlansProvider);
    final subscribers = ref.watch(bandwidthSubscribersProvider);
    final batches = ref.watch(bandwidthCardBatchesProvider);
    final planItems = plans.valueOrNull ?? const <Plan>[];
    final subscriberItems = subscribers.valueOrNull ?? const <Subscriber>[];
    final batchItems = batches.valueOrNull ?? const <CardBatch>[];
    final planNames = {
      for (final plan in planItems)
        if (plan.id != null) plan.id!: plan.name,
    };
    final batchNames = {
      for (final batch in batchItems)
        if (batch.id != null)
          batch.id!: batch.packageName.isNotEmpty
              ? '${batch.batchCode} - ${batch.packageName}'
              : batch.batchCode,
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
                ref.invalidate(bandwidthSubscribersProvider);
                ref.invalidate(bandwidthCardBatchesProvider);
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
                subscribers: subscriberItems,
                batches: batchItems,
                targetType: _targetType,
                planId: _planId,
                subscriberUsername: _subscriberUsername,
                cardBatchId: _cardBatchId,
                name: _name,
                down: _down,
                up: _up,
                cirDown: _cirDown,
                cirUp: _cirUp,
                priority: _priority,
                notes: _notes,
                starts: _starts,
                ends: _ends,
                restoreMode: _restoreMode,
                enabled: _enabled,
                saving: _saving,
                onTargetTypeChanged: (v) => setState(() {
                  _targetType = v;
                  _planId = null;
                  _subscriberUsername = null;
                  _cardBatchId = null;
                }),
                onPlanChanged: (v) => setState(() => _planId = v),
                onSubscriberChanged: (v) =>
                    setState(() => _subscriberUsername = v),
                onCardBatchChanged: (v) => setState(() => _cardBatchId = v),
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
                  batchNames: batchNames,
                  applying: _applying,
                  onApplyDryRun: (item) => _applySchedule(item),
                  onApplyLive: (item) => _applySchedule(item, live: true),
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
            targetType: _targetType,
            planId: _targetType == 'plan' ? _planId : null,
            subscriberUsername:
                _targetType == 'subscriber' ? (_subscriberUsername ?? '') : '',
            cardBatchId: _targetType == 'card_batch' ? _cardBatchId : null,
            priority: _toInt(_priority.text),
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

  Future<void> _applySchedule(
    BandwidthSchedule item, {
    bool live = false,
  }) async {
    setState(() => _applying = true);
    try {
      final result = await ref
          .read(bandwidthSchedulesRepositoryProvider)
          .apply(item.id, live: live);
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
    required this.subscribers,
    required this.batches,
    required this.targetType,
    required this.planId,
    required this.subscriberUsername,
    required this.cardBatchId,
    required this.name,
    required this.down,
    required this.up,
    required this.cirDown,
    required this.cirUp,
    required this.priority,
    required this.notes,
    required this.starts,
    required this.ends,
    required this.restoreMode,
    required this.enabled,
    required this.saving,
    required this.onTargetTypeChanged,
    required this.onPlanChanged,
    required this.onSubscriberChanged,
    required this.onCardBatchChanged,
    required this.onStartsChanged,
    required this.onEndsChanged,
    required this.onRestoreChanged,
    required this.onEnabledChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<Plan> plans;
  final List<Subscriber> subscribers;
  final List<CardBatch> batches;
  final String targetType;
  final int? planId;
  final String? subscriberUsername;
  final int? cardBatchId;
  final TextEditingController name;
  final TextEditingController down;
  final TextEditingController up;
  final TextEditingController cirDown;
  final TextEditingController cirUp;
  final TextEditingController priority;
  final TextEditingController notes;
  final String starts;
  final String ends;
  final String restoreMode;
  final bool enabled;
  final bool saving;
  final ValueChanged<String> onTargetTypeChanged;
  final ValueChanged<int?> onPlanChanged;
  final ValueChanged<String?> onSubscriberChanged;
  final ValueChanged<int?> onCardBatchChanged;
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
            DropdownButtonFormField<String>(
              initialValue: targetType,
              items: const [
                DropdownMenuItem(
                  value: 'plan',
                  child: Text('عرض / باقة خدمة'),
                ),
                DropdownMenuItem(
                  value: 'subscriber',
                  child: Text('مشترك محدد'),
                ),
                DropdownMenuItem(
                  value: 'card_batch',
                  child: Text('باقة كروت / دفعة'),
                ),
              ],
              onChanged: (v) => onTargetTypeChanged(v ?? 'plan'),
              decoration: const InputDecoration(
                labelText: 'نطاق القاعدة',
                helperText: 'المشترك أو باقة الكروت يتقدمان على قاعدة العرض.',
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            if (targetType == 'plan')
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
                  helperText:
                      'تُستخدم إذا لم توجد قاعدة خاصة بالمشترك أو الكروت.',
                ),
                validator: (v) => v == null ? 'اختر باقة' : null,
              )
            else if (targetType == 'subscriber')
              DropdownButtonFormField<String>(
                initialValue: subscriberUsername,
                items: [
                  for (final sub in subscribers)
                    DropdownMenuItem(
                      value: sub.username,
                      child: Text(
                        sub.fullName.isEmpty
                            ? sub.username
                            : '${sub.username} - ${sub.fullName}',
                      ),
                    ),
                ],
                onChanged: onSubscriberChanged,
                decoration: const InputDecoration(
                  labelText: 'المشترك',
                  helperText: 'هذه القاعدة لها أعلى أولوية عند تسجيل الدخول.',
                ),
                validator: (v) => (v ?? '').isEmpty ? 'اختر مشتركًا' : null,
              )
            else
              DropdownButtonFormField<int>(
                initialValue: cardBatchId,
                items: [
                  for (final batch in batches)
                    if (batch.id != null)
                      DropdownMenuItem(
                        value: batch.id,
                        child: Text(
                          batch.packageName.isEmpty
                              ? batch.batchCode
                              : '${batch.batchCode} - ${batch.packageName}',
                        ),
                      ),
                ],
                onChanged: onCardBatchChanged,
                decoration: const InputDecoration(
                  labelText: 'باقة الكروت / الدفعة',
                  helperText: 'تطبق على بطاقات هذه الدفعة وتتقدم على العرض.',
                ),
                validator: (v) => v == null ? 'اختر دفعة كروت' : null,
              ),
            const SizedBox(height: AppTokens.s12),
            WheelTimeRangeField(
              fromLabel: 'من',
              toLabel: 'إلى',
              fromValue: starts,
              toValue: ends,
              onChanged: (from, to) {
                onStartsChanged(from);
                onEndsChanged(to);
              },
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
                  child: _NumberField(
                    controller: cirDown,
                    label: 'الحد الأدنى للتنزيل',
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: _NumberField(
                    controller: cirUp,
                    label: 'الحد الأدنى للرفع',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            _NumberField(
              controller: priority,
              label: 'الأولوية داخل نفس النطاق',
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
    required this.batchNames,
    required this.applying,
    required this.onApplyDryRun,
    required this.onApplyLive,
  });

  final List<BandwidthSchedule> items;
  final Map<int, String> planNames;
  final Map<int, String> batchNames;
  final bool applying;
  final ValueChanged<BandwidthSchedule> onApplyDryRun;
  final ValueChanged<BandwidthSchedule> onApplyLive;

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
              targetName: _targetName(item, planNames, batchNames),
              applying: applying,
              onApplyDryRun: () => onApplyDryRun(item),
              onApplyLive: () => onApplyLive(item),
            ),
            if (item != items.last) const Divider(height: AppTokens.s24),
          ],
        ],
      ),
    );
  }

  static String _targetName(
    BandwidthSchedule item,
    Map<int, String> planNames,
    Map<int, String> batchNames,
  ) {
    if (item.targetType == 'subscriber') {
      return 'مشترك: ${item.subscriberUsername}';
    }
    if (item.targetType == 'card_batch') {
      final id = item.cardBatchId;
      return 'باقة كروت: ${id == null ? 'غير محددة' : batchNames[id] ?? '#$id'}';
    }
    return 'عرض: ${planNames[item.planId] ?? '#${item.planId}'}';
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.item,
    required this.targetName,
    required this.applying,
    required this.onApplyDryRun,
    required this.onApplyLive,
  });

  final BandwidthSchedule item;
  final String targetName;
  final bool applying;
  final VoidCallback onApplyDryRun;
  final VoidCallback onApplyLive;

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
          '$targetName • ${item.startsAtTime} → ${item.endsAtTime} • أولوية ${item.priority}',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            _Metric(label: 'تنزيل', value: '${item.speedDownKbps} Kbps'),
            _Metric(label: 'رفع', value: '${item.speedUpKbps} Kbps'),
            _Metric(label: 'حد تنزيل أدنى', value: '${item.cirDownKbps}'),
            _Metric(label: 'حد رفع أدنى', value: '${item.cirUpKbps}'),
          ],
        ),
        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s8),
          Text(item.notes, style: const TextStyle(color: AppTokens.textMuted)),
        ],
        const SizedBox(height: AppTokens.s12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: applying ? null : onApplyDryRun,
                icon: const Icon(Icons.science_outlined),
                label: const Text('تجربة تطبيق'),
              ),
              ElevatedButton.icon(
                onPressed: applying ? null : onApplyLive,
                icon: const Icon(Icons.network_check_outlined),
                label: const Text('تطبيق فعلي'),
              ),
            ],
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

int _toInt(String value) => int.tryParse(value.trim()) ?? 0;
