import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'ota_updater.dart';

/// Thin strip above the shell content: shown only while a patch downloads or
/// once it is ready («أعد فتح التطبيق»). Invisible otherwise.
class OtaBanner extends ConsumerWidget {
  const OtaBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ota = ref.watch(otaControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final (String text, IconData icon, bool busy) = switch (ota.phase) {
      OtaPhase.downloading => (
          'يُنزَّل تحديثٌ صغير في الخلفية…',
          Icons.cloud_download_outlined,
          true,
        ),
      OtaPhase.restartRequired => (
          'تحديثٌ جاهز — أغلق التطبيق وافتحه ليُطبَّق.',
          Icons.system_update_alt,
          false,
        ),
      _ => ('', Icons.info_outline, false),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s8,
          ),
          child: Row(
            children: [
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 18, color: scheme.onPrimaryContainer),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
              if (!busy)
                IconButton(
                  tooltip: 'إخفاء',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      ref.read(otaControllerProvider.notifier).dismiss(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
