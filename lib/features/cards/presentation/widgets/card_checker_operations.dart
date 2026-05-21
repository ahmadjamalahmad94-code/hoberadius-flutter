import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/card_model.dart';

class CardCheckerOperations extends StatelessWidget {
  const CardCheckerOperations({
    super.key,
    required this.card,
    required this.busy,
    required this.onEnable,
    required this.onDisable,
    required this.onLockMac,
    required this.onUnlockMac,
    required this.onResetUsage,
    required this.onDisconnect,
    required this.onDeletePermanent,
  });

  final CardCheckResult card;
  final bool busy;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onLockMac;
  final VoidCallback onUnlockMac;
  final VoidCallback onResetUsage;
  final VoidCallback onDisconnect;
  final VoidCallback onDeletePermanent;

  @override
  Widget build(BuildContext context) {
    final id = card.id;
    final enabled = id != null && !busy;
    return AppCard(
      title: 'إجراءات البطاقة',
      icon: Icons.tune,
      child: Wrap(
        spacing: AppTokens.s8,
        runSpacing: AppTokens.s8,
        children: [
          ElevatedButton.icon(
            onPressed: enabled && card.operations.canEnable ? onEnable : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('تفعيل'),
          ),
          OutlinedButton.icon(
            onPressed: enabled && card.operations.canDisable ? onDisable : null,
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text('تعطيل'),
          ),
          OutlinedButton.icon(
            onPressed: enabled ? onLockMac : null,
            icon: const Icon(Icons.lock_outline),
            label: const Text('تثبيت MAC'),
          ),
          OutlinedButton.icon(
            onPressed: enabled && (card.lockedMac?.isNotEmpty ?? false)
                ? onUnlockMac
                : null,
            icon: const Icon(Icons.lock_open),
            label: const Text('فك MAC'),
          ),
          OutlinedButton.icon(
            onPressed: enabled && card.operations.canResetUsage
                ? onResetUsage
                : null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('تصفير الاستخدام'),
          ),
          OutlinedButton.icon(
            onPressed: enabled && card.operations.canDisconnect
                ? onDisconnect
                : null,
            icon: const Icon(Icons.power_settings_new),
            label: const Text('طرد الجلسة'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppTokens.red),
            onPressed: enabled && card.operations.canDeletePermanently
                ? onDeletePermanent
                : null,
            icon: const Icon(Icons.delete_forever),
            label: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }
}
