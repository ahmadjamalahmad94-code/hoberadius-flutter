import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';

/// «طباعة الكروت» — the server does ALL rendering (the same engine that
/// prints from the web), the app never redraws a card itself:
///
/// * `preview.pdf` draws the unsaved design (web quick-form fields) with the
///   export's own drawing code → shown by the phone's native PDF renderer.
/// * `quick-save` normalizes the fields with the web designer's own builder,
///   so a template saved here is identical to one saved from the web.
/// * export jobs produce the final PDF, with real progress.
class QuickPrintRepository {
  QuickPrintRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> templates() async {
    final res =
        await _api.get('/api/v1/print-templates', query: {'limit': 200});
    final items = _data(res)['items'];
    return items is List
        ? items.whereType<Map>().map(_stringKeys).toList()
        : const [];
  }

  Future<Map<String, String>> lastSettings() async {
    final res = await _api.get('/api/v1/print-templates/last-settings');
    final s = _data(res)['settings'];
    return s is Map
        ? {for (final e in s.entries) '${e.key}': '${e.value ?? ''}'}
        : const {};
  }

  Future<Map<String, dynamic>> batch(int id) async {
    final res = await _api.get('/api/v1/cards/batches/$id');
    final d = _data(res);
    final b = d['batch'];
    return b is Map ? _stringKeys(b) : d;
  }

  /// Same Pillow optimizer as the web; returns the background_* fields.
  Future<Map<String, dynamic>> optimizeBackground(
    String dataUrl,
    String name,
  ) async {
    final res = await _api.post(
      '/api/v1/print-templates/background',
      body: {'data_url': dataUrl, 'name': name},
    );
    final bg = _data(res)['background'];
    return bg is Map ? _stringKeys(bg) : const {};
  }

  /// One-page PDF: `mode: card` (one card, card-sized page) or `page`.
  Future<Uint8List> preview({
    required Map<String, String> form,
    int? templateId,
    int? batchId,
    Map<String, String> printSettings = const {},
    String mode = 'card',
    CancelToken? cancel,
  }) async {
    final res = await _api.dio.post<List<int>>(
      '/api/v1/print-templates/preview.pdf',
      data: {
        if (templateId != null && templateId > 0) 'template_id': templateId,
        'form': form,
        if (batchId != null) 'batch_id': batchId,
        'print_settings': printSettings,
        'mode': mode,
      },
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancel,
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Future<Map<String, dynamic>> quickSave({
    required Map<String, String> form,
    int? templateId,
    Map<String, String> printSettings = const {},
  }) async {
    final res = await _api.post(
      '/api/v1/print-templates/quick-save',
      body: {
        if (templateId != null && templateId > 0) 'template_id': templateId,
        'form': form,
        'print_settings': printSettings,
      },
    );
    final t = _data(res)['template'];
    return t is Map ? _stringKeys(t) : const {};
  }

  Future<PrintExportJob> startExport({
    required int templateId,
    required int batchId,
    required Map<String, String> printSettings,
    Map<String, String> overrides = const {},
  }) async {
    final res = await _api.post(
      '/api/v1/print-templates/$templateId/export-jobs',
      body: {
        'batch_id': batchId,
        'print_settings': printSettings,
        'layout_overrides': overrides,
      },
    );
    return PrintExportJob.fromJson(_job(res));
  }

  Future<PrintExportJob> job(int id) async {
    final res = await _api.get('/api/v1/print-jobs/$id');
    return PrintExportJob.fromJson(_job(res));
  }

  Future<Uint8List> download(int jobId) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/print-jobs/$jobId/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  Map<String, dynamic> _job(Map<String, dynamic> res) {
    final j = _data(res)['job'];
    return j is Map ? _stringKeys(j) : const {};
  }

  static Map<String, dynamic> _data(Map<String, dynamic> res) {
    final d = res['data'];
    return d is Map ? _stringKeys(d) : res;
  }

  static Map<String, dynamic> _stringKeys(Map m) =>
      m.map((k, v) => MapEntry('$k', v));
}

class PrintExportJob {
  const PrintExportJob({
    required this.id,
    required this.status,
    required this.progress,
    required this.stageLabel,
    required this.rendered,
    required this.total,
    required this.downloadReady,
    required this.fileName,
    required this.message,
  });

  final int id;
  final String status;
  final int progress;
  final String stageLabel;
  final int rendered;
  final int total;
  final bool downloadReady;
  final String fileName;
  final String message;

  bool get failed => status == 'failed';

  /// The server flips `status` to success a moment before the file is
  /// written — only `download_ready` means the PDF can be fetched.
  bool get done => downloadReady;

  factory PrintExportJob.fromJson(Map<String, dynamic> j) {
    int toInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return PrintExportJob(
      id: toInt(j['id']),
      status: '${j['status'] ?? ''}',
      progress: toInt(j['progress']).clamp(0, 100),
      stageLabel: '${j['stage_label'] ?? ''}',
      rendered: toInt(j['rendered_cards']),
      total: toInt(j['total_cards']),
      downloadReady: j['download_ready'] == true,
      fileName: '${j['file_name'] ?? ''}',
      message: '${j['message'] ?? ''}',
    );
  }
}

final quickPrintRepositoryProvider = Provider<QuickPrintRepository>(
  (ref) => QuickPrintRepository(ref.watch(apiClientProvider)),
);
