// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../plans/domain/plan_option.dart';
import '../../domain/card_model.dart';
import 'card_number_field.dart';
import 'card_plan_picker.dart';

class CardBatchCoreSection extends StatelessWidget {
  const CardBatchCoreSection({
    super.key,
    required this.packageName,
    required this.planId,
    required this.planName,
    required this.onPlan,
    required this.count,
    required this.status,
    required this.onStatus,
    this.currency = '',
  });

  final TextEditingController packageName;

  /// The batch's plan (kept as is unless another plan is picked).
  final int? planId;

  /// Name of the batch's current plan (shown when it is not in the active
  /// plans list).
  final String planName;
  final ValueChanged<PlanOption> onPlan;

  /// Cards in the batch — locked after generation (server 422), display only.
  final int count;
  final String status;
  final ValueChanged<String?> onStatus;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'batch.edit.core',
      icon: Icons.credit_card_outlined,
      title: 'بيانات الباقة',
      child: Column(
        children: [
          FormFieldRow(
            label: 'اسم الباقة',
            child: TextFormField(controller: packageName),
          ),
          FormFieldRow(
            label: 'الباقة',
            required: true,
            hint: 'تغيير الباقة يطبّق على الكروت المتاحة فقط',
            child: CardPlanPicker(
              selectedId: planId,
              onChanged: onPlan,
              currency: currency,
              keepLabel: planName.trim().isNotEmpty
                  ? '${planName.trim()} (الحالية)'
                  : 'الباقة الحالية #${planId ?? ''}',
            ),
          ),
          FormFieldPair(
            first: CardReadOnlyField(
              label: 'عدد الباقة',
              value: '$count',
            ),
            second: FormFieldRow(
              label: 'الحالة',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشطة')),
                  DropdownMenuItem(value: 'exhausted', child: Text('مستهلكة')),
                  DropdownMenuItem(value: 'revoked', child: Text('ملغاة')),
                ],
                onChanged: onStatus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardBatchMoneySection extends StatelessWidget {
  const CardBatchMoneySection({
    super.key,
    required this.pricePerCard,
    required this.priceBulk,
    required this.totalPrice,
    required this.totalQuota,
    required this.serviceName,
    required this.managerId,
  });

  final TextEditingController pricePerCard;
  final TextEditingController priceBulk;
  final TextEditingController totalPrice;
  final TextEditingController totalQuota;
  final TextEditingController serviceName;
  final TextEditingController managerId;

  @override
  Widget build(BuildContext context) {
    Widget num(
      TextEditingController c,
      String label, {
      bool money = false,
    }) =>
        FormFieldRow(
          label: label,
          child: money
              ? CardNumberField.money(controller: c)
              : CardNumberField(controller: c),
        );
    return CollapsibleSection(
      storageKey: 'batch.edit.money',
      icon: Icons.sell_outlined,
      title: 'السعر والحصة',
      child: Column(
        children: [
          FormFieldPair(
            first: num(pricePerCard, 'سعر البطاقة', money: true),
            second: num(priceBulk, 'سعر الجملة', money: true),
          ),
          FormFieldPair(
            first: num(totalPrice, 'السعر الإجمالي', money: true),
            second: num(totalQuota, 'الحصة الكلية MB'),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'اسم الخدمة',
              child: TextFormField(controller: serviceName),
            ),
            second: num(managerId, 'معرّف المدير'),
          ),
        ],
      ),
    );
  }
}

/// «نمط كلمة المرور» of a stored batch.
String cardPasswordTypeLabel(String type) => switch (type) {
      'digits' => 'أرقام فقط',
      'weak' => 'حروف',
      'medium' => 'متوسط',
      'strong' => 'قوي',
      '' => '—',
      _ => type,
    };

/// «موضع الإضافة» of a stored batch.
String cardAffixModeLabel(String mode) => switch (mode) {
      'prefix' => 'قبل الاسم',
      'suffix' => 'بعد الاسم',
      _ => 'بدون',
    };

/// The generation settings of a batch — DISPLAY ONLY: the server locks the
/// card structure once the cards exist (422 on any change), so the editor
/// shows them and never sends them.
class CardBatchGenerationSection extends StatelessWidget {
  const CardBatchGenerationSection({super.key, required this.batch});

  final CardBatch batch;

  @override
  Widget build(BuildContext context) {
    String orDash(String v) => v.trim().isEmpty ? '—' : v.trim();
    return CollapsibleSection(
      storageKey: 'batch.edit.generation',
      icon: Icons.dialpad_outlined,
      title: 'إعدادات التوليد (للعرض فقط)',
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'بنية الكروت مقفلة بعد التوليد — الكروت مولّدة/مطبوعة بالفعل.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          CardReadOnlyField(
            label: 'موضع الإضافة',
            value: cardAffixModeLabel(batch.startsWithOrEndsWith),
          ),
          FormFieldPair(
            first: CardReadOnlyField(
              label: 'البادئة',
              value: orDash(batch.usernamePrefix),
              ltr: true,
            ),
            second: CardReadOnlyField(
              label: 'اللاحقة',
              value: orDash(batch.usernameSuffix),
              ltr: true,
            ),
          ),
          FormFieldPair(
            first: CardReadOnlyField(
              label: 'طول اسم الدخول',
              value: '${batch.usernameLength}',
            ),
            second: CardReadOnlyField(
              label: 'طول كلمة المرور',
              value: '${batch.passwordLength}',
            ),
          ),
          FormFieldPair(
            first: CardReadOnlyField(
              label: 'نمط كلمة المرور',
              value: cardPasswordTypeLabel(batch.passwordGenerationType),
            ),
            second: CardReadOnlyField(
              label: 'تضمين رقم الباقة',
              value: batch.includeBatchNumber ? 'نعم' : 'لا',
            ),
          ),
        ],
      ),
    );
  }
}

/// A locked value shown like a disabled field.
class CardReadOnlyField extends StatelessWidget {
  const CardReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return FormFieldRow(
      label: label,
      child: TextFormField(
        key: ValueKey('ro-$label-$value'),
        initialValue: value,
        readOnly: true,
        enabled: false,
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: const InputDecoration(
          suffixIcon: Icon(Icons.lock_outline, size: 16),
        ),
      ),
    );
  }
}
