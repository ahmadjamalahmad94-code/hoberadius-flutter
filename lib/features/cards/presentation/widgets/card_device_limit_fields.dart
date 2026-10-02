import 'package:flutter/material.dart';

import '../../../../shared/widgets/form_field_row.dart';
import '../../domain/card_batch_requests.dart';

/// «عدد الأجهزة» of the generator AND the batch editor — the same choices
/// in both (web: 0–50; 0 = the global card setting). A stored value outside
/// the list (e.g. 7) is still shown.
class CardDeviceCountField extends StatelessWidget {
  const CardDeviceCountField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'عدد الأجهزة المسموحة',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final current = normalizeCardDeviceCount(value);
    return FormFieldRow(
      label: label,
      hint: '0 = الافتراض العام',
      child: DropdownButtonFormField<int>(
        key: const ValueKey('card-device-count'),
        isExpanded: true,
        initialValue: current,
        items: [
          for (final n in cardDeviceCountOptionsFor(current))
            DropdownMenuItem(value: n, child: Text(cardDeviceCountLabel(n))),
        ],
        onChanged: (v) => onChanged(v ?? 0),
      ),
    );
  }
}

/// «عند بلوغ حدّ الأجهزة» (`device_limit_mode`), placed right under the
/// device count, web wording.
class CardDeviceLimitModeField extends StatelessWidget {
  const CardDeviceLimitModeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormFieldRow(
      label: 'عند بلوغ حدّ الأجهزة',
      hint: 'سلوك هذه الدفعة عند تجاوز حدّ الأجهزة — يَتجاوز إعداد الكروت '
          'العام. «الافتراض العام» يتبع الإعدادات.',
      child: DropdownButtonFormField<String>(
        key: const ValueKey('card-device-limit-mode'),
        isExpanded: true,
        initialValue: normalizeDeviceLimitMode(value),
        items: [
          for (final e in kCardDeviceLimitModeLabels.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) => onChanged(normalizeDeviceLimitMode(v)),
      ),
    );
  }
}
