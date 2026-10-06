import 'package:flutter/material.dart';
import 'package:hoberadius_app/core/format/number_input.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/hub_unit_input.dart';
import '../../../../shared/widgets/wheel_picker_fields.dart';
import '../../domain/bandwidth_schedule_model.dart';
import 'schedule_days_picker.dart';

/// «تعديل جدول السرعة» — the web edit dialog's fields, labels and units
/// (speeds in kbps/Mbps, priority 1–10, the three restore modes). The target
/// (plan / subscriber / batch / group) is fixed after creation, as on the web.
///
/// Returns the fields to PATCH, or null when cancelled.
Future<Map<String, dynamic>?> showBandwidthEditDialog(
  BuildContext context,
  BandwidthSchedule item,
) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    useRootNavigator: true,
    builder: (_) => BandwidthEditDialog(item: item),
  );
}

class BandwidthEditDialog extends StatefulWidget {
  const BandwidthEditDialog({super.key, required this.item});

  final BandwidthSchedule item;

  @override
  State<BandwidthEditDialog> createState() => _BandwidthEditDialogState();
}

class _BandwidthEditDialogState extends State<BandwidthEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _priority;
  late final TextEditingController _notes;
  late String _starts;
  late String _ends;
  late int _down;
  late int _up;
  late Set<String> _days;
  late String _restoreMode;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i.name);
    _priority = TextEditingController(
      text: '${i.priority >= 1 && i.priority <= 10 ? i.priority : 5}',
    );
    _notes = TextEditingController(text: i.notes);
    _starts = i.startsAtTime.isEmpty ? '00:00' : i.startsAtTime;
    _ends = i.endsAtTime.isEmpty ? '00:00' : i.endsAtTime;
    _down = i.speedDownKbps;
    _up = i.speedUpKbps;
    _days = parseScheduleDays(i.daysCsv);
    _restoreMode = normalizeScheduleRestoreMode(i.restoreMode);
    _enabled = i.enabled;
  }

  @override
  void dispose() {
    _name.dispose();
    _priority.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String, dynamic>{
      'name': _name.text.trim(),
      'priority': parseIntInput(_priority.text) ?? 5,
      'starts_at_time': _starts,
      'ends_at_time': _ends,
      'speed_down_kbps': _down,
      'speed_up_kbps': _up,
      'days_csv': scheduleDaysCsv(_days),
      'restore_mode': _restoreMode,
      'notes': _notes.text.trim(),
      'enabled': _enabled,
    });
  }

  Widget _speed(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTokens.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        HubUnitInput(
          value: value,
          units: const ['kbps', 'Mbps'],
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل جدول السرعة'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('bw-edit-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'اسم الجدول'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'اكتب اسم الجدول' : null,
                ),
                const SizedBox(height: AppTokens.s12),
                TextFormField(
                  key: const ValueKey('bw-edit-priority'),
                  controller: _priority,
                  keyboardType: TextInputType.number,
                  inputFormatters: numberFieldFormatters,
                  decoration: const InputDecoration(
                    labelText: 'الأولوية داخل نفس النطاق (1-10)',
                  ),
                  validator: (v) =>
                      validateNumberInput(v, decimal: false, min: 1, max: 10),
                ),
                const SizedBox(height: AppTokens.s12),
                WheelTimeRangeField(
                  fromLabel: 'من الساعة',
                  toLabel: 'إلى الساعة',
                  fromValue: _starts,
                  toValue: _ends,
                  onChanged: (from, to) => setState(() {
                    _starts = from;
                    _ends = to;
                  }),
                ),
                const SizedBox(height: AppTokens.s12),
                ScheduleDaysPicker(
                  selected: _days,
                  onChanged: (v) => setState(() => _days = v),
                ),
                const SizedBox(height: AppTokens.s12),
                _speed('سرعة التنزيل', _down, (v) => _down = v),
                const SizedBox(height: AppTokens.s8),
                _speed('سرعة الرفع', _up, (v) => _up = v),
                const SizedBox(height: AppTokens.s12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('bw-edit-restore-mode'),
                  isExpanded: true,
                  initialValue: _restoreMode,
                  items: [
                    for (final m in kScheduleRestoreModes.entries)
                      DropdownMenuItem(value: m.key, child: Text(m.value)),
                  ],
                  onChanged: (v) =>
                      setState(() => _restoreMode = v ?? 'profile_default'),
                  decoration: const InputDecoration(
                    labelText: 'طريقة الرجوع بعد الوقت',
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  title: const Text('مفعّل'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        ElevatedButton.icon(
          key: const ValueKey('bw-edit-save'),
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('حفظ التعديل'),
        ),
      ],
    );
  }
}

/// The web's delete confirmation: «حذف جدول «X»؟ لا يمكن التراجع.»
Future<bool> confirmDeleteBandwidthSchedule(
  BuildContext context,
  BandwidthSchedule item,
) async {
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف جدول السرعة'),
      content: Text('حذف جدول «${item.name}»؟ لا يمكن التراجع.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          key: const ValueKey('bw-delete-confirm'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTokens.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  return ok == true;
}
