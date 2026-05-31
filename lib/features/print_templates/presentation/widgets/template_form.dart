import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/app_card.dart';

/// Form panel for creating a new card-print template. Pure presentation:
/// the parent screen owns the [TextEditingController]s and the
/// `_orientation` / `_pageSize` / `_showQr` toggles, and is notified via
/// the callbacks below. Submit handling is delegated through [onSubmit].
class TemplateForm extends StatelessWidget {
  const TemplateForm({
    super.key,
    required this.formKey,
    required this.name,
    required this.row,
    required this.col,
    required this.width,
    required this.height,
    required this.ux,
    required this.uy,
    required this.px,
    required this.py,
    required this.qx,
    required this.qy,
    required this.font,
    required this.color,
    required this.orientation,
    required this.pageSize,
    required this.showQr,
    required this.saving,
    required this.onOrientation,
    required this.onPageSize,
    required this.onShowQr,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController row;
  final TextEditingController col;
  final TextEditingController width;
  final TextEditingController height;
  final TextEditingController ux;
  final TextEditingController uy;
  final TextEditingController px;
  final TextEditingController py;
  final TextEditingController qx;
  final TextEditingController qy;
  final TextEditingController font;
  final TextEditingController color;
  final String orientation;
  final String pageSize;
  final bool showQr;
  final bool saving;
  final ValueChanged<String> onOrientation;
  final ValueChanged<String> onPageSize;
  final ValueChanged<bool> onShowQr;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'إضافة قالب',
      icon: Icons.print_outlined,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'اسم القالب',
                helperText: 'اسم سهل لتعرف القالب عند الطباعة.',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'اكتب اسم القالب' : null,
            ),
            const SizedBox(height: AppTokens.s12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: orientation,
                    decoration: const InputDecoration(labelText: 'الاتجاه'),
                    items: const [
                      DropdownMenuItem(
                        value: 'portrait',
                        child: Text('عمودي'),
                      ),
                      DropdownMenuItem(
                        value: 'landscape',
                        child: Text('أفقي'),
                      ),
                    ],
                    onChanged: (v) => onOrientation(v ?? 'portrait'),
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: pageSize,
                    decoration: const InputDecoration(labelText: 'حجم الصفحة'),
                    items: const [
                      DropdownMenuItem(value: 'A4', child: Text('A4')),
                      DropdownMenuItem(
                        value: 'Letter',
                        child: Text('حجم الرسالة الأمريكي'),
                      ),
                    ],
                    onChanged: (v) => onPageSize(v ?? 'A4'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            _TwoFields(
              left: _NumberField(controller: row, label: 'كروت في الصف'),
              right: _NumberField(controller: col, label: 'كروت في العمود'),
            ),
            const SizedBox(height: AppTokens.s12),
            _TwoFields(
              left: _NumberField(controller: width, label: 'عرض الكرت mm'),
              right: _NumberField(controller: height, label: 'ارتفاع الكرت mm'),
            ),
            const SizedBox(height: AppTokens.s12),
            _TwoFields(
              left: _NumberField(controller: ux, label: 'اسم الدخول X'),
              right: _NumberField(controller: uy, label: 'اسم الدخول Y'),
            ),
            const SizedBox(height: AppTokens.s12),
            _TwoFields(
              left: _NumberField(controller: px, label: 'كلمة المرور X'),
              right: _NumberField(controller: py, label: 'كلمة المرور Y'),
            ),
            const SizedBox(height: AppTokens.s12),
            _TwoFields(
              left: _NumberField(controller: qx, label: 'QR X'),
              right: _NumberField(controller: qy, label: 'QR Y'),
            ),
            const SizedBox(height: AppTokens.s12),
            _TwoFields(
              left: _NumberField(controller: font, label: 'حجم الخط'),
              right: TextFormField(
                controller: color,
                decoration: const InputDecoration(labelText: 'اللون'),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: showQr,
              onChanged: onShowQr,
              title: const Text('إظهار QR'),
              subtitle: const Text('يحفظ الخيار داخل القالب فقط.'),
            ),
            const SizedBox(height: AppTokens.s12),
            ElevatedButton.icon(
              onPressed: saving ? null : onSubmit,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'جاري الحفظ...' : 'حفظ القالب'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({required this.left, required this.right});
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

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
          double.tryParse(v ?? '') == null ? 'اكتب رقمًا صحيحًا' : null,
    );
  }
}
