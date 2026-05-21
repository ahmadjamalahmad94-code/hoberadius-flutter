import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';

/// Date picker for the subscriber's expiry — InputDecorator + calendar
/// button + clear button (clear is only visible when a date is set).
class ExpirePicker extends StatelessWidget {
  const ExpirePicker({super.key, required this.value, required this.onChange});

  final DateTime? value;
  final ValueChanged<DateTime?> onChange;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Text(value == null ? 'بدون انتهاء' : df.format(value!)),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        IconButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  value ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChange(picked);
          },
          icon: const Icon(Icons.calendar_today_outlined),
        ),
        if (value != null)
          IconButton(
            onPressed: () => onChange(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }
}
