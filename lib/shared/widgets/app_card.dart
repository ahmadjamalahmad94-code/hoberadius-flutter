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
                          // Icon chip with brand-soft background — matches
                          // the .hub-section-head-icon look on the web.
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(end: AppTokens.s8),
                            decoration: BoxDecoration(
                              color: AppTokens.brandSoft,
                              borderRadius: BorderRadius.circular(AppTokens.r6),
                            ),
                            alignment: Alignment.center,
                            child: Icon(icon, size: 14, color: AppTokens.brandInk),
                          ),
                        ],
                        Flexible(
                          child: Text(
                            title!,
                            softWrap: true,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTokens.textPrimary,
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
