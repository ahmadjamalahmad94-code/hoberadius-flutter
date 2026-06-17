import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'hub_toggle_switch.dart';

/// Canonical settings row: a clearly-visible Arabic label (with optional
/// helper subtitle) on the leading side and a compact [HubToggleSwitch] on
/// the trailing side, aligned and evenly spaced.
///
/// This is the ONE accepted way to render a labelled on/off setting — screens
/// must not roll their own `SwitchListTile` / `FilterChip`-as-toggle, which is
/// what produced oversized purple pills with invisible labels. Tapping
/// anywhere on the row toggles the value. Pass `onChanged: null` to disable.
class HubSwitchRow extends StatelessWidget {
  const HubSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.dense = false,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Tighter vertical padding for use inside already-dense cards.
  final bool dense;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r10),
      onTap: _enabled ? () => onChanged!(!value) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTokens.s4,
          vertical: dense ? AppTokens.s8 : AppTokens.s12,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: _enabled ? AppTokens.brandInk : AppTokens.textMuted,
              ),
              const SizedBox(width: AppTokens.s8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _enabled
                          ? AppTokens.textPrimary
                          : AppTokens.textMuted,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: text.bodySmall?.copyWith(
                        color: AppTokens.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s12),
            HubToggleSwitch(
              value: value,
              onChanged: onChanged,
              showLabel: false,
              bare: true,
              semanticLabel: label,
            ),
          ],
        ),
      ),
    );
  }
}
