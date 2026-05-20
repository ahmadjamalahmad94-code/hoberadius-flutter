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
}

final printTemplatesRepositoryProvider =
    Provider<PrintTemplatesRepository>((ref) {
  return PrintTemplatesRepository(ref.watch(apiClientProvider));
});
