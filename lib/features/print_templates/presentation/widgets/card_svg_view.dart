import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/card_renderer_svg.dart';
import '../../domain/card_render_model.dart';

/// Displays a [CardRenderModel] as inline SVG via `flutter_svg`.
///
/// The widget is a thin wrapper around [SvgPicture.string]; the SVG
/// itself owns the aspect ratio (`viewBox`) and the `contain`
/// behaviour (`preserveAspectRatio="xMidYMid meet"`), so it scales
/// uniformly inside any parent constraint — exactly the way the web
/// preview behaves inside the designer canvas.
class CardSvgView extends StatelessWidget {
  const CardSvgView({
    super.key,
    required this.model,
    this.maskPassword = true,
    this.semanticsLabel,
  });

  final CardRenderModel model;
  final bool maskPassword;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final svg = renderCardSvg(model, maskPassword: maskPassword);
    return SvgPicture.string(
      svg,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel ?? 'card preview ${model.cardId}',
    );
  }
}
