import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Label + field row matching the Flask templates' `.form-row` style.
class FormFieldRow extends StatelessWidget {
  const FormFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  final String label;
  final String? hint;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s16),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final wide = c.maxWidth > 520;
          final labelW = wide
              ? SizedBox(
                  width: 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTokens.s12),
                    child: _Label(label: label, required: required, hint: hint),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s8),
                  child: _Label(label: label, required: required, hint: hint),
                );
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelW,
                const SizedBox(width: AppTokens.s16),
                Expanded(child: child),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [labelW, child],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, required this.required, this.hint});
  final String label;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textPrimary,
                ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTokens.red, fontWeight: FontWeight.w800),
                ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textMuted,
                ),
          ),
        ],
      ],
    );
  }
}
