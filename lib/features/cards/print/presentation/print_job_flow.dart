import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hoberadius_app/core/router/pop_on_route_change.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_saver/file_saver.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/tokens.dart';
import '../application/quick_print_controller.dart';
import '../data/quick_print_repository.dart';

/// «طباعة»: like the web «تحميل PDF» — save the design, start an export job
/// for the whole batch, follow its REAL progress, then open the finished PDF
/// (system print dialog / share / save).
Future<void> runPrintFlow(
  BuildContext context,
  WidgetRef ref,
  int batchId,
) async {
  final provider = quickPrintControllerProvider(batchId);
  final ctl = ref.read(provider.notifier);
  final repo = ref.read(quickPrintRepositoryProvider);
  final navigator = Navigator.of(context, rootNavigator: true);

  final templateId = await saveDesignOrAsk(context, ctl);
  if (templateId == null) return;
  final st = ref.read(provider);
  final settings = st.sheet.toSettings();
  final overrides = ctl.exportOverrides;
  if (!context.mounted) return;

  final result = await showDialog<_PrintResult>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => _PrintJobDialog(
      start: () => repo.startExport(
        templateId: templateId,
        batchId: batchId,
        printSettings: settings,
        overrides: overrides,
      ),
      poll: repo.job,
      download: repo.download,
      cancel: repo.cancelJob,
    ),
  );
  if (result == null) return;
  await navigator.push(
    MaterialPageRoute<void>(
      // Closes itself when the browser «back» changes the route underneath.
      builder: (_) => PopOnRouteChange(
        child: PrintPdfScreen(
          bytes: result.bytes,
          fileName: result.fileName.isEmpty
              ? 'cards-batch-$batchId.pdf'
              : result.fileName,
          title: 'كروت ${st.batchCode}',
        ),
      ),
    ),
  );
}

/// Saves the design; a name another template already has opens
/// [TemplateNameClashDialog] (replace that template, or save under another
/// name) instead of a dead-end error. Null: cancelled or failed (the error is
/// shown in a snack bar).
Future<int?> saveDesignOrAsk(
  BuildContext context,
  QuickPrintController ctl,
) async {
  final messenger = ScaffoldMessenger.of(context);
  String? name;
  int? target;
  for (var round = 0; round < 5; round++) {
    try {
      return await ctl.save(name: name, targetTemplateId: target);
    } on TemplateNameTaken catch (e) {
      if (!context.mounted) return null;
      final choice = await showDialog<TemplateNameChoice>(
        context: context,
        useRootNavigator: true,
        builder: (_) => TemplateNameClashDialog(clash: e),
      );
      if (choice == null) return null;
      name = choice.name;
      target = choice.overwriteId;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(visibleErrorMessage(e))));
      return null;
    }
  }
  return null;
}

/// The operator's answer to a template-name clash.
class TemplateNameChoice {
  const TemplateNameChoice.rename(this.name) : overwriteId = null;
  const TemplateNameChoice.overwrite(this.name, int id) : overwriteId = id;
  final String name;

  /// Save INTO this existing template (replace it).
  final int? overwriteId;
}

/// «يوجد قالب بهذا الاسم»: replace the existing template (when it is known)
/// or pick another name (a free one is suggested).
class TemplateNameClashDialog extends StatefulWidget {
  const TemplateNameClashDialog({super.key, required this.clash});
  final TemplateNameTaken clash;

  @override
  State<TemplateNameClashDialog> createState() =>
      _TemplateNameClashDialogState();
}

class _TemplateNameClashDialogState extends State<TemplateNameClashDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.clash.suggestion);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _rename() {
    final v = _name.text.trim();
    if (v.isEmpty) {
      setState(() => _error = 'اسم القالب مطلوب');
      return;
    }
    if (v.toLowerCase() == widget.clash.name.trim().toLowerCase()) {
      setState(() => _error = 'هذا الاسم مستخدم — اختر اسمًا آخر.');
      return;
    }
    Navigator.of(context).pop(TemplateNameChoice.rename(v));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.clash;
    return AlertDialog(
      title: const Text('يوجد قالب بهذا الاسم'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c.existingId > 0
                  ? 'القالب «${c.name}» موجود. استبدله بهذا التصميم، '
                      'أو احفظ باسم آخر.'
                  : 'القالب «${c.name}» موجود. احفظ باسم آخر.',
            ),
            const SizedBox(height: AppTokens.s12),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: 'اسم جديد للقالب',
                counterText: '',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _rename(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        if (c.existingId > 0)
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(TemplateNameChoice.overwrite(c.name, c.existingId)),
            child: const Text('استبدال الموجود'),
          ),
        FilledButton(
          onPressed: _rename,
          child: const Text('حفظ باسم جديد'),
        ),
      ],
    );
  }
}

class _PrintResult {
  const _PrintResult(this.bytes, this.fileName);
  final Uint8List bytes;
  final String fileName;
}

class _PrintJobDialog extends StatefulWidget {
  const _PrintJobDialog({
    required this.start,
    required this.poll,
    required this.download,
    this.cancel,
  });
  final Future<PrintExportJob> Function() start;
  final Future<PrintExportJob> Function(int id) poll;
  final Future<Uint8List> Function(int id) download;

  /// «إلغاء» while the job is queued/running (a stuck export used to leave
  /// no way out: the dialog cannot be dismissed).
  final Future<void> Function(int id)? cancel;

  @override
  State<_PrintJobDialog> createState() => _PrintJobDialogState();
}

class _PrintJobDialogState extends State<_PrintJobDialog> {
  PrintExportJob? _job;
  String _error = '';
  bool _downloading = false;
  Timer? _timer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _error = '';
      _job = null;
      _downloading = false;
    });
    try {
      final job = await widget.start();
      if (_closed) return;
      setState(() => _job = job);
      _schedule(job.id);
    } catch (e) {
      if (!_closed) setState(() => _error = visibleErrorWithRetryHint(e));
    }
  }

  Future<void> _cancelJob() async {
    final id = _job?.id;
    _closed = true;
    _timer?.cancel();
    if (id != null && widget.cancel != null) await widget.cancel!(id);
    if (mounted) Navigator.of(context).pop();
  }

  void _schedule(int id) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), () => _tick(id));
  }

  Future<void> _tick(int id) async {
    try {
      final job = await widget.poll(id);
      if (_closed) return;
      setState(() => _job = job);
      if (job.failed) {
        setState(
          () =>
              _error = job.message.isEmpty ? 'تعذّر إنشاء الملف.' : job.message,
        );
        return;
      }
      if (!job.done) {
        _schedule(id);
        return;
      }
      setState(() => _downloading = true);
      final bytes = await widget.download(id);
      if (_closed || !mounted) return;
      Navigator.of(context).pop(_PrintResult(bytes, job.fileName));
    } catch (_) {
      if (!_closed) {
        // A transient network error: keep following the job.
        _timer = Timer(const Duration(seconds: 2), () => _tick(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final job = _job;
    final progress = _downloading ? 1.0 : (job?.progress ?? 2) / 100;
    final failed = _error.isNotEmpty;
    final label = failed
        ? _error
        : _downloading
            ? 'تنزيل الملف…'
            : (job?.stageLabel.isNotEmpty ?? false)
                ? job!.stageLabel
                : 'تجهيز ملف الطباعة…';
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (failed ? AppTokens.red : AppTokens.brand)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    failed ? Icons.error_outline : Icons.print_outlined,
                    color: failed ? AppTokens.red : AppTokens.brand,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              Text(
                failed
                    ? 'تعذّر إنشاء ملف الطباعة'
                    : 'جاري تجهيز الكروت للطباعة',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: AppTokens.textMuted),
              ),
              if (!failed) ...[
                const SizedBox(height: AppTokens.s16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress.clamp(0.02, 1.0)),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: AppTokens.brand.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Row(
                  children: [
                    Text(
                      '${(progress * 100).round()}٪',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if ((job?.total ?? 0) > 0)
                      Text(
                        '${job!.rendered} / ${job.total} كرت',
                        style: const TextStyle(color: AppTokens.textMuted),
                      ),
                  ],
                ),
                if (widget.cancel != null && !_downloading) ...[
                  const SizedBox(height: AppTokens.s12),
                  OutlinedButton.icon(
                    onPressed: _cancelJob,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('إلغاء الطباعة'),
                  ),
                ],
              ],
              if (failed) ...[
                const SizedBox(height: AppTokens.s20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('إغلاق'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _run,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The finished PDF: pages rasterized by the platform's PDF engine (exactly
/// what prints), pinch-zoom / pan, and three actions — save to the device,
/// share (WhatsApp to the print shop…), and the system print dialog.
class PrintPdfScreen extends StatefulWidget {
  const PrintPdfScreen({
    super.key,
    required this.bytes,
    required this.fileName,
    required this.title,
  });
  final Uint8List bytes;
  final String fileName;
  final String title;

  @override
  State<PrintPdfScreen> createState() => _PrintPdfScreenState();
}

class _PrintPdfScreenState extends State<PrintPdfScreen> {
  final List<Uint8List> _pages = [];
  final _zoom = TransformationController();
  bool _rendering = true;
  String _error = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _render() async {
    try {
      // 170 dpi: sharp enough to read the smallest card text when zoomed.
      await for (final page in Printing.raster(widget.bytes, dpi: 170)) {
        final png = await page.toPng();
        if (!mounted) return;
        setState(() => _pages.add(png));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'تعذّر عرض الملف: ${visibleErrorMessage(e)}');
      }
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  String get _baseName => widget.fileName.toLowerCase().endsWith('.pdf')
      ? widget.fileName.substring(0, widget.fileName.length - 4)
      : widget.fileName;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (kIsWeb) {
        // The web build has no «save as» picker (UnimplementedError): a
        // plain browser download instead.
        await FileSaver.instance.saveFile(
          name: _baseName,
          bytes: widget.bytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('تم تنزيل الملف')),
        );
      } else {
        // The system «save as» picker: the operator chooses the folder.
        final path = await FileSaver.instance.saveAs(
          name: _baseName,
          bytes: widget.bytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        if (path != null && path.isNotEmpty) {
          messenger.showSnackBar(
            const SnackBar(content: Text('تم حفظ الملف')),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر الحفظ: ${visibleErrorMessage(e, fallback: 'جرّب «مشاركة» لحفظ الملف.')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() =>
      Printing.sharePdf(bytes: widget.bytes, filename: widget.fileName);

  Future<void> _print() => Printing.layoutPdf(
        name: _baseName,
        onLayout: (_) async => widget.bytes,
      );

  void _resetZoom() => _zoom.value = Matrix4.identity();

  Offset _tapAt = Offset.zero;

  void _toggleZoom() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) {
      _resetZoom();
      return;
    }
    const k = 2.5;
    final p = _tapAt;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-p.dx * (k - 1), -p.dy * (k - 1), 0, 1)
      ..scaleByDouble(k, k, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: const Color(0xFFE9E7F2),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_pages.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_pages.length} صفحة',
                  style: text.labelLarge?.copyWith(color: AppTokens.textMuted),
                ),
              ),
            ),
          IconButton(
            tooltip: 'الحجم الطبيعي',
            onPressed: _resetZoom,
            icon: const Icon(Icons.zoom_out_map),
          ),
        ],
      ),
      body: _error.isNotEmpty
          ? Center(child: Text(_error, textAlign: TextAlign.center))
          : _pages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, c) => GestureDetector(
                    // Double tap: zoom ×2.5 on that spot, again to reset.
                    onDoubleTapDown: (d) => _tapAt = d.localPosition,
                    onDoubleTap: _toggleZoom,
                    child: InteractiveViewer(
                      transformationController: _zoom,
                      constrained: false,
                      minScale: 1,
                      maxScale: 6,
                      boundaryMargin: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: c.maxWidth,
                        child: Column(
                          children: [
                            for (final png in _pages)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Image.memory(
                                    png,
                                    width: c.maxWidth - 24,
                                    fit: BoxFit.fitWidth,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                              ),
                            if (_rendering)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTokens.borderStrong)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PdfAction(
                  icon: Icons.download_outlined,
                  label: 'تحميل',
                  busy: _saving,
                  onTap: _save,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PdfAction(
                  icon: Icons.share_outlined,
                  label: 'مشاركة',
                  onTap: _share,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PdfAction(
                  icon: Icons.print_outlined,
                  label: 'طباعة',
                  primary: true,
                  onTap: _print,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfAction extends StatelessWidget {
  const _PdfAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.busy = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      // The default icon-button padding (16 + 24) left «مشاركة» ~38 px at
      // 360 px wide and it was clipped to «شاركة» (R06 N8.1).
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
    final iconW = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 20);
    // Never clipped: a narrow button shrinks the label instead.
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    );
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: primary
          ? FilledButton.icon(
              onPressed: busy ? null : onTap,
              style: style,
              icon: iconW,
              label: text,
            )
          : OutlinedButton.icon(
              onPressed: busy ? null : onTap,
              style: style,
              icon: iconW,
              label: text,
            ),
    );
  }
}
