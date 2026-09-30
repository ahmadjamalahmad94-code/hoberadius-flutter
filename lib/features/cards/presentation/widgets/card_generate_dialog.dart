import 'package:hoberadius_app/core/format/arabic_plural.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/visible_error_message.dart';
import '../../../../core/format/bidi.dart';
import '../../../../core/theme/tokens.dart';
import '../../data/cards_repository.dart';

/// What the generate dialog ended with.
class GenerateDialogOutcome {
  const GenerateDialogOutcome.success(GenerateResult this.result)
      : error = null;
  const GenerateDialogOutcome.failed(Object this.error) : result = null;
  final GenerateResult? result;

  /// The last error when the operator closed the dialog after a failure
  /// (the form maps it to the field it concerns).
  final Object? error;
}

/// Where the success buttons go (the form passes the router actions).
class GenerateDialogRoutes {
  const GenerateDialogRoutes({
    required this.print,
    required this.detail,
    required this.batches,
  });
  final void Function(int batchId) print;
  final void Function(int batchId) detail;
  final VoidCallback batches;
}

/// «توليد»: a modal progress dialog (the form behind stays frozen) that
/// becomes the success card (print / open the batch / back to batches) or
/// the error with «إعادة المحاولة». [run] is the SAME request each time
/// (same body + Idempotency-Key), so a retry never makes a second batch.
class CardGenerateDialog extends StatefulWidget {
  const CardGenerateDialog({
    super.key,
    required this.count,
    required this.run,
    required this.routes,
  });

  final int count;
  final Future<GenerateResult> Function() run;
  final GenerateDialogRoutes routes;

  @override
  State<CardGenerateDialog> createState() => _CardGenerateDialogState();
}

class _CardGenerateDialogState extends State<CardGenerateDialog> {
  bool _running = true;
  GenerateResult? _result;
  Object? _error;
  int _seconds = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _running = true;
      _error = null;
      _seconds = 0;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    try {
      final r = await widget.run();
      if (!mounted) return;
      setState(() => _result = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      _ticker?.cancel();
      if (mounted) setState(() => _running = false);
    }
  }

  void _close() {
    final r = _result;
    Navigator.of(context).pop(
      r != null
          ? GenerateDialogOutcome.success(r)
          : GenerateDialogOutcome.failed(_error ?? 'x'),
    );
  }

  void _go(void Function() nav) {
    final r = _result!;
    Navigator.of(context).pop(GenerateDialogOutcome.success(r));
    nav();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = _result;
    final Widget body;
    if (_running) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppTokens.s16),
          Text(
            'جاري توليد ${arCount(widget.count, arCard, showOne: true)}…',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            'مضى $_seconds ث — لا تغلق التطبيق.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTokens.textMuted),
          ),
          const SizedBox(height: AppTokens.s12),
          const LinearProgressIndicator(minHeight: 6),
        ],
      );
    } else if (r != null) {
      final id = r.batch.id ?? 0;
      final made = r.cards.isNotEmpty
          ? r.cards.length
          : (r.batch.generated > 0 ? r.batch.generated : widget.count);
      final name = r.batch.packageName.trim();
      final code = r.batch.batchCode.trim();
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(Icons.check_circle, color: AppTokens.green, size: 56),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            'تم توليد ${arCount(made, arCard, showOne: true)}',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (name.isNotEmpty || code.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              [
                if (name.isNotEmpty) autoIsolate(name),
                if (code.isNotEmpty) ltrIsolate(code),
              ].join(' · '),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
          ],
          const SizedBox(height: AppTokens.s20),
          FilledButton.icon(
            onPressed: id > 0 ? () => _go(() => widget.routes.print(id)) : null,
            icon: const Icon(Icons.print_outlined),
            label: const Text('طباعة / تصدير'),
          ),
          const SizedBox(height: AppTokens.s8),
          OutlinedButton.icon(
            onPressed:
                id > 0 ? () => _go(() => widget.routes.detail(id)) : null,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('عرض الحزمة'),
          ),
          const SizedBox(height: AppTokens.s8),
          TextButton(
            onPressed: () => _go(widget.routes.batches),
            child: const Text('رجوع للحزم'),
          ),
        ],
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(Icons.error_outline, color: AppTokens.red, size: 52),
          ),
          const SizedBox(height: AppTokens.s12),
          Text(
            'تعذّر توليد الكروت',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTokens.s8),
          Text(
            visibleErrorMessage(_error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTokens.redInk),
          ),
          const SizedBox(height: AppTokens.s20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _close,
                  child: const Text('إغلاق'),
                ),
              ),
              const SizedBox(width: AppTokens.s8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Back after the result: close like «إغلاق» (the form stays filled).
        if (!didPop && !_running) _close();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(child: body),
        ),
      ),
    );
  }
}
