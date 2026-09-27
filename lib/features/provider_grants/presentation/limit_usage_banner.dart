import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../application/provider_grants_provider.dart';
import '../domain/provider_grants_model.dart';

/// "X of Y used" banner for a provider quantity cap. Renders nothing when the
/// service has no cap (or no grants). Turns red + shows the over-limit message
/// when the cap is reached, mirroring the web's capacity warning.
class LimitUsageBanner extends ConsumerWidget {
  const LimitUsageBanner({super.key, required this.serviceKey});

  /// The provider feature-key (e.g. 'subscribers', 'cards', 'profiles').
  final String serviceKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(grantLimitProvider(serviceKey));
    if (limit == null || !limit.hasCap) return const SizedBox.shrink();

    final atCap = limit.atCap;
    final color = atCap ? AppTokens.red : AppTokens.brand;
    final max = limit.limit!;
    final ratio = max <= 0 ? 1.0 : (limit.current / max).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s12),
      padding: const EdgeInsets.all(AppTokens.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                atCap ? Icons.error_outline : Icons.donut_large_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'حدّ المزوّد: ${limit.current} من $max',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (atCap) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              providerLimitMessageAr(limit),
              style: const TextStyle(color: AppTokens.redInk, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// The Arabic over-limit message, byte-identical to the web's
/// `provider_grant.check_limit` message.
String providerLimitMessageAr(GrantLimit limit) {
  final max = limit.limit ?? 0;
  return 'تم الوصول إلى الحدّ المسموح من المزوّد لهذه الخدمة '
      '(${limit.current} من $max).';
}

/// True when a create action for [serviceKey] is allowed (no cap, or under it).
bool grantsAllowCreate(WidgetRef ref, String serviceKey) {
  final limit = ref.read(grantLimitProvider(serviceKey));
  return limit == null || !limit.atCap;
}

/// A primary create button that disables itself when the provider quantity cap
/// for [serviceKey] is reached, with the Arabic over-limit message in a
/// tooltip. Drop-in replacement for the screens' `ElevatedButton.icon` add
/// buttons so block-at-cap is consistent everywhere.
class GuardedCreateButton extends ConsumerWidget {
  const GuardedCreateButton({
    super.key,
    required this.serviceKey,
    required this.label,
    required this.onCreate,
    this.icon = Icons.add,
  });

  final String serviceKey;
  final String label;
  final VoidCallback onCreate;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(grantLimitProvider(serviceKey));
    final atCap = limit?.atCap ?? false;
    final button = ElevatedButton.icon(
      onPressed: atCap ? null : onCreate,
      icon: Icon(icon),
      label: Text(label),
    );
    if (!atCap) return button;
    return Tooltip(
      message: providerLimitMessageAr(limit!),
      child: button,
    );
  }
}
