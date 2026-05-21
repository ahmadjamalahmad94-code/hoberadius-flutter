import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/mikrotik_model.dart';

class MikrotikConfigCard extends StatelessWidget {
  const MikrotikConfigCard({
    super.key,
    required this.config,
    required this.testing,
    required this.onEdit,
    required this.onTest,
    required this.onDelete,
  });

  final MikrotikConfig config;
  final bool testing;
  final VoidCallback onEdit;
  final VoidCallback? onTest;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: config.enabled
                      ? AppTokens.brandSoft
                      : AppTokens.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.router_outlined,
                  color: config.enabled
                      ? AppTokens.brand
                      : AppTokens.textMuted,
                  size: 20,
                ),
              ),
              Text(
                config.name.isEmpty ? config.host : config.name,
                style: const TextStyle(
                  color: AppTokens.sidebarBg,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              StatusPill(
                text: config.enabled ? 'مفعّل' : 'معطّل',
                tone: config.enabled ? PillTone.green : PillTone.neutral,
              ),
              if (config.useTls)
                const StatusPill(text: 'TLS', tone: PillTone.blue),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            '${config.host}:${config.port} · المستخدم: ${config.username.isEmpty ? 'غير محدد' : config.username} · المهلة: ${config.timeoutSec} ث',
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
              OutlinedButton.icon(
                onPressed: testing ? null : onTest,
                icon: testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check),
                label: Text(testing ? 'جار الاختبار...' : 'اختبار'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppTokens.red),
                label: const Text('حذف'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
