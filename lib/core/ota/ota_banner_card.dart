import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'ota_updater.dart';

/// A clear «يوجد تحديث جديد» bar for the dashboard and the notifications
/// page — a pop-up alone is easy to miss among many notifications (owner,
/// 2026-09-28). Shown while an update is available / downloading / ready,
/// whatever «لاحقًا» said; hidden otherwise (and on web / plain builds).
class OtaBannerCard extends ConsumerWidget {
  const OtaBannerCard({super.key, this.bottomGap = AppTokens.s12});
  final double bottomGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ota = ref.watch(otaControllerProvider);
    final (String title, String body, String action, IconData icon) =
        switch (ota.phase) {
      OtaPhase.available => (
          'يوجد تحديث جديد للتطبيق',
          'ثبّته الآن ليظهر آخر ما وصل من تحسينات.',
          'تثبيت',
          Icons.system_update,
        ),
      OtaPhase.downloading => (
          'جاري تنزيل التحديث…',
          'لا تغلق التطبيق.',
          '',
          Icons.cloud_download_outlined,
        ),
      OtaPhase.readyToRestart => (
          'التحديث جاهز',
          'أعد تشغيل التطبيق لتظهر التعديلات.',
          'إعادة التشغيل',
          Icons.restart_alt,
        ),
      _ => ('', '', '', Icons.info_outline),
    };
    if (title.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [AppTokens.brandDeep, AppTokens.brand],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTokens.brand.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    body,
                    style: text.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            if (action.isNotEmpty) const SizedBox(width: AppTokens.s8),
            if (action.isNotEmpty)
              FilledButton(
                onPressed: () =>
                    ref.read(otaControllerProvider.notifier).reopen(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTokens.brandInk,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle:
                      text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                child: Text(action),
              ),
          ],
        ),
      ),
    );
  }
}
