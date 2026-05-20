import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Empty state matching the web `.hub-empty` look — dashed border,
/// faint icon, soft surface.
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s16),
      padding: const EdgeInsets.all(AppTokens.s40),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(
          color: AppTokens.borderStrong,
          width: 1,
          style: BorderStyle.solid, // Flutter has no native dashed border;
                                    // BorderStyle.solid with brand line color
                                    // approximates the hub-empty dashed look.
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTokens.brandSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: AppTokens.textFaint),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTokens.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textMuted,
                  ),
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
