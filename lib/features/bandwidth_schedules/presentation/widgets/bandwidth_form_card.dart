import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';
import '../../../cards/domain/card_model.dart';
import '../../../plans/domain/plan_model.dart';
import '../../../subscribers/domain/subscriber_model.dart';

class BandwidthFormCard extends StatelessWidget {
  const BandwidthFormCard({
    super.key,
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
              isExpanded: true,
              initialValue: targetType,
              items: const [
                DropdownMenuItem(value: 'plan', child: Text('عرض / باقة خدمة')),
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
            _TargetPicker(
              targetType: targetType,
              plans: plans,
              subscribers: subscribers,
              batches: batches,
              planId: planId,
              subscriberUsername: subscriberUsername,
              cardBatchId: cardBatchId,
              onPlanChanged: onPlanChanged,
              onSubscriberChanged: onSubscriberChanged,
              onCardBatchChanged: onCardBatchChanged,
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
              isExpanded: true,
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
              subtitle: const Text(
                'تعطيله يبقي الجدول محفوظًا بدون تطبيقه على السرعات.',
              ),
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

class _TargetPicker extends StatelessWidget {
  const _TargetPicker({
    required this.targetType,
    required this.plans,
    required this.subscribers,
    required this.batches,
    required this.planId,
    required this.subscriberUsername,
    required this.cardBatchId,
    required this.onPlanChanged,
    required this.onSubscriberChanged,
    required this.onCardBatchChanged,
  });

  final String targetType;
  final List<Plan> plans;
  final List<Subscriber> subscribers;
  final List<CardBatch> batches;
  final int? planId;
  final String? subscriberUsername;
  final int? cardBatchId;
  final ValueChanged<int?> onPlanChanged;
  final ValueChanged<String?> onSubscriberChanged;
  final ValueChanged<int?> onCardBatchChanged;

  @override
  Widget build(BuildContext context) {
    if (targetType == 'plan') {
      return DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue: planId,
        items: [
          for (final plan in plans)
            if (plan.id != null)
              DropdownMenuItem(value: plan.id, child: Text(plan.name)),
        ],
        onChanged: onPlanChanged,
        decoration: const InputDecoration(
          labelText: 'الباقة',
          helperText: 'تُستخدم إذا لم توجد قاعدة خاصة بالمشترك أو الكروت.',
        ),
        validator: (v) => v == null ? 'اختر باقة' : null,
      );
    }
    if (targetType == 'subscriber') {
      return DropdownButtonFormField<String>(
        isExpanded: true,
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
      );
    }
    return DropdownButtonFormField<int>(
      isExpanded: true,
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
