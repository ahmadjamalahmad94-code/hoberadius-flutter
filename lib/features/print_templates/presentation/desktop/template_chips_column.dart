/// Right column of the Windows export room.
///
/// Compact list of template chips — each row shows a small gradient
/// swatch, the template name, a star button (set as default), a PDF
/// sample button, and a trash button. Selecting a chip drives the
/// preview + the PDF export buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../../core/theme/tokens.dart';
import '../../application/print_templates_controller.dart';
import '../../data/print_templates_repository.dart';
import '../../domain/print_template_model.dart';
import '../widgets/pdf_preview_launcher.dart';
import 'export_room_state.dart';

class TemplateChipsColumn extends ConsumerWidget {
  const TemplateChipsColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(printTemplatesProvider);
    final state = ref.watch(exportRoomControllerProvider);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.image_outlined),
                const SizedBox(width: AppTokens.s8),
                const Text(
                  'القوالب',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const Spacer(),
                templates.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (items) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Expanded(
              child: templates.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(visibleErrorMessage(e))),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد قوالب — افتح المصمم وأنشئ أول قالب.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  // On first paint, ensure the default template is
                  // auto-selected — same UX the web export center has.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final defaultId = _defaultIdFrom(items);
                    if (defaultId != null) {
                      ref
                          .read(exportRoomControllerProvider.notifier)
                          .rememberDefault(defaultId);
                    }
                  });
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _TemplateChip(
                      template: items[i],
                      selected: state.selectedTemplateId == items[i].id,
                      isDefault: _isDefault(items[i], state.defaultTemplateId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _defaultIdFrom(List<CardPrintTemplate> items) {
    for (final t in items) {
      final layout = t.layout;
      final flag = layout['is_default'];
      if (flag is bool && flag) return t.id;
      if (flag is num && flag != 0) return t.id;
    }
    return null;
  }

  bool _isDefault(CardPrintTemplate t, int? defaultId) {
    if (defaultId != null && defaultId == t.id) return true;
    final flag = t.layout['is_default'];
    return (flag is bool && flag) || (flag is num && flag != 0);
  }
}

class _TemplateChip extends ConsumerWidget {
  const _TemplateChip({
    required this.template,
    required this.selected,
    required this.isDefault,
  });
  final CardPrintTemplate template;
  final bool selected;
  final bool isDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = template.layout;
    final start = (layout['gradient_start'] as String?) ?? '#0f172a';
    final end = (layout['gradient_end'] as String?) ?? '#22a7bd';
    final accent = (layout['accent_color'] as String?) ?? '#f59e0b';

    return Material(
      color: selected
          ? const Color(0x1A22A7BD)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref
            .read(exportRoomControllerProvider.notifier)
            .selectTemplate(template.id),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF22A7BD)
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            boxShadow: isDefault
                ? const [
                    BoxShadow(
                      color: Color(0x66F59E0B),
                      blurRadius: 0,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _Swatch(start: start, end: end, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            template.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          _DefaultPill(),
                        ],
                      ],
                    ),
                    Text(
                      '${layout['design_preset'] ?? 'custom'} · '
                      '${template.cardsPerRow}×${template.cardsPerColumn}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isDefault
                    ? 'القالب الافتراضي حاليًا'
                    : 'اعتمد كقالب افتراضي',
                onPressed: () async {
                  await ref
                      .read(exportRoomControllerProvider.notifier)
                      .setDefault(template.id);
                },
                icon: Icon(
                  isDefault ? Icons.star : Icons.star_border,
                  color:
                      isDefault ? const Color(0xFFB45309) : AppTokens.textMuted,
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'PDF عينة',
                onPressed: () async {
                  final repo = ref.read(printTemplatesRepositoryProvider);
                  final bytes = await repo.exportPdf(template.id);
                  if (!context.mounted) return;
                  await PdfPreviewLauncher.show(
                    context,
                    pdfBytes: bytes,
                    fileName: 'sample-template-${template.id}.pdf',
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'حذف القالب',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حذف القالب'),
                      content: Text('حذف القالب «${template.name}» نهائيًا؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  await ref
                      .read(exportRoomControllerProvider.notifier)
                      .deleteTemplate(template.id);
                  ref.invalidate(printTemplatesProvider);
                },
                icon: const Icon(Icons.delete_outline),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.start,
    required this.end,
    required this.accent,
  });
  final String start;
  final String end;
  final String accent;

  @override
  Widget build(BuildContext context) {
    Color parse(String h) {
      final hex = h.startsWith('#') ? h.substring(1) : h;
      final intVal = int.tryParse(hex, radix: 16) ?? 0;
      // Add alpha when only 6 digits.
      return Color(hex.length == 8 ? intVal : (0xFF000000 | intVal));
    }

    return Container(
      width: 46,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [parse(start), parse(end)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: parse(accent), width: 3),
        ),
      ),
    );
  }
}

class _DefaultPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        border: Border.all(color: const Color(0xFFF59E0B)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: Color(0xFFB45309)),
          SizedBox(width: 3),
          Text(
            'افتراضي',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}
