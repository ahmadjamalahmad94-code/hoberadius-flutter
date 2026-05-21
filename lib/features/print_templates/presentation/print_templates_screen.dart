import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/status_pill.dart';
import '../data/print_templates_repository.dart';
import '../domain/print_template_model.dart';

final printTemplatesProvider =
    FutureProvider.autoDispose<List<CardPrintTemplate>>((ref) {
  return ref.watch(printTemplatesRepositoryProvider).list();
});

class PrintTemplatesScreen extends ConsumerStatefulWidget {
  const PrintTemplatesScreen({super.key});

  @override
  ConsumerState<PrintTemplatesScreen> createState() =>
      _PrintTemplatesScreenState();
}

class _PrintTemplatesScreenState extends ConsumerState<PrintTemplatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _row = TextEditingController(text: '2');
  final _col = TextEditingController(text: '5');
  final _width = TextEditingController(text: '85');
  final _height = TextEditingController(text: '54');
  final _ux = TextEditingController(text: '10');
  final _uy = TextEditingController(text: '15');
  final _px = TextEditingController(text: '10');
  final _py = TextEditingController(text: '25');
  final _qx = TextEditingController(text: '60');
  final _qy = TextEditingController(text: '12');
  final _font = TextEditingController(text: '12');
  final _color = TextEditingController(text: '#1f2937');
  String _orientation = 'portrait';
  String _pageSize = 'A4';
  bool _showQr = true;
  bool _saving = false;
  bool _previewing = false;
  bool _exportingPdf = false;
  PrintTemplatePreview? _preview;

  @override
  void dispose() {
    for (final c in [
      _name,
      _row,
      _col,
      _width,
      _height,
      _ux,
      _uy,
      _px,
      _py,
      _qx,
      _qy,
      _font,
      _color,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(printTemplatesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'قوالب طباعة الكروت',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTokens.sidebarBg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'تحديث',
              onPressed: () => ref.invalidate(printTemplatesProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s12),
        const AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTokens.amber),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'القوالب محفوظة وقابلة لإعادة الاستخدام، والمعاينة بصرية للمواضع والألوان، ويمكن تنزيل PDF حقيقي لنموذج القالب.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        if (_preview != null) ...[
          const SizedBox(height: AppTokens.s12),
          _PreviewCard(preview: _preview!),
        ],
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final form = _TemplateForm(
              formKey: _formKey,
              name: _name,
              row: _row,
              col: _col,
              width: _width,
              height: _height,
              ux: _ux,
              uy: _uy,
              px: _px,
              py: _py,
              qx: _qx,
              qy: _qy,
              font: _font,
              color: _color,
              orientation: _orientation,
              pageSize: _pageSize,
              showQr: _showQr,
              saving: _saving,
              onOrientation: (v) => setState(() => _orientation = v),
              onPageSize: (v) => setState(() => _pageSize = v),
              onShowQr: (v) => setState(() => _showQr = v),
              onSubmit: _save,
            );
            final list = templates.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر تحميل قوالب الطباعة',
                subtitle: '$e',
              ),
              data: (items) => _TemplateList(
                items: items,
                previewing: _previewing,
                exportingPdf: _exportingPdf,
                onPreview: _previewTemplate,
                onExportPdf: _exportPdf,
              ),
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [form, const SizedBox(height: AppTokens.s12), list],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 420, child: form),
                const SizedBox(width: AppTokens.s12),
                Expanded(child: list),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(printTemplatesRepositoryProvider).create(
            name: _name.text.trim(),
            orientation: _orientation,
            cardsPerRow: _toInt(_row.text, 2),
            cardsPerColumn: _toInt(_col.text, 5),
            pageSize: _pageSize,
            showQr: _showQr,
            usernameX: _toDouble(_ux.text),
            usernameY: _toDouble(_uy.text),
            passwordX: _toDouble(_px.text),
            passwordY: _toDouble(_py.text),
            qrX: _toDouble(_qx.text),
            qrY: _toDouble(_qy.text),
            fontSize: _toInt(_font.text, 12),
            color: _color.text.trim(),
            cardWidthMm: _toDouble(_width.text, 85),
            cardHeightMm: _toDouble(_height.text, 54),
          );
      _name.clear();
      ref.invalidate(printTemplatesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ قالب الطباعة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _previewTemplate(CardPrintTemplate item) async {
    setState(() => _previewing = true);
    try {
      final result = await ref.read(printTemplatesRepositoryProvider).preview(
            item.id,
            sampleUsername: 'CARD1234',
          );
      if (!mounted) return;
      setState(() => _preview = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _exportPdf(CardPrintTemplate item) async {
    setState(() => _exportingPdf = true);
    try {
      final bytes = await ref.read(printTemplatesRepositoryProvider).exportPdf(
            item.id,
            sampleUsername: 'CARD1234',
          );
      await FileSaver.instance.saveFile(
        name: 'print-template-${item.id}',
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل PDF لنموذج القالب')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تصدير PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }
}

class _TemplateForm extends StatelessWidget {
  const _TemplateForm({
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
                      DropdownMenuItem(value: 'portrait', child: Text('عمودي')),
                      DropdownMenuItem(value: 'landscape', child: Text('أفقي')),
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
                      DropdownMenuItem(value: 'Letter', child: Text('Letter')),
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

class _TemplateList extends StatelessWidget {
  const _TemplateList({
    required this.items,
    required this.previewing,
    required this.exportingPdf,
    required this.onPreview,
    required this.onExportPdf,
  });

  final List<CardPrintTemplate> items;
  final bool previewing;
  final bool exportingPdf;
  final ValueChanged<CardPrintTemplate> onPreview;
  final ValueChanged<CardPrintTemplate> onExportPdf;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.print_outlined,
          title: 'لا توجد قوالب طباعة بعد',
          subtitle: 'احفظ أول قالب لاستخدامه لاحقًا في الطباعة.',
        ),
      );
    }
    return AppCard(
      title: 'القوالب المحفوظة',
      icon: Icons.print_outlined,
      child: Column(
        children: [
          for (final item in items) ...[
            _TemplateTile(
              item: item,
              previewing: previewing,
              exportingPdf: exportingPdf,
              onPreview: () => onPreview(item),
              onExportPdf: () => onExportPdf(item),
            ),
            if (item != items.last) const Divider(height: AppTokens.s24),
          ],
        ],
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.item,
    required this.previewing,
    required this.exportingPdf,
    required this.onPreview,
    required this.onExportPdf,
  });

  final CardPrintTemplate item;
  final bool previewing;
  final bool exportingPdf;
  final VoidCallback onPreview;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                color: AppTokens.sidebarBg,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            StatusPill(
              text: item.orientation == 'landscape' ? 'أفقي' : 'عمودي',
              tone: PillTone.cyan,
            ),
            StatusPill(
              text: item.showQr ? 'QR ظاهر' : 'بدون QR',
              tone: item.showQr ? PillTone.green : PillTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            _Metric(label: 'لكل صفحة', value: '${item.cardsPerPage}'),
            _Metric(label: 'الصف', value: '${item.cardsPerRow}'),
            _Metric(label: 'العمود', value: '${item.cardsPerColumn}'),
            _Metric(label: 'الخط', value: '${item.fontSize}'),
          ],
        ),
        const SizedBox(height: AppTokens.s8),
        Text(
          'اسم الدخول (${item.usernameX}, ${item.usernameY}) • كلمة المرور (${item.passwordX}, ${item.passwordY}) • QR (${item.qrX}, ${item.qrY})',
          style: const TextStyle(color: AppTokens.textMuted),
        ),
        const SizedBox(height: AppTokens.s12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            children: [
              OutlinedButton.icon(
                onPressed: previewing ? null : onPreview,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('معاينة بصرية'),
              ),
              ElevatedButton.icon(
                onPressed: exportingPdf ? null : onExportPdf,
                icon: exportingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(exportingPdf ? 'جاري التصدير...' : 'PDF'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});
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
                      colors: [Colors.white, Color(0xFFEFF8FF)],
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
              _Metric(label: 'renderer', value: preview.renderer),
              _Metric(label: 'cards/page', value: '${preview.cardsPerPage}'),
              _Metric(
                label: 'export',
                value: preview.exportGenerated ? 'generated' : 'PDF available',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'العينة: $username. PDF متاح لنموذج القالب من زر التصدير.',
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: AppTokens.s8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.bg,
        borderRadius: BorderRadius.circular(AppTokens.r10),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTokens.textMuted, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTokens.sidebarBg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

int _toInt(String text, int fallback) => int.tryParse(text.trim()) ?? fallback;

double _toDouble(String text, [double fallback = 0]) =>
    double.tryParse(text.trim()) ?? fallback;

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
