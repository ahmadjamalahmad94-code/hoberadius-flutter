import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/print_template_model.dart';
import 'template_metric.dart';

/// Visual preview of a saved print template — renders a single sample
/// card at the correct aspect ratio with the username / password / QR
/// placeholders positioned according to the template's coordinates.
class TemplatePreviewCard extends StatelessWidget {
  const TemplatePreviewCard({super.key, required this.preview});
  final PrintTemplatePreview preview;

  @override
  Widget build(BuildContext context) {
    final width = _num(preview.card['width_mm'], 85);
    final height = _num(preview.card['height_mm'], 54);
    final ratio = width <= 0 || height <= 0 ? 1.57 : width / height;
    final font = _num(preview.card['font_size'], 12);
    final color = _parseColor(preview.card['color']?.toString());
    final userPlace = _place(preview.placements['username']);
    final passPlace = _place(preview.placements['password']);
    final qrPlace = _place(preview.placements['qr']);
    final username = preview.sample['username']?.toString() ?? 'CARD1234';
    return AppCard(
      title: 'معاينة بصرية',
      icon: Icons.visibility_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AspectRatio(
                aspectRatio: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.r14),
                    border: Border.all(color: AppTokens.brand),
                    gradient: const LinearGradient(
                      colors: [Colors.white, AppTokens.infoBg],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      _PreviewText(
                        text: username,
                        placement: userPlace,
                        color: color,
                        fontSize: font,
                      ),
                      _PreviewText(
                        text: '••••••••',
                        placement: passPlace,
                        color: color,
                        fontSize: font,
                      ),
                      if (preview.qrSupported)
                        _PreviewQr(placement: qrPlace, color: color),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              TemplateMetric(label: 'محرك الرسم', value: preview.renderer),
              TemplateMetric(
                label: 'كروت في الصفحة',
                value: '${preview.cardsPerPage}',
              ),
              TemplateMetric(
                label: 'التصدير',
                value:
                    preview.exportGenerated ? 'تم التجهيز' : 'PDF متاح',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'العينة: $username. ملف PDF متاح من زر التصدير.',
            style: const TextStyle(color: AppTokens.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PreviewText extends StatelessWidget {
  const _PreviewText({
    required this.text,
    required this.placement,
    required this.color,
    required this.fontSize,
  });

  final String text;
  final Offset placement;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * placement.dx / 100,
                top: constraints.maxHeight * placement.dy / 100,
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize.clamp(8, 28),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewQr extends StatelessWidget {
  const _PreviewQr({required this.placement, required this.color});

  final Offset placement;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * placement.dx / 100,
                top: constraints.maxHeight * placement.dy / 100,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'QR',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

double _num(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

Offset _place(Object? value) {
  if (value is Map) {
    return Offset(
      _num(value['x_percent'], 12),
      _num(value['y_percent'], 28),
    );
  }
  return const Offset(12, 28);
}

Color _parseColor(String? value) {
  final hex = (value ?? '#1f2937').replaceFirst('#', '');
  final parsed = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
  return Color(parsed ?? 0xff1f2937);
}
