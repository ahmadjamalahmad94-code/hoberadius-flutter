import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../../../core/platform/platform_capabilities.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../provider_grants/application/provider_grants_provider.dart';
import '../../provider_grants/presentation/limit_usage_banner.dart';
import '../application/print_templates_controller.dart';
import '../domain/print_template_model.dart';
import 'desktop/export_room.dart';
import 'widgets/template_designer_section.dart';
import 'widgets/template_form.dart';
import 'widgets/template_list.dart';
import 'widgets/template_live_preview.dart';
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
  // — designer styling —
  final _gradStart = TextEditingController(text: '#0f172a');
  final _gradEnd = TextEditingController(text: '#22a7bd');
  final _accent = TextEditingController(text: '#f59e0b');
  final _textColor = TextEditingController(text: '#ffffff');
  final _surface = TextEditingController(text: '#e8f7fb');
  final _qrColor = TextEditingController(text: '#0f172a');
  final _qrSizePct = TextEditingController(text: '');
  final _patternColor = TextEditingController(text: '#ffffff');
  final _patternOpacity = TextEditingController(text: '');
  String _pattern = 'signal';
  String _renderEngine = 'ar_horizontal';
  String _bgImageDataUrl = '';
  String _orientation = 'portrait';
  String _pageSize = 'A4';
  bool _showQr = true;
  // Page split: 0 = «تصميم» (design + live preview), 1 = «طباعة» (pick a
  // saved template → preview / export PDF). Mirrors the web's design/print
  // separation so the operator isn't shown export controls while drafting.
  int _section = 0;

  /// Live-preview listenable: every designer text field. Dropdown/picker
  /// changes already trigger setState (parent rebuild), so the preview
  /// refreshes on those too.
  late final Listenable _designerListenable = Listenable.merge([
    _name,
    _width,
    _height,
    _gradStart,
    _gradEnd,
    _accent,
    _textColor,
    _surface,
    _qrColor,
    _qrSizePct,
    _patternColor,
    _patternOpacity,
  ]);

  /// Builds the in-flight template map (same shape the renderer/export use)
  /// from the current designer state, so the live preview matches the saved
  /// output exactly.
  Map<String, dynamic> _currentTemplate() {
    final brand = _name.text.trim();
    return {
      'username_x': _toDouble(_ux.text),
      'username_y': _toDouble(_uy.text),
      'password_x': _toDouble(_px.text),
      'password_y': _toDouble(_py.text),
      'qr_x': _toDouble(_qx.text),
      'qr_y': _toDouble(_qy.text),
      'layout_json': {
        'card_width_mm': _toDouble(_width.text, 85),
        'card_height_mm': _toDouble(_height.text, 54),
        'brand_name': brand.isEmpty ? 'HobeRadius' : brand,
        'card_title': 'بطاقة إنترنت',
        'show_qr': _showQr,
        ..._designerLayout(),
      },
    };
  }

  Map<String, dynamic> _designerLayout() {
    final qrPct = double.tryParse(_qrSizePct.text.trim());
    return {
      'render_engine': _renderEngine,
      'gradient_start': _gradStart.text.trim(),
      'gradient_end': _gradEnd.text.trim(),
      'pattern_style': _pattern,
      'pattern_color': _patternColor.text.trim().isEmpty
          ? '#ffffff'
          : _patternColor.text.trim(),
      if (_patternOpacity.text.trim().isNotEmpty)
        'pattern_opacity': double.tryParse(_patternOpacity.text.trim()) ?? '',
      'accent_color': _accent.text.trim(),
      'text_color': _textColor.text.trim(),
      'surface_color': _surface.text.trim(),
      'qr_color': _qrColor.text.trim(),
      if (qrPct != null && qrPct > 0) 'qr_size_pct': qrPct,
      if (_bgImageDataUrl.isNotEmpty)
        'background_image_data_url': _bgImageDataUrl,
    };
  }

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
      _gradStart,
      _gradEnd,
      _accent,
      _textColor,
      _surface,
      _qrColor,
      _qrSizePct,
      _patternColor,
      _patternOpacity,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(printTemplatesActionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'قوالب طباعة الكروت',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
        // ── Design / Print section split (web parity) ──────────────
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('تصميم'),
                icon: Icon(Icons.brush_outlined),
              ),
              ButtonSegment(
                value: 1,
                label: Text('طباعة'),
                icon: Icon(Icons.print_outlined),
              ),
            ],
            selected: {_section},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _section = s.first),
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        if (_section == 0) _buildDesignSection(action) else _buildPrintSection(action),
      ],
    );
  }

  /// «تصميم» — the editor (form + designer) beside a live SVG preview that
  /// updates as fields change (same renderer the export PDF uses).
  Widget _buildDesignSection(PrintTemplatesActionState action) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTokens.amber),
              SizedBox(width: AppTokens.s8),
              Expanded(
                child: Text(
                  'صمّم القالب من الحقول والألوان على اليمين، وتابع النتيجة في المعاينة الحية. بعد الحفظ انتقل إلى «طباعة» لاختيار حزمة وتصدير PDF.',
                  style: TextStyle(color: AppTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s12),
        const LimitUsageBanner(serviceKey: 'print_templates'),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final form = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TemplateForm(
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
                ),
                const SizedBox(height: AppTokens.s12),
                TemplateDesignerSection(
                  renderEngine: _renderEngine,
                  pattern: _pattern,
                  gradientStart: _gradStart,
                  gradientEnd: _gradEnd,
                  accent: _accent,
                  textColor: _textColor,
                  surface: _surface,
                  qrColor: _qrColor,
                  qrSizePct: _qrSizePct,
                  patternColor: _patternColor,
                  patternOpacity: _patternOpacity,
                  bgImageDataUrl: _bgImageDataUrl,
                  onRenderEngine: (v) => setState(() => _renderEngine = v),
                  onPattern: (v) => setState(() => _pattern = v),
                  onBgImage: (dataUrl) =>
                      setState(() => _bgImageDataUrl = dataUrl),
                  onBgClear: () => setState(() => _bgImageDataUrl = ''),
                ),
              ],
            );
            final preview = TemplateLivePreview(
              buildTemplate: _currentTemplate,
              listenable: _designerListenable,
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  preview,
                  const SizedBox(height: AppTokens.s12),
                  form,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: AppTokens.s12),
                SizedBox(width: 400, child: preview),
              ],
            );
          },
        ),
      ],
    );
  }

  /// «طباعة» — pick a saved template (and, on desktop, a package via the
  /// export room) then preview / export the PDF sheet.
  Widget _buildPrintSection(PrintTemplatesActionState action) {
    final templates = ref.watch(printTemplatesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (action.preview != null) ...[
          TemplatePreviewCard(preview: action.preview!),
          const SizedBox(height: AppTokens.s12),
        ],
        // ── Windows desktop: 3-column export room mirroring the web's
        //    #export section. Mobile + narrow web fall back to the saved
        //    template list below — mobile-safety contract preserved
        //    (see docs/MOBILE_BASELINE.md).
        if (PlatformCapabilities.supportsDesktopLayout)
          LayoutBuilder(
            builder: (context, constraints) {
              // The 3-column desktop export room needs real width. Gate on
              // available WIDTH regardless of platform so a narrow desktop
              // window falls back to the saved template list instead of
              // overflowing (owner rule #2: no breakage at any width).
              if (constraints.maxWidth < AppTokens.bpTablet) {
                return const SizedBox.shrink();
              }
              return const Padding(
                padding: EdgeInsets.only(bottom: AppTokens.s12),
                child: ExportRoom(),
              );
            },
          ),
        templates.when(
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
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Block-at-cap: provider may limit the number of active print templates.
    if (!grantsAllowCreate(ref, 'print_templates')) {
      final limit = ref.read(grantLimitProvider('print_templates'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            limit == null
                ? 'تم الوصول إلى الحدّ المسموح من المزوّد.'
                : providerLimitMessageAr(limit),
          ),
        ),
      );
      return;
    }
    final error = await ref.read(printTemplatesActionProvider.notifier).save(
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
          layout: _designerLayout(),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
