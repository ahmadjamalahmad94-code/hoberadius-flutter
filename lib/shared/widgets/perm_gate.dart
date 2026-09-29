import 'package:flutter/material.dart';

/// Wraps a control the admin may not use in a tooltip that says why
/// (tap or hover). [reason] null → [child] unchanged.
class PermTooltip extends StatelessWidget {
  const PermTooltip({super.key, required this.reason, required this.child});

  final String? reason;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final r = reason;
    if (r == null || r.isEmpty) return child;
    return Tooltip(
      message: r,
      triggerMode: TooltipTriggerMode.tap,
      child: child,
    );
  }
}
