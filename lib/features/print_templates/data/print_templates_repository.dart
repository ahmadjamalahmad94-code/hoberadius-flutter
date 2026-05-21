import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/print_template_model.dart';

class PrintTemplatesRepository {
  PrintTemplatesRepository(this._api);

  final ApiClient _api;

  Future<List<CardPrintTemplate>> list() async {
    final res = await _api.get('/api/v1/print-templates');
    final data = res['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => CardPrintTemplate.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<List<PrintTemplatePreset>> presets() async {
    final res = await _api.get('/api/v1/print-templates/presets');
    final data = res['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => PrintTemplatePreset.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<List<PrintJob>> jobs({int limit = 50}) async {
    final res = await _api.get(
      '/api/v1/print-jobs',
      query: {'limit': limit},
    );
    final data = res['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) => PrintJob.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<CardPrintTemplate> create({
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
    double cardWidthMm = 85,
    double cardHeightMm = 54,
    Map<String, dynamic> layout = const {},
  }) async {
    final res = await _api.post(
      '/api/v1/print-templates',
      body: {
        'name': name,
        'orientation': orientation,
        'cards_per_row': cardsPerRow,
        'cards_per_column': cardsPerColumn,
        'page_size': pageSize,
        'show_qr': showQr,
        'username_x': usernameX,
        'username_y': usernameY,
        'password_x': passwordX,
        'password_y': passwordY,
        'qr_x': qrX,
        'qr_y': qrY,
        'font_size': fontSize,
        'color': color,
        'layout': {
          'preview_mode': 'json_layout_preview',
          'card_width_mm': cardWidthMm,
          'card_height_mm': cardHeightMm,
          ...layout,
        },
      },
    );
    final data = res['data'];
    final template = data is Map ? data['template'] : null;
    if (template is Map<String, dynamic>) {
      return CardPrintTemplate.fromJson(template);
    }
    if (template is Map) {
      return CardPrintTemplate.fromJson(
        template.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return const CardPrintTemplate(
      id: 0,
      name: '',
      orientation: 'portrait',
      cardsPerRow: 0,
      cardsPerColumn: 0,
      pageSize: 'A4',
      showQr: false,
      usernameX: 0,
      usernameY: 0,
      passwordX: 0,
      passwordY: 0,
      qrX: 0,
      qrY: 0,
      fontSize: 0,
      color: '#1f2937',
      layout: {},
      createdAt: null,
    );
  }

  Future<CardPrintTemplate> update({
    required int templateId,
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
    double cardWidthMm = 85,
    double cardHeightMm = 54,
    Map<String, dynamic> layout = const {},
  }) async {
    final res = await _api.patch(
      '/api/v1/print-templates/$templateId',
      body: {
        'name': name,
        'orientation': orientation,
        'cards_per_row': cardsPerRow,
        'cards_per_column': cardsPerColumn,
        'page_size': pageSize,
        'show_qr': showQr,
        'username_x': usernameX,
        'username_y': usernameY,
        'password_x': passwordX,
        'password_y': passwordY,
        'qr_x': qrX,
        'qr_y': qrY,
        'font_size': fontSize,
        'color': color,
        'layout': {
          'preview_mode': 'json_layout_preview',
          'card_width_mm': cardWidthMm,
          'card_height_mm': cardHeightMm,
          ...layout,
        },
      },
    );
    final data = res['data'];
    final template = data is Map ? data['template'] : null;
    if (template is Map<String, dynamic>) {
      return CardPrintTemplate.fromJson(template);
    }
    if (template is Map) {
      return CardPrintTemplate.fromJson(
        template.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    throw StateError('تعذر قراءة القالب من استجابة الخادم');
  }

  Future<PrintTemplatePreview> preview(
    int templateId, {
    String sampleUsername = 'CARD1234',
  }) async {
    final res = await _api.post(
      '/api/v1/print-templates/$templateId/render',
      body: {
        'sample': {
          'username': sampleUsername,
          'has_password': true,
          'qr_payload': sampleUsername,
        },
      },
    );
    final data = res['data'];
    return PrintTemplatePreview.fromJson(
      data is Map<String, dynamic>
          ? data
          : data is Map
              ? data.map((key, value) => MapEntry(key.toString(), value))
              : const {},
    );
  }

  Future<Uint8List> exportPdf(
    int templateId, {
    String sampleUsername = 'CARD1234',
    int? batchId,
    Map<String, String> overrides = const {},
  }) async {
    final res = await _api.dio.get<List<int>>(
      '/api/v1/print-templates/$templateId/export.pdf',
      queryParameters: {
        'sample_username': sampleUsername,
        if (batchId != null) 'batch_id': batchId,
        ...overrides,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  /// Mark a template as the tenant default (web `set_default` action).
  /// Returns the saved template row.
  Future<CardPrintTemplate?> setDefault(int templateId) async {
    final res = await _api.post(
      '/api/v1/print-templates/$templateId/set-default',
      body: const {},
    );
    final data = res['data'];
    final template = data is Map ? data['template'] : null;
    if (template is Map) {
      return CardPrintTemplate.fromJson(
        template.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  /// Soft-delete a single template (web `print_templates_delete`).
  Future<void> delete(int templateId) async {
    await _api.delete('/api/v1/print-templates/$templateId');
  }

  /// Bulk-delete every template whose name matches the auto-fixture
  /// regex (Print UI / ops_room_ / template_<hex>).
  ///
  /// Returns the number of rows that were purged.
  Future<int> cleanupFixtures() async {
    final res = await _api.post(
      '/api/v1/print-templates/cleanup-fixtures',
      body: const {},
    );
    final data = res['data'];
    final count = data is Map ? data['purged'] : null;
    if (count is num) return count.toInt();
    if (count is List) return count.length;
    return 0;
  }

  /// Fetch the SAME HTML preview fragment the web's export center
  /// renders. We only use this for parity tests / a fall-back path
  /// when the backend ships a renderer change ahead of the Flutter
  /// model — the Windows build's primary preview is the local SVG.
  Future<String> previewFragmentHtml(
    int templateId, {
    int? batchId,
    Map<String, String> overrides = const {},
  }) async {
    final res = await _api.dio.get<String>(
      '/admin/radius/print-templates/$templateId/preview-fragment',
      queryParameters: {
        if (batchId != null) 'batch_id': batchId,
        ...overrides,
      },
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }
}

final printTemplatePresetsProvider =
    FutureProvider.autoDispose<List<PrintTemplatePreset>>((ref) {
  return ref.watch(printTemplatesRepositoryProvider).presets();
});

final printJobsProvider = FutureProvider.autoDispose<List<PrintJob>>((ref) {
  return ref.watch(printTemplatesRepositoryProvider).jobs();
});

final printTemplatesRepositoryProvider =
    Provider<PrintTemplatesRepository>((ref) {
  return PrintTemplatesRepository(ref.watch(apiClientProvider));
});
