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
              child: Wrap(
                spacing: AppTokens.s8,
                runSpacing: AppTokens.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 180),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: AppTokens.cyan500),
                          const SizedBox(width: AppTokens.s8),
                        ],
                        Flexible(
                          child: Text(
                            title!,
                            softWrap: true,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.navy800,
                                  height: 1.25,
                                ),
                          ),
                        ),
                      ],
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
