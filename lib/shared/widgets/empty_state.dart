import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Empty state matching the web `.hub-empty` look — soft tinted card,
/// gradient icon halo, centred copy + optional CTA.
///
/// J5.2: themes through AppPalette + AppTypography so it renders
/// correctly in dark mode; the icon now sits in a brand-soft gradient
/// halo to give the state a polished "illustration + CTA" feel.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s16),
      padding: const EdgeInsets.all(AppTokens.s40),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: p.border, width: 1),
        boxShadow: p.shCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.brandSoft,
                  p.brandSoft.withValues(alpha: 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: p.brandLine, width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: p.brand.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: p.brandInk),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              subtitle!,
              style: AppTypography.bodyMedium.copyWith(color: p.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppTokens.s20),
            action!,
          ],
        ],
      ),
    );
  }
}
