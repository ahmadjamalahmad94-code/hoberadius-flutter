import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/print_templates_controller.dart';
import '../domain/print_template_model.dart';
import 'desktop/export_room.dart';
import 'widgets/template_form.dart';
import 'widgets/template_list.dart';
import 'widgets/template_preview_card.dart';

/// Screen entry for the print-templates feature. Owns the form
/// [TextEditingController]s and the three radio-ish dropdown selections
/// (orientation / page size / show QR). Action state (saving, preview,
/// export) lives in [printTemplatesActionProvider]; the list lives in
/// [printTemplatesProvider]. Sub-widgets are pure presentation.
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
  // mm position defaults are 0 so the renderer falls back to
  // `_DEFAULT_POSITIONS` in card_render_model.dart (web parity:
  // commit P2 on the web side flipped these from 10/15/… to 0).
  // The drag handles in the designer canvas write non-zero values
  // here when the user customises positions; the renderer then
  // honours the custom coords end-to-end.
  final _ux = TextEditingController(text: '0');
  final _uy = TextEditingController(text: '0');
  final _px = TextEditingController(text: '0');
  final _py = TextEditingController(text: '0');
  final _qx = TextEditingController(text: '0');
  final _qy = TextEditingController(text: '0');
  final _font = TextEditingController(text: '12');
  final _color = TextEditingController(text: '#1f2937');
  String _orientation = 'portrait';
  String _pageSize = 'A4';
  bool _showQr = true;

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
    final action = ref.watch(printTemplatesActionProvider);
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
                  'القوالب محفوظة وقابلة لإعادة الاستخدام، والمعاينة بصرية للمواضع والألوان، ويمكن تنزيل ملف PDF للمعاينة.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        if (action.preview != null) ...[
          const SizedBox(height: AppTokens.s12),
          TemplatePreviewCard(preview: action.preview!),
        ],
        // ── Windows desktop: 3-column export room mirroring the web's
        //    #export section. Mobile + narrow web keep the existing
        //    single-column layout below — mobile-safety contract
        //    preserved (see docs/MOBILE_BASELINE.md).
        //
        //    Gating rule
        //    ───────────
        //    On Windows (or any other true-desktop OS) we always
        //    render the export room — the user explicitly chose a
        //    desktop build, so even narrow windows should get the
        //    new UI. The breakpoint check only applies to web
        //    builds, where a single Flutter bundle can serve a
        //    600 px phone browser. The earlier "constraint width
        //    ≥ bpDesktop" threshold was a bug: after the shell's
        //    260 px sidebar + 32 px padding, a 1280 px window's
        //    content area was only ~988 px so the room never
        //    rendered. Now we gate on `bpTablet` (960) for web AND
        //    bypass the check entirely on isDesktop.
        if (PlatformCapabilities.supportsDesktopLayout) ...[
          const SizedBox(height: AppTokens.s12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (!PlatformCapabilities.isDesktop &&
                  constraints.maxWidth < AppTokens.bpTablet) {
                return const SizedBox.shrink();
              }
              return const ExportRoom();
            },
          ),
        ],
        const SizedBox(height: AppTokens.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final form = TemplateForm(
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
              saving: action.saving,
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
                subtitle: visibleErrorMessage(e),
              ),
              data: (items) => TemplateList(
                items: items,
                previewing: action.previewing,
                exportingPdf: action.exportingPdf,
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
    final error =
        await ref.read(printTemplatesActionProvider.notifier).save(
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
    if (!mounted) return;
    if (error == null) {
      _name.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ قالب الطباعة')),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _previewTemplate(CardPrintTemplate item) async {
    final error = await ref
        .read(printTemplatesActionProvider.notifier)
        .previewTemplate(item.id);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _exportPdf(CardPrintTemplate item) async {
    final result = await ref
        .read(printTemplatesActionProvider.notifier)
        .exportPdf(item.id);
    if (result.bytes != null) {
      await FileSaver.instance.saveFile(
        name: 'print-template-${item.id}',
        bytes: result.bytes!,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تنزيل ملف PDF للمعاينة')),
      );
    } else if (result.error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تصدير PDF: ${result.error}')),
      );
    }
  }
}

int _toInt(String text, int fallback) => int.tryParse(text.trim()) ?? fallback;

double _toDouble(String text, [double fallback = 0]) =>
    double.tryParse(text.trim()) ?? fallback;
