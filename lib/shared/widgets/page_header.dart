import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppTokens.s8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTokens.navy900,
                          height: 1.15,
                        ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTokens.textMuted,
                            height: 1.35,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        if (actions.isEmpty) return titleBlock;

        final actionsWrap = Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          alignment: compact ? WrapAlignment.start : WrapAlignment.end,
          children: actions,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: AppTokens.s12),
              actionsWrap,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppTokens.s12),
            Flexible(child: actionsWrap),
          ],
        );
      },
    );
  }
}
