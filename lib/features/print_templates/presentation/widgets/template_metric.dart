import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Shared mini-tile used in the template list and the preview card to
/// render `label / value` pairs in a consistent card style.
class TemplateMetric extends StatelessWidget {
  const TemplateMetric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
