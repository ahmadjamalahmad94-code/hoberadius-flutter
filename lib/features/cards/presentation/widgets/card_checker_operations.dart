import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/hub_layout.dart';
import '../../../../shared/widgets/status_pill.dart';
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
      padding: const EdgeInsets.all(AppTokens.s12),
      child: ActionBar(
        maxPerRow: 2,
        items: [
          ActionItem(
            icon: Icons.play_arrow,
            label: 'تفعيل',
            primary: true,
            onPressed: enabled && card.operations.canEnable ? onEnable : null,
          ),
          ActionItem(
            icon: Icons.pause_circle_outline,
            label: 'تعطيل',
            tone: PillTone.amber,
            onPressed: enabled && card.operations.canDisable ? onDisable : null,
          ),
          ActionItem(
            icon: Icons.lock_outline,
            label: 'تثبيت MAC',
            onPressed: enabled ? onLockMac : null,
          ),
          ActionItem(
            icon: Icons.lock_open,
            label: 'فك MAC',
            onPressed: enabled && (card.lockedMac?.isNotEmpty ?? false)
                ? onUnlockMac
                : null,
          ),
          ActionItem(
            icon: Icons.restart_alt,
            label: 'تصفير الاستخدام',
            onPressed: enabled && card.operations.canResetUsage
                ? onResetUsage
                : null,
          ),
          ActionItem(
            icon: Icons.power_settings_new,
            label: 'طرد الجلسة',
            onPressed: enabled && card.operations.canDisconnect
                ? onDisconnect
                : null,
          ),
          ActionItem(
            icon: Icons.delete_forever,
            label: 'حذف نهائي',
            tone: PillTone.red,
            onPressed: enabled && card.operations.canDeletePermanently
                ? onDeletePermanent
                : null,
          ),
        ],
      ),
    );
  }
}
