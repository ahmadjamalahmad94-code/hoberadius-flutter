import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Premium KPI card for dashboards.
///
/// Mirrors the `.hub-kpi` look from `app/static/css/hub_v2.css`:
/// rounded card, brand-soft icon chip with semantic tint, big value,
/// soft hover lift.
enum KpiVariant { brand, green, amber, red, blue }

class HubKpi extends StatelessWidget {
  const HubKpi({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.variant = KpiVariant.brand,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final KpiVariant variant;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipFg, valueColor) = switch (variant) {
      KpiVariant.brand => (AppTokens.brandSoft, AppTokens.brandInk, AppTokens.brandInk),
      KpiVariant.green => (AppTokens.greenSoft, AppTokens.greenInk, AppTokens.greenInk),
      KpiVariant.amber => (AppTokens.amberSoft, AppTokens.amberInk, AppTokens.amberInk),
      KpiVariant.red   => (AppTokens.redSoft,   AppTokens.redInk,   AppTokens.redInk),
      KpiVariant.blue  => (AppTokens.blueSoft,  AppTokens.blueInk,  AppTokens.blueInk),
    };

    final card = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s16,
      ),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        border: Border.all(color: AppTokens.border),
        boxShadow: AppTokens.shCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(AppTokens.r10),
            ),
            child: Icon(icon, size: 20, color: chipFg),
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTokens.textMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.textMuted,
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.r14),
        child: card,
      ),
    );
  }
}
