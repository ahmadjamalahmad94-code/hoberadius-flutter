import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Popup menu shown on the edit screen for disable / extend / reset /
/// delete actions. Each callback may be `null` to render the entry as
/// disabled (while the form is mid-action).
class SubscriberActionMenu extends StatelessWidget {
  const SubscriberActionMenu({
    super.key,
    required this.isDisabled,
    required this.onToggle,
    required this.onExtend,
    required this.onResetPw,
    required this.onDelete,
  });

  final bool isDisabled;
  final VoidCallback? onToggle;
  final VoidCallback? onExtend;
  final VoidCallback? onResetPw;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'إجراءات',
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        switch (v) {
          case 'toggle':
            onToggle?.call();
          case 'extend':
            onExtend?.call();
          case 'reset':
            onResetPw?.call();
          case 'delete':
            onDelete?.call();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                isDisabled ? Icons.check_circle_outline : Icons.block,
                size: 18,
                color: isDisabled ? AppTokens.green : AppTokens.amber,
              ),
              const SizedBox(width: 8),
              Text(isDisabled ? 'تفعيل' : 'تعطيل'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'extend',
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: AppTokens.brand),
              SizedBox(width: 8),
              Text('تمديد الوقت'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.password, size: 18, color: AppTokens.sidebarBgElev2),
              SizedBox(width: 8),
              Text('إعادة كلمة المرور'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppTokens.red),
              SizedBox(width: 8),
              Text('حذف', style: TextStyle(color: AppTokens.red)),
            ],
          ),
        ),
      ],
    );
  }
}
