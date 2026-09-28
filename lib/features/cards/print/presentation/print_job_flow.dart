import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/tokens.dart';
import '../application/quick_print_controller.dart';
import '../data/quick_print_repository.dart';

/// «طباعة»: like the web «تحميل PDF» — save the design, start an export job
/// for the whole batch, follow its REAL progress, then open the finished PDF
/// (system print dialog / share / save).
Future<void> runPrintFlow(
    BuildContext context, WidgetRef ref, int batchId,) async {
  final provider = quickPrintControllerProvider(batchId);
  final ctl = ref.read(provider.notifier);
  final repo = ref.read(quickPrintRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  final int templateId;
  try {
    templateId = await ctl.save();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
    return;
  }
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
    ),
  );
  if (result == null) return;
  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => PrintPdfScreen(
        bytes: result.bytes,
        fileName: result.fileName.isEmpty
            ? 'cards-batch-$batchId.pdf'
            : result.fileName,
        title: 'كروت ${st.batchCode}',
      ),
    ),
  );
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
  });
  final Future<PrintExportJob> Function() start;
  final Future<PrintExportJob> Function(int id) poll;
  final Future<Uint8List> Function(int id) download;

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
      if (!_closed) setState(() => _error = '$e');
    }
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
        setState(() =>
            _error = job.message.isEmpty ? 'تعذّر إنشاء الملف.' : job.message,);
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

/// The finished PDF, shown by the platform's PDF renderer, with the system
/// print dialog and share/save.
class PrintPdfScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
