import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/tokens.dart';

/// Expiry = date AND time, like the web («تاريخ وساعة الانتهاء بالضبط»).
/// Picking a date then a time; a new date defaults to 23:59 (the old
/// «end of that day»). Shown and picked in the phone's local time; the model
/// sends it as UTC.
class ExpirePicker extends StatelessWidget {
  const ExpirePicker({super.key, required this.value, required this.onChange});

  final DateTime? value;
  final ValueChanged<DateTime?> onChange;

  Future<void> _pick(BuildContext context) async {
    final base = value ?? DateTime.now().add(const Duration(days: 30));
    final day = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'تاريخ الانتهاء',
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: value == null
          ? const TimeOfDay(hour: 23, minute: 59)
          : TimeOfDay.fromDateTime(value!),
      helpText: 'ساعة الانتهاء',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    final t = time ??
        (value == null
            ? const TimeOfDay(hour: 23, minute: 59)
            : TimeOfDay.fromDateTime(value!));
    onChange(
      DateTime(
        day.year,
        day.month,
        day.day,
        t.hour,
        t.minute,
        t.hour == 23 && t.minute == 59 ? 59 : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd  HH:mm', 'en');
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r10),
            onTap: () => _pick(context),
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Text(
                value == null ? 'بدون انتهاء' : df.format(value!),
                textDirection: value == null ? null : TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        IconButton(
          tooltip: 'اختيار التاريخ والساعة',
          onPressed: () => _pick(context),
          icon: const Icon(Icons.event_outlined),
        ),
        if (value != null)
          IconButton(
            tooltip: 'بدون انتهاء',
            onPressed: () => onChange(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }
}
