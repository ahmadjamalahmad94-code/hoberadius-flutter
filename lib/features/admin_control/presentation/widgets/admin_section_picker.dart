import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'admin_section_common.dart';

/// Choice-chip strip for switching between admin control sections.
class AdminSectionPicker extends StatelessWidget {
  const AdminSectionPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AdminSection value;
  final ValueChanged<AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (section: AdminSection.settings, icon: Icons.tune, label: 'الإعدادات'),
      (section: AdminSection.tokens, icon: Icons.key, label: 'مفاتيح الربط'),
      (section: AdminSection.tenants, icon: Icons.business, label: 'المستأجرون'),
      (section: AdminSection.webhooks, icon: Icons.bolt, label: 'إشعارات الويب'),
    ];
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: [
        for (final item in items)
          ChoiceChip(
            selected: value == item.section,
            avatar: Icon(item.icon, size: 16),
            label: Text(item.label),
            onSelected: (_) => onChanged(item.section),
          ),
      ],
    );
  }
}
