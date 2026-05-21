// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/form_field_row.dart';

class CardBatchRuntimeSection extends StatelessWidget {
  const CardBatchRuntimeSection({
    super.key,
    required this.timeVal,
    required this.devices,
    required this.notes,
    required this.timeUnit,
    required this.onTimeUnit,
    required this.durationMode,
    required this.onDurationMode,
    required this.quotaAction,
    required this.onQuotaAction,
    required this.countFromFirstConnect,
    required this.onCountFromFirstConnect,
    required this.countBySeconds,
    required this.onCountBySeconds,
    required this.autoRenew,
    required this.onAutoRenew,
    required this.switchMac,
    required this.onSwitchMac,
    required this.lockMac,
    required this.onLockMac,
    required this.phoneOnly,
    required this.onPhoneOnly,
  });

  final TextEditingController timeVal;
  final TextEditingController devices;
  final TextEditingController notes;
  final String timeUnit;
  final ValueChanged<String?> onTimeUnit;
  final String durationMode;
  final ValueChanged<String?> onDurationMode;
  final String quotaAction;
  final ValueChanged<String?> onQuotaAction;
  final bool countFromFirstConnect;
  final ValueChanged<bool> onCountFromFirstConnect;
  final bool countBySeconds;
  final ValueChanged<bool> onCountBySeconds;
  final bool autoRenew;
  final ValueChanged<bool> onAutoRenew;
  final bool switchMac;
  final ValueChanged<bool> onSwitchMac;
  final bool lockMac;
  final ValueChanged<bool> onLockMac;
  final bool phoneOnly;
  final ValueChanged<bool> onPhoneOnly;

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        title: Text(label),
      );

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      storageKey: 'batch.edit.runtime',
      icon: Icons.timer_outlined,
      title: 'الصلاحية والسلوك',
      child: Column(
        children: [
          FormFieldRow(
            label: 'قيمة الوقت',
            child: TextFormField(
              controller: timeVal,
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'وحدة الوقت',
            child: DropdownButtonFormField<String>(
              value: timeUnit,
              items: const [
                DropdownMenuItem(value: 'minutes', child: Text('دقائق')),
                DropdownMenuItem(value: 'hours', child: Text('ساعات')),
                DropdownMenuItem(value: 'days', child: Text('أيام')),
              ],
              onChanged: onTimeUnit,
            ),
          ),
          FormFieldRow(
            label: 'عدد الأجهزة',
            child: TextFormField(
              controller: devices,
              keyboardType: TextInputType.number,
            ),
          ),
          FormFieldRow(
            label: 'وضع المدة',
            child: DropdownButtonFormField<String>(
              value: durationMode,
              items: const [
                DropdownMenuItem(
                  value: 'time_unit',
                  child: Text('حسب الوحدة'),
                ),
                DropdownMenuItem(value: 'seconds', child: Text('بالثواني')),
              ],
              onChanged: onDurationMode,
            ),
          ),
          FormFieldRow(
            label: 'عند انتهاء الحصة',
            child: DropdownButtonFormField<String>(
              value: quotaAction,
              items: const [
                DropdownMenuItem(value: 'stop', child: Text('إيقاف')),
                DropdownMenuItem(
                  value: 'reduce_speed',
                  child: Text('تخفيض السرعة'),
                ),
                DropdownMenuItem(value: 'notify', child: Text('تنبيه فقط')),
              ],
              onChanged: onQuotaAction,
            ),
          ),
          _switch(
            'العد من أول اتصال',
            countFromFirstConnect,
            onCountFromFirstConnect,
          ),
          _switch('العد بالثواني', countBySeconds, onCountBySeconds),
          _switch('تجديد تلقائي', autoRenew, onAutoRenew),
          _switch('ربط MAC عند الاتصال', switchMac, onSwitchMac),
          _switch('قفل MAC عند الإغلاق', lockMac, onLockMac),
          _switch('دخول برقم الجوال فقط', phoneOnly, onPhoneOnly),
          FormFieldRow(
            label: 'ملاحظات',
            child: TextFormField(controller: notes, maxLines: 3),
          ),
        ],
      ),
    );
  }
}
