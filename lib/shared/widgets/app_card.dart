import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Bordered card with optional header (title + actions).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.icon,
    this.actions,
    this.padding = const EdgeInsets.all(AppTokens.s20),
    required this.child,
  });

  final String? title;
  final IconData? icon;
  final List<Widget>? actions;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s16,
                AppTokens.s20,
                AppTokens.s16,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppTokens.cyan500),
                    const SizedBox(width: AppTokens.s8),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTokens.navy800,
                          ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
