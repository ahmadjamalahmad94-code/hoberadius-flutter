import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../data/print_templates_repository.dart';
import '../domain/print_template_model.dart';

/// Loads the saved templates list. Kept as a sibling of the action
/// controller so all print-templates state lives in one file.
final printTemplatesProvider =
    FutureProvider.autoDispose<List<CardPrintTemplate>>((ref) {
  return ref.watch(printTemplatesRepositoryProvider).list();
});

/// State for the imperative actions on the print-templates screen
/// (save / preview / export). The list itself is owned by
/// [printTemplatesProvider]; this state only tracks in-flight flags
/// and the most-recent preview payload so the preview card can render.
class PrintTemplatesActionState {
  const PrintTemplatesActionState({
    this.saving = false,
    this.previewing = false,
    this.exportingPdf = false,
    this.preview,
  });

  final bool saving;
  final bool previewing;
  final bool exportingPdf;
  final PrintTemplatePreview? preview;

  PrintTemplatesActionState withFlags({
    bool? saving,
    bool? previewing,
    bool? exportingPdf,
  }) =>
      PrintTemplatesActionState(
        saving: saving ?? this.saving,
        previewing: previewing ?? this.previewing,
        exportingPdf: exportingPdf ?? this.exportingPdf,
        preview: preview,
      );

  PrintTemplatesActionState withPreview(PrintTemplatePreview? next) =>
      PrintTemplatesActionState(
        saving: saving,
        previewing: previewing,
        exportingPdf: exportingPdf,
        preview: next,
      );
}

/// Result returned by [PrintTemplatesActionController.exportPdf] —
/// `bytes` is non-null on success, `error` on failure.
class ExportPdfResult {
  const ExportPdfResult({this.bytes, this.error});
  final Uint8List? bytes;
  final String? error;
}

class PrintTemplatesActionController
    extends Notifier<PrintTemplatesActionState> {
  @override
  PrintTemplatesActionState build() => const PrintTemplatesActionState();

  Future<String?> save({
    required String name,
    required String orientation,
    required int cardsPerRow,
    required int cardsPerColumn,
    required String pageSize,
    required bool showQr,
    required double usernameX,
    required double usernameY,
    required double passwordX,
    required double passwordY,
    required double qrX,
    required double qrY,
    required int fontSize,
    required String color,
    required double cardWidthMm,
    required double cardHeightMm,
  }) async {
    state = state.withFlags(saving: true);
    try {
      await ref.read(printTemplatesRepositoryProvider).create(
            name: name,
            orientation: orientation,
            cardsPerRow: cardsPerRow,
            cardsPerColumn: cardsPerColumn,
            pageSize: pageSize,
            showQr: showQr,
            usernameX: usernameX,
            usernameY: usernameY,
            passwordX: passwordX,
            passwordY: passwordY,
            qrX: qrX,
            qrY: qrY,
            fontSize: fontSize,
            color: color,
            cardWidthMm: cardWidthMm,
            cardHeightMm: cardHeightMm,
          );
      ref.invalidate(printTemplatesProvider);
      return null;
    } catch (e) {
      return visibleErrorMessage(e);
    } finally {
      state = state.withFlags(saving: false);
    }
  }

  Future<String?> previewTemplate(
    int id, {
    String sampleUsername = 'CARD1234',
  }) async {
    state = state.withFlags(previewing: true);
    try {
      final result =
          await ref.read(printTemplatesRepositoryProvider).preview(
                id,
                sampleUsername: sampleUsername,
              );
      state = state.withPreview(result);
      return null;
    } catch (e) {
      return visibleErrorMessage(e);
    } finally {
      state = state.withFlags(previewing: false);
    }
  }

  Future<ExportPdfResult> exportPdf(
    int id, {
    String sampleUsername = 'CARD1234',
  }) async {
    state = state.withFlags(exportingPdf: true);
    try {
      final bytes =
          await ref.read(printTemplatesRepositoryProvider).exportPdf(
                id,
                sampleUsername: sampleUsername,
              );
      return ExportPdfResult(bytes: bytes);
    } catch (e) {
      return ExportPdfResult(error: visibleErrorMessage(e));
    } finally {
      state = state.withFlags(exportingPdf: false);
    }
  }
}

final printTemplatesActionProvider = NotifierProvider<
    PrintTemplatesActionController, PrintTemplatesActionState>(
  PrintTemplatesActionController.new,
);
