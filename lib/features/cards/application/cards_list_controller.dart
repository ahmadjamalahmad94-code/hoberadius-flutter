import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../data/cards_repository.dart';
import 'cards_list_providers.dart';

/// Result for bulk-action requests on the batches table.
class BulkActionResult {
  const BulkActionResult({this.message, this.error});
  final String? message;
  final String? error;
}

/// Result for export operations — bytes saved on success, `error`
/// otherwise.
class ExportResult {
  const ExportResult({this.savedAs, this.error});
  final String? savedAs;
  final String? error;
}

class CardsListController {
  CardsListController(this._ref);
  final Ref _ref;

  Future<ExportResult> exportCsv() async {
    final filters = _ref.read(batchOpsFiltersProvider);
    try {
      final bytes = await _ref
          .read(cardsRepositoryProvider)
          .exportBatchesCsv(query: filters.query, status: filters.status);
      await _save(bytes, 'card-batches', 'csv', MimeType.csv);
      return const ExportResult(savedAs: 'تم تنزيل ملف الحزم المعروضة');
    } catch (e) {
      return ExportResult(error: visibleErrorMessage(e));
    }
  }

  Future<ExportResult> exportXlsx() async {
    final filters = _ref.read(batchOpsFiltersProvider);
    try {
      final bytes = await _ref
          .read(cardsRepositoryProvider)
          .exportBatchesXlsx(query: filters.query, status: filters.status);
      await _save(
        bytes,
        'card-batches',
        'xlsx',
        MimeType.microsoftExcel,
      );
      return const ExportResult(
        savedAs: 'تم تنزيل ملف Excel للحزم المعروضة',
      );
    } catch (e) {
      return ExportResult(error: visibleErrorMessage(e));
    }
  }

  Future<ExportResult> exportPdf() async {
    final filters = _ref.read(batchOpsFiltersProvider);
    try {
      final bytes = await _ref
          .read(cardsRepositoryProvider)
          .exportBatchesPdf(query: filters.query, status: filters.status);
      await _save(bytes, 'card-batches', 'pdf', MimeType.pdf);
      return const ExportResult(
        savedAs: 'تم تنزيل ملف PDF للحزم المعروضة',
      );
    } catch (e) {
      return ExportResult(error: visibleErrorMessage(e));
    }
  }

  Future<BulkActionResult> runBulk(String action) async {
    final ids = _ref.read(selectedBatchIdsProvider).toList()..sort();
    if (ids.isEmpty) return const BulkActionResult();
    final label = switch (action) {
      'archive' => 'أرشفة',
      'restore' => 'استعادة',
      _ => 'تحديث',
    };
    try {
      final result = await _ref.read(cardsRepositoryProvider).bulkBatches(
            action: action,
            batchIds: ids,
            reason: action == 'archive' ? 'أرشفة من تطبيق الإدارة' : '',
          );
      _ref.read(selectedBatchIdsProvider.notifier).state = <int>{};
      _ref.invalidate(batchesOperationsProvider);
      _ref.invalidate(batchesListProvider);
      final message = action == 'refresh'
          ? 'تم تحديث العرض'
          : 'تم تنفيذ $label على ${result.changed} من ${result.requested} حزمة';
      return BulkActionResult(message: message);
    } catch (e) {
      return BulkActionResult(error: visibleErrorMessage(e));
    }
  }

  Future<void> _save(
    Uint8List bytes,
    String name,
    String ext,
    MimeType mime,
  ) async {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: ext,
      mimeType: mime,
    );
  }
}

final cardsListControllerProvider = Provider.autoDispose<CardsListController>(
  CardsListController.new,
);
