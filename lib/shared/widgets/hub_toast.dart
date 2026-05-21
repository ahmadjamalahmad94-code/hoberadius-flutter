import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/tokens.dart';

/// Canonical floating toast — Flutter mirror of the web `uf-toast` block
/// from `templates/radius/users_form.html`.
///
/// Two surfaces:
///
///   * [HubToast] — the visual card itself, useful in the gallery and
///     for golden tests.
///   * [HubToaster] — the imperative entry point: enqueue toasts onto
///     the nearest [Overlay] with a single call. Stacks newest at the
///     bottom-start corner and auto-dismisses after [defaultDuration].
///
/// ```dart
/// HubToaster.success(context, 'تم الحفظ بنجاح');
/// HubToaster.error(context, 'فشل الاتصال');
/// HubToaster.info(context, 'جاري المزامنة');
/// ```
enum HubToastKind { success, error, info }

class HubToast extends StatelessWidget {
  const HubToast({
    super.key,
    required this.message,
    this.kind = HubToastKind.success,
    this.icon,
    this.onDismiss,
  });

  final String message;
  final HubToastKind kind;
  final IconData? icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (accent, fg, defaultIcon) = switch (kind) {
      HubToastKind.success => (
        p.successStrong,
        p.successFg,
        Icons.check_circle,
      ),
      HubToastKind.error => (
        p.dangerRose,
        p.dangerFg,
        Icons.error_outline,
      ),
      HubToastKind.info => (
        p.infoStrong,
        p.infoFg,
        Icons.info_outline,
      ),
    };

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
        padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 12, 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(AppTokens.r10),
          border: BorderDirectional(
            start: BorderSide(color: accent, width: 4),
            top: BorderSide(color: p.border),
            bottom: BorderSide(color: p.border),
            end: BorderSide(color: p.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon ?? defaultIcon, size: 18, color: fg),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 6),
              InkResponse(
                radius: 16,
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: p.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Imperative entry point for showing [HubToast]s via the nearest
/// [Overlay]. Stateless — every call creates a fresh entry and
/// auto-removes it after [duration].
class HubToaster {
  HubToaster._();

  static const Duration defaultDuration = Duration(milliseconds: 3200);
  static const Duration animationDuration = Duration(milliseconds: 220);

  static final _Toaster _toaster = _Toaster();

  /// Generic entry. Returns a handle the caller can use to dismiss
  /// the toast early.
  static HubToastHandle show(
    BuildContext context,
    String message, {
    HubToastKind kind = HubToastKind.success,
    Duration duration = defaultDuration,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    return _toaster.enqueue(
      overlay: overlay,
      message: message,
      kind: kind,
      duration: duration,
      icon: icon,
    );
  }

  static HubToastHandle success(BuildContext context, String message) =>
      show(context, message, kind: HubToastKind.success);

  static HubToastHandle error(BuildContext context, String message) =>
      show(context, message, kind: HubToastKind.error);

  static HubToastHandle info(BuildContext context, String message) =>
      show(context, message, kind: HubToastKind.info);
}

/// Handle returned by [HubToaster.show]. Call [dismiss] to remove the
/// toast before its auto-dismiss timer fires.
class HubToastHandle {
  HubToastHandle._(this._entry);
  final _ToastEntry _entry;
  void dismiss() => _entry.dismiss();
}

// ───────────────────────────────────────────────────────────────
//  Internal: overlay manager
// ───────────────────────────────────────────────────────────────
class _Toaster {
  final _entries = <_ToastEntry>{};

  HubToastHandle enqueue({
    required OverlayState overlay,
    required String message,
    required HubToastKind kind,
    required Duration duration,
    IconData? icon,
  }) {
    final entry = _ToastEntry(
      overlay: overlay,
      message: message,
      kind: kind,
      duration: duration,
      icon: icon,
      onRemoved: _entries.remove,
    );
    _entries.add(entry);
    entry.show();
    return HubToastHandle._(entry);
  }
}

class _ToastEntry {
  _ToastEntry({
    required this.overlay,
    required this.message,
    required this.kind,
    required this.duration,
    required this.icon,
    required this.onRemoved,
  });

  final OverlayState overlay;
  final String message;
  final HubToastKind kind;
  final Duration duration;
  final IconData? icon;
  final void Function(_ToastEntry) onRemoved;

  OverlayEntry? _entry;
  Timer? _autoDismiss;
  final _controller = ValueNotifier<bool>(false);
  bool _disposed = false;

  void show() {
    _entry = OverlayEntry(builder: _build);
    overlay.insert(_entry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.value = true;
    });
    _autoDismiss = Timer(duration, dismiss);
  }

  void dismiss() {
    if (_disposed) return;
    _controller.value = false;
    _autoDismiss?.cancel();
    Future<void>.delayed(HubToaster.animationDuration, _remove);
  }

  void _remove() {
    if (_disposed) return;
    _disposed = true;
    _entry?.remove();
    _entry = null;
    _controller.dispose();
    onRemoved(this);
  }

  Widget _build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.bottomStart,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
          child: ValueListenableBuilder<bool>(
            valueListenable: _controller,
            builder: (context, shown, child) {
              return AnimatedSlide(
                duration: HubToaster.animationDuration,
                curve: AppTokens.motionEase,
                offset: shown
                    ? Offset.zero
                    : const Offset(-0.08, 0),
                child: AnimatedOpacity(
                  duration: HubToaster.animationDuration,
                  curve: AppTokens.motionEase,
                  opacity: shown ? 1 : 0,
                  child: child,
                ),
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: HubToast(
                message: message,
                kind: kind,
                icon: icon,
                onDismiss: dismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
