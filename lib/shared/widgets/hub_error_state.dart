import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'hub_toast.dart';

/// Canonical error surface for failing list/detail requests — danger-
/// tone halo, message body, and an inline retry CTA. Optionally fires
/// an inline [HubToast] (error tone) on the first build so the
/// operator sees a transient pop the moment the error appears.
class HubErrorState extends StatefulWidget {
  const HubErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
    this.showToastOnce = false,
    this.icon = Icons.error_outline,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool showToastOnce;
  final IconData icon;

  @override
  State<HubErrorState> createState() => _HubErrorStateState();
}

class _HubErrorStateState extends State<HubErrorState> {
  bool _toastFired = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    if (widget.showToastOnce && !_toastFired) {
      _toastFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          HubToaster.error(context, widget.title);
        }
      });
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s16),
      padding: const EdgeInsets.all(AppTokens.s40),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTokens.r18),
        border: Border.all(color: p.dangerStrong.withValues(alpha: 0.32)),
        boxShadow: p.shCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.dangerBg,
                  p.dangerBg.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: p.dangerStrong.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: p.dangerStrong.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 28, color: p.dangerFg),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              color: p.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              widget.subtitle!,
              style: AppTypography.bodyMedium.copyWith(color: p.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.onRetry != null) ...[
            const SizedBox(height: AppTokens.s20),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(widget.retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
