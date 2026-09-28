import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'app_restart.dart';
import 'ota_updater.dart';

/// Wraps the shell: checks for an update on launch and on resume, and shows
/// the update pop-up whenever one is available or ready to apply.
class OtaDialogHost extends ConsumerStatefulWidget {
  const OtaDialogHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<OtaDialogHost> createState() => _OtaDialogHostState();
}

class _OtaDialogHostState extends ConsumerState<OtaDialogHost>
    with WidgetsBindingObserver {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(otaControllerProvider.notifier).check(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(otaControllerProvider.notifier).check();
    }
  }

  Future<void> _show() async {
    if (_open || !mounted) return;
    _open = true;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const OtaUpdateDialog(),
    );
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OtaState>(otaControllerProvider, (prev, next) {
      final wantsDialog = !next.snoozed &&
          (next.phase == OtaPhase.available ||
              next.phase == OtaPhase.readyToRestart);
      if (wantsDialog) _show();
    });
    return widget.child;
  }
}

/// The update pop-up. One dialog walks through every step so it never
/// flickers: available, downloading (progress), ready (restart) or failed.
class OtaUpdateDialog extends ConsumerStatefulWidget {
  const OtaUpdateDialog({super.key});

  @override
  ConsumerState<OtaUpdateDialog> createState() => _OtaUpdateDialogState();
}

class _OtaUpdateDialogState extends ConsumerState<OtaUpdateDialog> {
  bool? _canRestart;

  @override
  void initState() {
    super.initState();
    AppRestart.isSupported().then((v) {
      if (mounted) setState(() => _canRestart = v);
    });
  }

  void _close() {
    ref.read(otaControllerProvider.notifier).later();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ota = ref.watch(otaControllerProvider);
    final notifier = ref.read(otaControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final closesInstead = _canRestart == false;

    final (IconData icon, Color tone, String title, String body) =
        switch (ota.phase) {
      OtaPhase.downloading => (
          Icons.cloud_download_outlined,
          AppTokens.brand,
          'جاري التحديث…',
          'يُنزَّل التحديث الآن، لا تغلق التطبيق.',
        ),
      OtaPhase.readyToRestart => (
          Icons.check_circle_outline,
          AppTokens.green,
          'التحديث جاهز',
          closesInstead
              ? 'اضغط «إغلاق التطبيق» ثم افتحه من جديد لتظهر التعديلات.'
              : 'أعد تشغيل التطبيق لتظهر التعديلات.',
        ),
      OtaPhase.failed => (
          Icons.error_outline,
          AppTokens.red,
          'تعذّر تنزيل التحديث',
          'تحقّق من الاتصال بالإنترنت ثم أعد المحاولة.',
        ),
      _ => (
          Icons.system_update_outlined,
          AppTokens.brand,
          'يوجد تحديث جديد',
          'تحديث جديد للتطبيق جاهز. التثبيت يعيد تشغيل التطبيق.',
        ),
    };

    final List<Widget> buttons = switch (ota.phase) {
      OtaPhase.downloading => const [],
      OtaPhase.readyToRestart => [
          _Btn(label: 'لاحقًا', onPressed: _close),
          _Btn(
            label: closesInstead ? 'إغلاق التطبيق' : 'إعادة التشغيل',
            icon: Icons.restart_alt,
            primary: true,
            onPressed: AppRestart.restartOrClose,
          ),
        ],
      OtaPhase.failed => [
          _Btn(label: 'إغلاق', onPressed: _close),
          _Btn(
            label: 'إعادة المحاولة',
            icon: Icons.refresh,
            primary: true,
            onPressed: notifier.install,
          ),
        ],
      OtaPhase.available => [
          _Btn(label: 'لاحقًا', onPressed: _close),
          _Btn(
            label: 'تثبيت',
            icon: Icons.download_outlined,
            primary: true,
            onPressed: notifier.install,
          ),
        ],
      // Checked again and nothing to do (e.g. patch withdrawn): just close.
      _ => [_Btn(label: 'إغلاق', onPressed: _close)],
    };

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tone, size: 30),
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppTokens.textMuted),
              ),
              if (ota.phase == OtaPhase.downloading) ...[
                const SizedBox(height: AppTokens.s16),
                const _DownloadProgress(),
              ],
              if (buttons.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (var i = 0; i < buttons.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppTokens.s8),
                      Expanded(child: buttons[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shorebird reports no download percentage, so the bar eases towards ~90%
/// while the download runs; the dialog switches to «جاهز» when it is done.
class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.05, end: 0.9),
      duration: const Duration(seconds: 12),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 8,
          backgroundColor: AppTokens.brand.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(46)),
      // Derived from the theme so the app font (Cairo) is kept.
      textStyle: WidgetStatePropertyAll(
        Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
    final child = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    if (!primary) {
      return OutlinedButton(onPressed: onPressed, style: style, child: child);
    }
    if (icon == null) {
      return FilledButton(onPressed: onPressed, style: style, child: child);
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: child,
    );
  }
}
