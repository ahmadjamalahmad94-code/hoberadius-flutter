// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';
import '../../../../shared/widgets/hub_switch_row.dart';

class CardBatchCoreSection extends StatelessWidget {
  const CardBatchCoreSection({
    super.key,
    required this.packageName,
    required this.plan,
    required this.count,
    required this.status,
    required this.onStatus,
    required this.minCount,
  });

  final TextEditingController packageName;
  final TextEditingController plan;
  final TextEditingController count;
  final String status;
  final ValueChanged<String?> onStatus;
  final int minCount;

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
            label: 'معرّف العرض',
            required: true,
            hint: 'تغيير العرض يطبّق على الكروت المتاحة فقط',
            child: TextFormField(
              controller: plan,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v?.trim() ?? '') == null ? 'مطلوب' : null,
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'عدد الباقة',
              required: true,
              hint: 'لا يقلّ عن $minCount',
              child: TextFormField(
                controller: count,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < minCount) {
                    return 'لا يقلّ عن $minCount';
                  }
                  return null;
                },
              ),
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
    Widget num(TextEditingController c, String label) => FormFieldRow(
          label: label,
          child:
              TextFormField(controller: c, keyboardType: TextInputType.number),
        );
    return CollapsibleSection(
      storageKey: 'batch.edit.money',
      icon: Icons.sell_outlined,
      title: 'السعر والحصة',
      child: Column(
        children: [
          FormFieldPair(
            first: num(pricePerCard, 'سعر البطاقة'),
            second: num(priceBulk, 'سعر الجملة'),
          ),
          FormFieldPair(
            first: num(totalPrice, 'السعر الإجمالي'),
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

class CardBatchGenerationSection extends StatelessWidget {
  const CardBatchGenerationSection({
    super.key,
    required this.prefix,
    required this.suffix,
    required this.ulen,
    required this.plen,
    required this.passwordType,
    required this.onPasswordType,
    required this.affixMode,
    required this.onAffixMode,
    required this.includeBatchNumber,
    required this.onIncludeBatchNumber,
  });

  final TextEditingController prefix;
  final TextEditingController suffix;
  final TextEditingController ulen;
  final TextEditingController plen;
  final String passwordType;
  final ValueChanged<String?> onPasswordType;
  final String affixMode;
  final ValueChanged<String?> onAffixMode;
  final bool includeBatchNumber;
  final ValueChanged<bool> onIncludeBatchNumber;

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'batch.edit.generation',
      icon: Icons.dialpad_outlined,
      title: 'إعدادات التوليد المستقبلية',
      child: Column(
        children: [
          FormFieldRow(
            label: 'موضع الإضافة',
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: affixMode.isEmpty ? 'none' : affixMode,
              items: const [
                DropdownMenuItem(value: 'none', child: Text('بدون')),
                DropdownMenuItem(value: 'prefix', child: Text('قبل الاسم')),
                DropdownMenuItem(value: 'suffix', child: Text('بعد الاسم')),
              ],
              onChanged: (v) => onAffixMode(v == 'none' ? '' : v),
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'البادئة',
              child: TextFormField(controller: prefix),
            ),
            second: FormFieldRow(
              label: 'اللاحقة',
              child: TextFormField(controller: suffix),
            ),
          ),
          FormFieldPair(
            first: FormFieldRow(
              label: 'طول اسم الدخول',
              child: TextFormField(
                controller: ulen,
                keyboardType: TextInputType.number,
              ),
            ),
            second: FormFieldRow(
              label: 'طول كلمة المرور',
              child: TextFormField(
                controller: plen,
                keyboardType: TextInputType.number,
              ),
            ),
          ),
          FormFieldRow(
            label: 'نمط كلمة المرور',
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: passwordType,
              items: const [
                DropdownMenuItem(value: 'digits', child: Text('أرقام فقط')),
                DropdownMenuItem(value: 'weak', child: Text('حروف')),
                DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                DropdownMenuItem(value: 'strong', child: Text('قوي')),
              ],
              onChanged: onPasswordType,
            ),
          ),
          HubSwitchRow(
            dense: true,
            label: 'تضمين رقم الباقة',
            value: includeBatchNumber,
            onChanged: onIncludeBatchNumber,
          ),
        ],
      ),
    );
  }
}
