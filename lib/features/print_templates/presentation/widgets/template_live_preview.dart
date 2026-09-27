import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/card_render_model_builder.dart';
import 'card_svg_view.dart';

/// Live, in-place preview of the print-template designer. Rebuilds whenever any
/// designer field changes ([listenable] = the text controllers; dropdown/picker
/// changes arrive via the parent's setState) and renders the real SVG engine
/// (same renderer the export PDF uses), so what the operator designs is exactly
/// what prints.
class TemplateLivePreview extends StatelessWidget {
  const TemplateLivePreview({
    super.key,
    required this.buildTemplate,
    required this.listenable,
  });

  /// Returns the template map (with `layout_json`) for the current designer
  /// state — called on every rebuild so live edits reflect immediately.
  final Map<String, dynamic> Function() buildTemplate;
  final Listenable listenable;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'معاينة حية',
      icon: Icons.visibility_outlined,
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final model = buildCardRenderModel(
            buildTemplate(),
            card: const {
              'id': 0,
              'username': 'CARD1234',
              'password': 'pw1234',
            },
          );
          final aspect = model.canvas.width / model.canvas.height;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        border: Border.all(color: AppTokens.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        child: CardSvgView(model: model),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              const Text(
                'المعاينة تتحدّث فورًا مع تعديل التصميم — كلمة المرور مُقنّعة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTokens.textMuted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}
