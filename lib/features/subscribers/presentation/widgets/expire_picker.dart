import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/tokens.dart';

/// Expiry = date AND time, like the web («تاريخ وساعة الانتهاء بالضبط»).
/// Picking a date then a time; a new date defaults to 23:59 (the old
/// «end of that day»). Shown and picked on the PANEL's clock (the tenant's
/// `billing.timezone`, labelled under the field); the model sends it as UTC.
class ExpirePicker extends StatelessWidget {
  const ExpirePicker({
    super.key,
    required this.value,
    required this.onChange,
    this.error,
  });

  final DateTime? value;

  /// The server's (or the form's) message about the expiry.
  final String? error;
  final ValueChanged<DateTime?> onChange;

  Future<void> _pick(BuildContext context) async {
    final base = value ?? panelNow().add(const Duration(days: 30));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(context, df),
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.red,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            PanelTimeZone.label(value),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, DateFormat df) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.r10),
            onTap: () => _pick(context),
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: error == null || error!.isEmpty ? null : '',
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
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
