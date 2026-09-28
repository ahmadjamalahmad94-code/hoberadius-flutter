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
    // Accessibility: the visible label is drawn beside/above the field, so it
    // was never linked to it (inputs had an empty aria-label on the web and
    // TalkBack read «edit box»). The field gets the label as its own
    // semantics node; the drawn caption is excluded to avoid reading twice.
    final labelled = Semantics(
      container: true,
      label: required ? '$label (مطلوب)' : label,
      hint: hint,
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final wide = c.maxWidth > 520;
          final labelW = wide
              ? SizedBox(
                  width: 180,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTokens.s12),
                    child: ExcludeSemantics(
                      child:
                          _Label(label: label, required: required, hint: hint),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.s4),
                  child: ExcludeSemantics(
                    child: _Label(
                      label: label,
                      required: required,
                      hint: hint,
                      inline: true,
                    ),
                  ),
                );
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelW,
                const SizedBox(width: AppTokens.s16),
                Expanded(child: labelled),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [labelW, labelled],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.required,
    this.hint,
    this.inline = false,
  });
  final String label;
  final bool required;
  final String? hint;

  /// Phone layout: the hint rides on the label's line (muted, after a dot)
  /// instead of taking a line of its own — forms were twice as tall as they
  /// needed to be.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final labelStyle = text.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppTokens.textPrimary,
    );
    final hintStyle = text.bodySmall?.copyWith(color: AppTokens.textMuted);
    if (inline) {
      return Text.rich(
        TextSpan(
          style: labelStyle,
          children: [
            TextSpan(text: label),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppTokens.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (hint != null && hint!.isNotEmpty)
              TextSpan(text: '  ·  ${hint!}', style: hintStyle),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppTokens.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!, style: hintStyle),
        ],
      ],
    );
  }
}

/// Two short fields side by side (numbers, prices, ports, durations) — halves
/// the height of phone forms. Each child is normally a [FormFieldRow].
class FormFieldPair extends StatelessWidget {
  const FormFieldPair({super.key, required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: first),
        const SizedBox(width: AppTokens.s12),
        Expanded(child: second),
      ],
    );
  }
}
