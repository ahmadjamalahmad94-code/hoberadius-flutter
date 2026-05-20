class CardPrintTemplate {
  const CardPrintTemplate({
    required this.id,
    required this.name,
    required this.orientation,
    required this.cardsPerRow,
    required this.cardsPerColumn,
    required this.pageSize,
    required this.showQr,
    required this.usernameX,
    required this.usernameY,
    required this.passwordX,
    required this.passwordY,
    required this.qrX,
    required this.qrY,
    required this.fontSize,
    required this.color,
    required this.layout,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String orientation;
  final int cardsPerRow;
  final int cardsPerColumn;
  final String pageSize;
  final bool showQr;
  final double usernameX;
  final double usernameY;
  final double passwordX;
  final double passwordY;
  final double qrX;
  final double qrY;
  final int fontSize;
  final String color;
  final Map<String, dynamic> layout;
  final DateTime? createdAt;

  int get cardsPerPage => cardsPerRow * cardsPerColumn;

  factory CardPrintTemplate.fromJson(Map<String, dynamic> json) {
    final layout = json['layout_json'] ?? json['layout'];
    return CardPrintTemplate(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      orientation: (json['orientation'] ?? 'portrait').toString(),
      cardsPerRow: _asInt(json['cards_per_row']),
      cardsPerColumn: _asInt(json['cards_per_column']),
      pageSize: (json['page_size'] ?? 'A4').toString(),
      showQr: _asBool(json['show_qr']),
      usernameX: _asDouble(json['username_x']),
      usernameY: _asDouble(json['username_y']),
      passwordX: _asDouble(json['password_x']),
      passwordY: _asDouble(json['password_y']),
      qrX: _asDouble(json['qr_x']),
      qrY: _asDouble(json['qr_y']),
      fontSize: _asInt(json['font_size']),
      color: (json['color'] ?? '#1f2937').toString(),
      layout: layout is Map
          ? layout.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class PrintTemplatePreview {
  const PrintTemplatePreview({
    required this.cardsPerPage,
    required this.renderer,
    required this.qrSupported,
    required this.sample,
    required this.exportGenerated,
  });

  final int cardsPerPage;
  final String renderer;
  final bool qrSupported;
  final Map<String, dynamic> sample;
  final bool exportGenerated;

  factory PrintTemplatePreview.fromJson(Map<String, dynamic> json) {
    final preview = json['preview'];
    final previewMap = preview is Map
        ? preview.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final sample = previewMap['sample'];
    return PrintTemplatePreview(
      cardsPerPage: _asInt(previewMap['cards_per_page']),
      renderer: (previewMap['renderer'] ?? '').toString(),
      qrSupported: _asBool(previewMap['qr_supported']),
      sample: sample is Map
          ? sample.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      exportGenerated: _asBool(json['export_generated']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}
