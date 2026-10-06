import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ota/ota_dialogs.dart';
import '../../../core/ota/ota_updater.dart';
import '../../../core/ota/release_notes.dart';
import '../../../core/theme/tokens.dart';

/// «حول التطبيق والتحديثات» (owner 2026-10-07): the version and the patch
/// running now, a «فحص التحديثات» button that works any time, install with
/// the real failure reason, and the history of what each update brought.
class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

final releaseNotesHistoryProvider =
    FutureProvider.autoDispose<List<ReleaseNote>>((ref) async {
  final all = await fetchReleaseNotes();
  final list = [...all]..sort((a, b) => b.patch.compareTo(a.patch));
  return list;
});

class _AboutScreenState extends ConsumerState<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    final ota = ref.watch(otaControllerProvider);
    final ctrl = ref.read(otaControllerProvider.notifier);
    final notes = ref.watch(releaseNotesHistoryProvider);
    final patch = ota.currentPatch;

    final (String status, Color tone) = switch (ota.phase) {
      OtaPhase.checking => ('جاري الفحص…', AppTokens.brand),
      OtaPhase.available => ('في تحديث جديد جاهز للتنزيل', AppTokens.brand),
      OtaPhase.downloading => ('جاري تنزيل التحديث…', AppTokens.brand),
      OtaPhase.readyToRestart => (
          'التحديث نزل — أعد فتح التطبيق ليتطبّق',
          AppTokens.green
        ),
      OtaPhase.upToDate => ('عندك آخر تحديث', AppTokens.green),
      OtaPhase.failed => ('تعذّر تنزيل التحديث', AppTokens.red),
      _ => ('اضغط «فحص التحديثات»', AppTokens.textMuted),
    };

    return ListView(
      padding: const EdgeInsets.all(AppTokens.s16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'حول التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.s12),
                const _Row(label: 'رقم الإصدار', value: kAppRelease),
                _Row(
                  key: const ValueKey('about-patch'),
                  label: 'رقم التحديث',
                  value: patch == null
                      ? 'بدون تحديثات (النسخة الأصلية)'
                      : '#$patch',
                ),
                const Divider(height: AppTokens.s24),
                Text(
                  status,
                  key: const ValueKey('about-status'),
                  style: TextStyle(color: tone, fontWeight: FontWeight.w700),
                ),
                if (ota.phase == OtaPhase.failed &&
                    ota.error.trim().isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s8),
                  SelectableText(
                    'السبب: ${ota.error.trim()}',
                    key: const ValueKey('about-error'),
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (!ctrl.isAvailable) ...[
                  const SizedBox(height: AppTokens.s8),
                  const Text(
                    'التحديث التلقائي غير متاح على هالنسخة من التطبيق.',
                    style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: AppTokens.s12),
                Wrap(
                  spacing: AppTokens.s8,
                  runSpacing: AppTokens.s8,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('about-check'),
                      onPressed: ota.phase == OtaPhase.checking ||
                              ota.phase == OtaPhase.downloading
                          ? null
                          : () => ctrl.check(force: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('فحص التحديثات'),
                    ),
                    if (ota.phase == OtaPhase.available ||
                        ota.phase == OtaPhase.failed)
                      OutlinedButton.icon(
                        key: const ValueKey('about-install'),
                        onPressed: ctrl.install,
                        icon: const Icon(Icons.download),
                        label: Text(ota.phase == OtaPhase.failed
                            ? 'إعادة المحاولة'
                            : 'تنزيل التحديث',),
                      ),
                  ],
                ),
                if (ota.phase == OtaPhase.downloading) ...[
                  const SizedBox(height: AppTokens.s12),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'سجل التحديثات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppTokens.s8),
                notes.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppTokens.s12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const Text(
                    'تعذّر تحميل سجل التحديثات.',
                    style: TextStyle(color: AppTokens.textMuted),
                  ),
                  data: (list) => list.isEmpty
                      ? const Text(
                          'لا يوجد سجل بعد.',
                          style: TextStyle(color: AppTokens.textMuted),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final n in list)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppTokens.s12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تحديث #${n.patch}'
                                      '${n.date.isEmpty ? '' : ' · ${n.date}'}'
                                      '${patch != null && n.patch == patch ? ' (المثبّت)' : ''}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: patch != null && n.patch > patch
                                            ? AppTokens.brand
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ReleaseNotesList(items: n.items),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppTokens.textMuted)),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
