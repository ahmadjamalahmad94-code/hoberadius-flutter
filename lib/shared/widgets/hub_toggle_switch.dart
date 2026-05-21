import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';

/// Canonical mobile on/off toggle — Flutter mirror of the web
/// `_partials/toggle_switch.html` macro (operator-locked 2026-05-21).
///
/// Renders a 38×22 (md) or 32×18 (sm) pill track with a sliding white
/// thumb, optional inline on/off label, optional shell box, and full
/// light/dark theme support via [AppPalette].
///
/// This is the ONLY accepted boolean on/off control for the redesigned
/// app — screens must not roll their own `Switch` styling. Pass
/// `onChanged: null` to render a disabled toggle.
enum HubToggleSize { md, sm }

class HubToggleSwitch extends StatelessWidget {
  const HubToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = HubToggleSize.md,
    this.bare = false,
    this.showLabel = true,
    this.onLabel = 'مفعَّل',
    this.offLabel = 'معطَّل',
    this.semanticLabel,
  });

  final bool value;

  /// Tap handler. Pass `null` to render the toggle in a disabled state.
  final ValueChanged<bool>? onChanged;

  final HubToggleSize size;

  /// When `true`, drops the surrounding shell box (padding + border +
  /// background). Use inside dense tables / row cells.
  final bool bare;

  /// Hide the inline text label entirely.
  final bool showLabel;

  final String onLabel;
  final String offLabel;

  /// Screen-reader label. Falls back to the active on/off label.
  final String? semanticLabel;

  bool get _enabled => onChanged != null;
  bool get _isSm => size == HubToggleSize.sm;

  // Track / thumb geometry — mirrors the CSS in toggle_switch.html.
  double get _trackW => _isSm ? 32 : 38;
  double get _trackH => _isSm ? 18 : 22;
  double get _thumbSize => _isSm ? 14 : 18;
  double get _thumbInset => 2;
  double get _thumbOffsetOn => _trackW - _thumbSize - _thumbInset;

  EdgeInsets get _shellPadding => _isSm
      ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
      : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
  double get _shellMinHeight => _isSm ? 30 : 40;
  double get _gap => _isSm ? 8 : 10;
  double get _labelSize => _isSm ? 12 : 13;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final track = _Track(
      value: value,
      width: _trackW,
      height: _trackH,
      thumbSize: _thumbSize,
      thumbInset: _thumbInset,
      thumbOffsetOn: _thumbOffsetOn,
      enabled: _enabled,
      palette: p,
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        track,
        if (showLabel) ...[
          SizedBox(width: _gap),
          Text(
            value ? onLabel : offLabel,
            style: TextStyle(
              fontSize: _labelSize,
              fontWeight: FontWeight.w700,
              height: 1,
              color: !_enabled
                  ? p.textMuted
                  : (value ? p.brandInk : p.textSecondary),
            ),
          ),
        ],
      ],
    );

    final content = bare
        ? row
        : AnimatedContainer(
            duration: AppTokens.motionFast,
            curve: AppTokens.motionEase,
            padding: _shellPadding,
            constraints: BoxConstraints(minHeight: _shellMinHeight),
            decoration: BoxDecoration(
              color: p.soft,
              borderRadius: BorderRadius.circular(AppTokens.r10),
              border: Border.all(
                color: value && _enabled ? p.brandLine : p.border,
              ),
            ),
            child: row,
          );

    return Semantics(
      toggled: value,
      enabled: _enabled,
      label: semanticLabel ?? (value ? onLabel : offLabel),
      button: true,
      child: MouseRegion(
        cursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? () => onChanged!(!value) : null,
          child: Opacity(
            opacity: _enabled ? 1 : 0.55,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.value,
    required this.width,
    required this.height,
    required this.thumbSize,
    required this.thumbInset,
    required this.thumbOffsetOn,
    required this.enabled,
    required this.palette,
  });

  final bool value;
  final double width;
  final double height;
  final double thumbSize;
  final double thumbInset;
  final double thumbOffsetOn;
  final bool enabled;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final thumbStart = value ? thumbOffsetOn : thumbInset;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: AppTokens.motionFast,
            curve: AppTokens.motionEase,
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: value && enabled ? palette.brandGradient : null,
              color: value && enabled ? null : palette.borderStrong,
              borderRadius: BorderRadius.circular(999),
              boxShadow: value && enabled
                  ? [
                      BoxShadow(
                        color: palette.brand.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
          AnimatedPositioned(
            duration: AppTokens.motionFast,
            curve: AppTokens.motionEase,
            top: thumbInset,
            left: isRtl ? null : thumbStart,
            right: isRtl ? thumbStart : null,
            width: thumbSize,
            height: thumbSize,
            child: const _Thumb(),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
