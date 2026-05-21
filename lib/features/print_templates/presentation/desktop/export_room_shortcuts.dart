/// Windows keyboard shortcuts for the print-templates export room.
///
/// Each Shortcut maps to an Intent that triggers a method on the
/// [ExportRoomController]. Mounted only when
/// `PlatformCapabilities.isWindows` — mobile builds register no
/// shortcuts, no keyboard listeners.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/platform_capabilities.dart';
import '../../data/print_templates_repository.dart';
import '../widgets/pdf_preview_launcher.dart';
import 'export_room_state.dart';

// ── Intents ───────────────────────────────────────────────────────

class _ExportPdfIntent extends Intent {
  const _ExportPdfIntent();
}

class _CleanupFixturesIntent extends Intent {
  const _CleanupFixturesIntent();
}

class _CloseDrawerIntent extends Intent {
  const _CloseDrawerIntent();
}

/// Wraps a child with the Windows-only shortcut bindings:
///   Ctrl + P  → trigger "تصدير PDF للحزمة" for the selected template
///   Ctrl + Shift + X → trigger "تنظيف القوالب التجريبية"
///   Escape    → close any open designer drawer / dialog (delegated
///                back to Navigator.maybePop)
class ExportRoomShortcuts extends ConsumerWidget {
  const ExportRoomShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!PlatformCapabilities.isWindows) return child;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyP, control: true):
            _ExportPdfIntent(),
        SingleActivator(LogicalKeyboardKey.keyX, control: true, shift: true):
            _CleanupFixturesIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _CloseDrawerIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ExportPdfIntent: CallbackAction<_ExportPdfIntent>(
            onInvoke: (_) => _exportPdf(context, ref),
          ),
          _CleanupFixturesIntent: CallbackAction<_CleanupFixturesIntent>(
            onInvoke: (_) => _cleanup(context, ref),
          ),
          _CloseDrawerIntent: CallbackAction<_CloseDrawerIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  Future<Object?> _exportPdf(BuildContext context, WidgetRef ref) async {
    final state = ref.read(exportRoomControllerProvider);
    if (state.selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر قالبًا أولًا قبل التصدير')),
      );
      return null;
    }
    final repo = ref.read(printTemplatesRepositoryProvider);
    final bytes = await repo.exportPdf(
      state.selectedTemplateId!,
      batchId: state.selectedBatchId,
      overrides: state.overrides,
    );
    if (!context.mounted) return null;
    await PdfPreviewLauncher.show(
      context,
      pdfBytes: bytes,
      fileName: state.selectedBatchId != null
          ? 'cards-batch-${state.selectedBatchId}-template-${state.selectedTemplateId}.pdf'
          : 'cards-template-${state.selectedTemplateId}.pdf',
    );
    return null;
  }

  Future<Object?> _cleanup(BuildContext context, WidgetRef ref) async {
    final purged = await ref
        .read(exportRoomControllerProvider.notifier)
        .cleanupFixtures();
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          purged != null && purged > 0
              ? 'تم تنظيف $purged قالب اختبار من القائمة.'
              : 'لا توجد قوالب اختبار للتنظيف.',
        ),
      ),
    );
    return null;
  }
}
