import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/hub_layout.dart';

/// One-row header for the card-package forms: back arrow, title, and the
/// form's main action as a compact filled button at the far edge — instead of
/// the button floating alone on its own line above the form.
class CardsFormHeader extends StatelessWidget {
  const CardsFormHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.actionLabel,
    required this.actionIcon,
    required this.busy,
    required this.onAction,
  });

  final String title;
  final VoidCallback onBack;
  final String actionLabel;
  final IconData actionIcon;
  final bool busy;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 820;
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleLarge;
    return Row(
      children: [
        IconButton(
          tooltip: 'رجوع',
          visualDensity: VisualDensity.compact,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: AppTokens.s4),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTokens.sidebarBg,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        SizedBox(
          width: 104,
          child: HubActionButton(
            item: ActionItem(
              icon: busy ? Icons.hourglass_top : actionIcon,
              label: actionLabel,
              primary: true,
              onPressed: busy ? null : onAction,
            ),
          ),
        ),
      ],
    );
  }
}
