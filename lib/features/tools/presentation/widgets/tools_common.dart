import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class ToolsPanelTitle extends StatelessWidget {
  const ToolsPanelTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTokens.brandSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppTokens.brand, size: 20),
        ),
        const SizedBox(width: AppTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ToolsTwoFields extends StatelessWidget {
  const ToolsTwoFields({
    super.key,
    required this.first,
    required this.second,
    this.alwaysRow = false,
  });

  final Widget first;
  final Widget second;

  /// Keep short fields (speeds, credentials) side by side even on phones.
  final bool alwaysRow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!alwaysRow && constraints.maxWidth < 640) {
          return Column(
            children: [
              first,
              const SizedBox(height: AppTokens.s8),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: AppTokens.s8),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class ToolsTintBox extends StatelessWidget {
  const ToolsTintBox({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: child,
      ),
    );
  }
}

class ToolsKeyValueBox extends StatelessWidget {
  const ToolsKeyValueBox({super.key, required this.values});

  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return ToolsTintBox(
      color: AppTokens.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.entries
            .map(
              (entry) => Text(
                '${_resultKeyLabel(entry.key)}: ${_resultValueLabel(entry.value)}',
              ),
            )
            .toList(),
      ),
    );
  }
}

String _resultKeyLabel(String key) {
  return switch (key.trim().toLowerCase()) {
    'ok' || 'success' => 'النتيجة',
    'dry_run' => 'معاينة فقط',
    'action' => 'الإجراء',
    'matched' || 'matched_count' => 'الحسابات المطابقة',
    'changed' || 'changed_count' => 'الحسابات المعدلة',
    'skipped' || 'skipped_count' => 'الحسابات المتروكة',
    'errors' || 'error_count' => 'الأخطاء',
    'message' => 'الرسالة',
    'users' || 'usernames' => 'الحسابات',
    'minutes' => 'الدقائق',
    _ => 'تفصيل',
  };
}

String _resultValueLabel(Object? value) {
  if (value is bool) return value ? 'نعم' : 'لا';
  final text = value?.toString().trim() ?? '';
  return switch (text.toLowerCase()) {
    'true' => 'نعم',
    'false' => 'لا',
    'disable' => 'تعطيل',
    'enable' => 'تفعيل',
    'extend' => 'تمديد وقت',
    'reset_password' => 'تغيير كلمة المرور',
    '' => 'غير محدد',
    _ => text,
  };
}

class ToolsTextField extends StatelessWidget {
  const ToolsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
