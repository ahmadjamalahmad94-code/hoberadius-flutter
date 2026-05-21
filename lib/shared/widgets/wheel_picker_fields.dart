import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

const wheelDayKeys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const wheelDayLabels = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

class WheelTimePickerField extends StatelessWidget {
  const WheelTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: () async {
        final picked = await showWheelTimePicker(context, value);
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule_outlined),
        ),
        child: Text(
          _normalizeTime(value),
          style: const TextStyle(
            color: AppTokens.sidebarBg,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class WheelTimeRangeField extends StatelessWidget {
  const WheelTimeRangeField({
    super.key,
    required this.fromLabel,
    required this.toLabel,
    required this.fromValue,
    required this.toValue,
    required this.onChanged,
  });

  final String fromLabel;
  final String toLabel;
  final String fromValue;
  final String toValue;
  final void Function(String from, String to) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WheelTimePickerField(
            label: fromLabel,
            value: fromValue,
            onChanged: (value) => onChanged(value, toValue),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: WheelTimePickerField(
            label: toLabel,
            value: toValue,
            onChanged: (value) => onChanged(fromValue, value),
          ),
        ),
      ],
    );
  }
}

class WheelDaysPickerField extends StatelessWidget {
  const WheelDaysPickerField({
    super.key,
    required this.selectedKeys,
    required this.onChanged,
  });

  final Set<String> selectedKeys;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [
      for (var index = 0; index < wheelDayKeys.length; index++)
        if (selectedKeys.contains(wheelDayKeys[index])) wheelDayLabels[index],
    ];
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: () async {
        final picked = await showWheelDaysPicker(context, selectedKeys);
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'الأيام',
          suffixIcon: Icon(Icons.view_day_outlined),
        ),
        child: Text(
          labels.isEmpty ? 'لا توجد أيام محددة' : labels.join('، '),
          style: TextStyle(
            color: labels.isEmpty ? AppTokens.textMuted : AppTokens.sidebarBg,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Future<String?> showWheelTimePicker(BuildContext context, String initialValue) {
  final parsed = _parseTime(initialValue);
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      var hour = parsed.$1;
      var minute = parsed.$2;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SizedBox(
            height: 310,
            child: Column(
              children: [
                const Text(
                  'اختيار الوقت',
                  style: TextStyle(
                    color: AppTokens.sidebarBg,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: hour,
                          ),
                          itemExtent: 42,
                          onSelectedItemChanged: (value) => hour = value,
                          children: [
                            for (var h = 0; h < 24; h++)
                              Center(
                                child: Text(h.toString().padLeft(2, '0')),
                              ),
                          ],
                        ),
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: minute,
                          ),
                          itemExtent: 42,
                          onSelectedItemChanged: (value) => minute = value,
                          children: [
                            for (var m = 0; m < 60; m++)
                              Center(
                                child: Text(m.toString().padLeft(2, '0')),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(
                            context,
                            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                          ),
                          child: const Text('اعتماد'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<Set<String>?> showWheelDaysPicker(
  BuildContext context,
  Set<String> initialKeys,
) {
  var selected = Set<String>.from(initialKeys);
  var focusedIndex = 0;
  return showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final focusedKey = wheelDayKeys[focusedIndex];
            final isSelected = selected.contains(focusedKey);
            return SafeArea(
              child: SizedBox(
                height: 360,
                child: Column(
                  children: [
                    const Text(
                      'اختيار الأيام',
                      style: TextStyle(
                        color: AppTokens.sidebarBg,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: focusedIndex,
                        ),
                        itemExtent: 44,
                        onSelectedItemChanged: (value) =>
                            setSheetState(() => focusedIndex = value),
                        children: [
                          for (final label in wheelDayLabels)
                            Center(child: Text(label)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s16,
                      ),
                      child: Wrap(
                        spacing: AppTokens.s8,
                        runSpacing: AppTokens.s8,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => setSheetState(() {
                              if (isSelected) {
                                selected.remove(focusedKey);
                              } else {
                                selected.add(focusedKey);
                              }
                            }),
                            icon: Icon(
                              isSelected
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline,
                            ),
                            label: Text(
                              isSelected ? 'إزالة اليوم' : 'إضافة اليوم',
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => setSheetState(
                              () => selected = {...wheelDayKeys},
                            ),
                            child: const Text('كل الأيام'),
                          ),
                          OutlinedButton(
                            onPressed: () => setSheetState(selected.clear),
                            child: const Text('مسح'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppTokens.s16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, selected),
                              child: const Text('اعتماد'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

(int, int) _parseTime(String value) {
  final parts = _normalizeTime(value).split(':');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

String _normalizeTime(String value) {
  final raw = value.trim();
  final parts = raw.split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return '${hour.clamp(0, 23).toString().padLeft(2, '0')}:${minute.clamp(0, 59).toString().padLeft(2, '0')}';
}
