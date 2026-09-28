import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/status_pill.dart';

/// Solid colour of an action's tone — icon chips, confirm buttons.
Color actionToneColor(PillTone tone) => switch (tone) {
      PillTone.green => AppTokens.greenInk,
      PillTone.amber => const Color(0xFFB45309),
      PillTone.red => AppTokens.red,
      PillTone.blue => AppTokens.blueInk,
      PillTone.neutral => AppTokens.slate500,
      _ => AppTokens.brand,
    };

/// Tinted rounded square holding an action's icon (sheet rows, dialog
/// titles) — the same chip everywhere so an action reads at a glance.
class ActionIconChip extends StatelessWidget {
  const ActionIconChip({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 36,
    this.enabled = true,
  });

  final IconData icon;
  final PillTone tone;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = pillToneColors(enabled ? tone : PillTone.neutral);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Icon(icon, size: size * 0.53, color: fg),
    );
  }
}

/// Chrome shared by every subscriber action dialog: icon chip + title +
/// username, a scrollable body, an inline error box, and «إلغاء» + the
/// confirm button splitting the width evenly. While [busy] the confirm button
/// shows a spinner and nothing can be dismissed.
class ActionDialogFrame extends StatelessWidget {
  const ActionDialogFrame({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.children,
    required this.confirmLabel,
    required this.onConfirm,
    this.subtitle,
    this.confirmIcon,
    this.busy = false,
    this.error,
    this.danger = false,
    this.cancelLabel = 'إلغاء',
    this.retryable = false,
  });

  /// The last failure can simply be retried (server busy/unreachable): the
  /// confirm button turns into «إعادة المحاولة».
  final bool retryable;

  final IconData icon;
  final PillTone tone;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String confirmLabel;
  final IconData? confirmIcon;

  /// `null` disables the confirm button (form not valid yet).
  final VoidCallback? onConfirm;
  final bool busy;
  final String? error;
  final bool danger;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final btnText = text.labelLarge?.copyWith(fontWeight: FontWeight.w800);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.s12),
    );
    final confirmColor = danger ? AppTokens.red : AppTokens.brand;
    return PopScope(
      canPop: !busy,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r18),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 6, 10),
                child: Row(
                  children: [
                    ActionIconChip(icon: icon, tone: tone, size: 38),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTokens.sidebarBg,
                              height: 1.3,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: AppTokens.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      visualDensity: VisualDensity.compact,
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTokens.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
              if (error != null && error!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: ActionNote(text: error!, tone: PillTone.red),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: AppTokens.textSecondary,
                          side: const BorderSide(color: AppTokens.borderStrong),
                          backgroundColor: AppTokens.surfaceMuted,
                          shape: shape,
                          textStyle: btnText,
                        ),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: busy ? null : onConfirm,
                        icon: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                retryable
                                    ? Icons.refresh
                                    : (confirmIcon ?? Icons.check),
                                size: 18,
                              ),
                        label: Text(
                          retryable ? 'إعادة المحاولة' : confirmLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              confirmColor.withValues(alpha: 0.45),
                          disabledForegroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: shape,
                          textStyle: btnText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small label above a group of controls (web «usq-field» caption).
class ActionFieldLabel extends StatelessWidget {
  const ActionFieldLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textPrimary,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Muted/tinted one-paragraph note (live price, rules, warnings, errors).
class ActionNote extends StatelessWidget {
  const ActionNote({
    super.key,
    required this.text,
    this.tone = PillTone.neutral,
    this.icon,
  });

  final String text;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = pillToneColors(tone);
    final ic = icon ??
        switch (tone) {
          PillTone.red => Icons.error_outline,
          PillTone.amber => Icons.warning_amber_rounded,
          PillTone.green => Icons.check_circle_outline,
          _ => Icons.info_outline,
        };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(ic, size: 16, color: fg),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChoiceOption<T> {
  const ChoiceOption(
    this.value,
    this.label, {
    this.icon,
    this.caption,
    this.enabled = true,
  });
  final T value;
  final String label;
  final IconData? icon;
  final String? caption;
  final bool enabled;
}

/// Equal-width selectable tiles — the web's «usq-seg» segmented choice.
class ChoiceTiles<T> extends StatelessWidget {
  const ChoiceTiles({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.dense = false,
    this.tone = PillTone.brand,
  });

  final List<ChoiceOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final bool dense;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (softBg, fg, _) = pillToneColors(tone);
    final strong = actionToneColor(tone);
    // IntrinsicHeight: equal-height tiles inside the dialog's scroll view
    // (a stretched Row alone would ask for infinite height).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Builder(
                builder: (context) {
                  final o = options[i];
                  final selected = o.value == value;
                  final enabled = o.enabled && onChanged != null;
                  return Opacity(
                    opacity: enabled || selected ? 1 : 0.45,
                    child: Material(
                      color: selected ? softBg : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.r10),
                        side: BorderSide(
                          color: selected ? strong : AppTokens.borderStrong,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTokens.r10),
                        onTap: enabled ? () => onChanged!(o.value) : null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: dense ? 6 : 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (o.icon != null) ...[
                                Icon(
                                  o.icon,
                                  size: 18,
                                  color: selected ? fg : AppTokens.slate500,
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                o.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    (dense ? text.labelMedium : text.labelLarge)
                                        ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: selected ? fg : AppTokens.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              if (o.caption != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  o.caption!,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelSmall?.copyWith(
                                    color: AppTokens.textMuted,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A read-only value shown like a field (auto price, currency).
class ReadOnlyValue extends StatelessWidget {
  const ReadOnlyValue({super.key, required this.value, this.emphasis = false});
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTokens.slate100,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.slate200.withValues(alpha: 0.8)),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
              color: emphasis ? AppTokens.brandInk : AppTokens.textSecondary,
            ),
      ),
    );
  }
}

/// Digits (Latin or Arabic-Indic) + one decimal separator.
final numberInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹\.,٫]')),
];

final intInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹]')),
];

const actionFieldDecoration = InputDecoration(isDense: true);
