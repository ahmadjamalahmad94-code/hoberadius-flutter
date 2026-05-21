import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../application/lifecycle_providers.dart';
import '../../data/lifecycle_repository.dart';
import '../../domain/lifecycle_model.dart';

class LifecyclePolicyCard extends ConsumerWidget {
  const LifecyclePolicyCard({
    super.key,
    required this.policy,
    required this.onChanged,
  });

  final LifecyclePolicy policy;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTokens.brandSoft,
            child: Icon(_entityIcon(policy.entityType), color: AppTokens.brand),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      lifecycleEntityLabel(policy.entityType),
                      style: const TextStyle(
                        color: AppTokens.sidebarBg,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    StatusPill(
                      text: policy.enabled ? 'مفعّلة' : 'معطّلة',
                      tone:
                          policy.enabled ? PillTone.green : PillTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  'بعد ${policy.delayValue} ${lifecycleUnitLabel(policy.delayUnit)} من الانتهاء · احتفاظ ${policy.retentionValue} ${lifecycleUnitLabel(policy.retentionUnit)}',
                  style: const TextStyle(color: AppTokens.textMuted),
                ),
                if (policy.createdAt != null)
                  Text(
                    'أنشئت: ${DateFormat('yyyy-MM-dd HH:mm').format(policy.createdAt!)}',
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: !policy.enabled
                ? null
                : () async {
                    await ref
                        .read(lifecycleRepositoryProvider)
                        .disablePolicy(policy.id);
                    onChanged();
                  },
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text('تعطيل'),
          ),
        ],
      ),
    );
  }
}

IconData _entityIcon(String value) => switch (value) {
      'card' => Icons.credit_card,
      'subscriber' => Icons.person_outline,
      'external_file' => Icons.file_present_outlined,
      _ => Icons.inventory_2_outlined,
    };
