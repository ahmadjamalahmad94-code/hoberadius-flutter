import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import 'bg_image_picker.dart';

/// Editable designer controls for a print template — gradient / pattern /
/// colours / render-engine / QR styling + the strict background-image picker.
/// Writes the matching `layout_json` keys consumed by the Dart render builder
/// (and the web `card_renderer.py`), so a card renders the same in Flutter
/// and on the web.
class TemplateDesignerSection extends StatelessWidget {
  const TemplateDesignerSection({
    super.key,
    required this.renderEngine,
    required this.pattern,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    required this.textColor,
    required this.surface,
    required this.qrColor,
    required this.qrSizePct,
    required this.bgImageDataUrl,
    required this.onRenderEngine,
    required this.onPattern,
    required this.onBgImage,
    required this.onBgClear,
  });

  final String renderEngine;
  final String pattern;
  final TextEditingController gradientStart;
  final TextEditingController gradientEnd;
  final TextEditingController accent;
  final TextEditingController textColor;
  final TextEditingController surface;
  final TextEditingController qrColor;
  final TextEditingController qrSizePct;
  final String bgImageDataUrl;
  final ValueChanged<String> onRenderEngine;
  final ValueChanged<String> onPattern;
  final ValueChanged<String> onBgImage;
  final VoidCallback onBgClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'مصمّم القالب',
      icon: Icons.palette_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: renderEngine,
            decoration: const InputDecoration(labelText: 'محرّك العرض واللغة'),
            items: const [
              DropdownMenuItem(
                value: 'ar_horizontal',
                child: Text('عربي - أفقي'),
              ),
              DropdownMenuItem(
                value: 'ar_vertical',
                child: Text('عربي - عمودي'),
              ),
              DropdownMenuItem(
                value: 'en_horizontal',
                child: Text('إنجليزي - أفقي'),
              ),
              DropdownMenuItem(
                value: 'en_vertical',
                child: Text('إنجليزي - عمودي'),
              ),
            ],
            onChanged: (v) => onRenderEngine(v ?? 'ar_horizontal'),
          ),
          const SizedBox(height: AppTokens.s12),
          DropdownButtonFormField<String>(
            initialValue: pattern,
            decoration: const InputDecoration(labelText: 'النقشة الخلفية'),
            items: const [
              DropdownMenuItem(value: 'signal', child: Text('إشارة')),
              DropdownMenuItem(value: 'wave', child: Text('موجة')),
              DropdownMenuItem(value: 'grid', child: Text('شبكة')),
              DropdownMenuItem(value: 'clean', child: Text('بدون نقشة')),
            ],
            onChanged: (v) => onPattern(v ?? 'signal'),
          ),
          const SizedBox(height: AppTokens.s12),
          _ColorRow(
            left: _ColorField(controller: gradientStart, label: 'تدرّج البداية'),
            right: _ColorField(controller: gradientEnd, label: 'تدرّج النهاية'),
          ),
          const SizedBox(height: AppTokens.s12),
          _ColorRow(
            left: _ColorField(controller: accent, label: 'لون التمييز'),
            right: _ColorField(controller: textColor, label: 'لون النص'),
          ),
          const SizedBox(height: AppTokens.s12),
          _ColorRow(
            left: _ColorField(controller: surface, label: 'لون البطاقة الداخلية'),
            right: _ColorField(controller: qrColor, label: 'لون رمز QR'),
          ),
          const SizedBox(height: AppTokens.s12),
          TextFormField(
            controller: qrSizePct,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'حجم رمز QR (%)',
              helperText: 'اتركه فارغًا للحجم الافتراضي (8%–48%).',
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          const Text(
            'صورة الخلفية',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTokens.s8),
          BgImagePicker(
            onImageBytes: (bytes, mime, fileName) =>
                onBgImage(_toDataUrl(bytes, mime)),
            onClear: onBgClear,
            initialFileName: bgImageDataUrl.isEmpty ? null : 'صورة محفوظة',
          ),
        ],
      ),
    );
  }

  static String _toDataUrl(Uint8List bytes, String mime) {
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: AppTokens.s8),
        Expanded(child: right),
      ],
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(labelText: label, hintText: '#2BAACC'),
    );
  }
}
