/// Center column of the Windows export room.
///
/// Renders the SVG preview of the selected template (with the current
/// overrides) via [CardSvgView]. The viewport implements the same
/// `object-fit:contain` semantics the web's `.pr-canvas-wrap` uses
/// after the P5 fix — the card never clips, never zooms beyond what
/// the viewport can hold.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../application/print_templates_controller.dart';
import '../../domain/card_render_model.dart';
import '../widgets/card_svg_view.dart';
import 'export_room_state.dart';

class PreviewColumn extends ConsumerWidget {
  const PreviewColumn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportRoomControllerProvider);
    final templates = ref.watch(printTemplatesProvider);

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
                const Icon(Icons.visibility_outlined),
                const SizedBox(width: AppTokens.s8),
                const Text(
                  'معاينة حية',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const Spacer(),
                _LockedPill(),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            Expanded(
              child: templates.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (items) {
                  final selected = state.selectedTemplateId == null
                      ? null
                      : items.firstWhere(
                          (t) => t.id == state.selectedTemplateId,
                          orElse: () => items.isEmpty
                              ? items.first
                              : items.first, // safe — empty handled below
                        );
                  if (items.isEmpty) {
                    return const Center(
                      child:
                          Text('لا توجد قوالب — افتح المصمم وأنشئ أول قالب.'),
                    );
                  }
                  if (selected == null) {
                    return const Center(
                      child: Text(
                        'اختر قالبًا من القائمة لرؤية المعاينة',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );
                  }
                  final model = buildModelFor(
                    selected,
                    state,
                    sampleCard: const {
                      'id': '',
                      'username': 'SAMPLE',
                      'password': '********',
                    },
                  );
                  return _PreviewViewport(model: model);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12),
          SizedBox(width: 4),
          Text(
            'تصميم مغلق',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Implements the same `object-fit: contain` formula the web uses
/// in `.pr-canvas-wrap .pr-card-preview` after the P5 fit-to-viewport
/// fix:
///   width  = min(viewport_w, viewport_h * canvas_aspect_w_over_h)
///   height = aspect-derived
/// The SVG's own viewBox + preserveAspectRatio handles the rest.
class _PreviewViewport extends StatelessWidget {
  const _PreviewViewport({required this.model});
  final CardRenderModel model;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final viewportW = c.maxWidth;
        final viewportH = c.maxHeight;
        final aspect = model.canvas.width / model.canvas.height;
        final cardW = (viewportH * aspect).clamp(0.0, viewportW).toDouble();
        final cardH = cardW / aspect;
        return Center(
          child: SizedBox(
            width: cardW,
            height: cardH,
            child: CardSvgView(model: model),
          ),
        );
      },
    );
  }
}
