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

  String get designPreset => _layoutString('design_preset', 'modern');
  String get brandName => _layoutString('brand_name', 'HobeRadius');
  String get cardTitle => _layoutString('card_title', 'بطاقة إنترنت');
  String get footerText =>
      _layoutString('footer_text', 'احتفظ بالبطاقة حتى انتهاء الصلاحية');
  String get hotspotAddress => _layoutString('hotspot_address', '');
  String get priceText => _layoutString('price_text', '');
  String get validityText => _layoutString('validity_text', '');
  String get instructionsText => _layoutString('instructions_text', '');
  String get gradientStart => _layoutString('gradient_start', '#0f172a');
  String get gradientEnd => _layoutString('gradient_end', '#2563eb');
  String get accentColor => _layoutString('accent_color', '#22d3ee');
  String get textColor => _layoutString('text_color', '#ffffff');
  String get surfaceColor => _layoutString('surface_color', '#ffffff');
  String get qrStyle => _layoutString('qr_style', 'square');
  String get backgroundStyle => _layoutString('background_style', 'gradient');
  bool get showUsername => _layoutBool('show_username', true);
  bool get showPassword => _layoutBool('show_password', true);
  bool get showPrice => _layoutBool('show_price', true);
  bool get showValidity => _layoutBool('show_validity', true);
  bool get showPlanName => _layoutBool('show_plan_name', true);
  bool get showSerial => _layoutBool('show_serial', true);
  bool get showHotspot => _layoutBool('show_hotspot', true);

  String _layoutString(String key, String fallback) {
    final value = layout[key];
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  bool _layoutBool(String key, bool fallback) {
    if (!layout.containsKey(key)) return fallback;
    return _asBool(layout[key]);
  }

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

class PrintTemplatePreset {
  const PrintTemplatePreset({
    required this.key,
    required this.name,
    required this.description,
    required this.layout,
  });

  final String key;
  final String name;
  final String description;
  final Map<String, dynamic> layout;

  factory PrintTemplatePreset.fromJson(Map<String, dynamic> json) {
    final layout = json['layout'];
    return PrintTemplatePreset(
      key: (json['key'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      layout: layout is Map
          ? layout.map((key, value) => MapEntry(key.toString(), value))
          : const {},
    );
  }
}

class PrintJob {
  const PrintJob({
    required this.id,
    required this.templateId,
    this.batchId,
    required this.exportType,
    required this.status,
    required this.cardCount,
    required this.fileName,
    required this.message,
    required this.createdBy,
    this.createdAt,
    this.completedAt,
  });

  final int id;
  final int templateId;
  final int? batchId;
  final String exportType;
  final String status;
  final int cardCount;
  final String fileName;
  final String message;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get succeeded => status == 'success';

  factory PrintJob.fromJson(Map<String, dynamic> json) => PrintJob(
        id: _asInt(json['id']),
        templateId: _asInt(json['template_id']),
        batchId: _nullableInt(json['batch_id']),
        exportType: (json['export_type'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        cardCount: _asInt(json['card_count']),
        fileName: (json['file_name'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        createdBy: (json['created_by'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
        completedAt: DateTime.tryParse((json['completed_at'] ?? '').toString()),
      );
}

class PrintTemplatePreview {
  const PrintTemplatePreview({
    required this.template,
    required this.cardsPerPage,
    required this.renderer,
    required this.qrSupported,
    required this.card,
    required this.placements,
    required this.sample,
    required this.exportGenerated,
  });

  final CardPrintTemplate template;
  final int cardsPerPage;
  final String renderer;
  final bool qrSupported;
  final Map<String, dynamic> card;
  final Map<String, dynamic> placements;
  final Map<String, dynamic> sample;
  final bool exportGenerated;

  factory PrintTemplatePreview.fromJson(Map<String, dynamic> json) {
    final preview = json['preview'];
    final previewMap = preview is Map
        ? preview.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final sample = previewMap['sample'];
    final template = json['template'];
    final card = previewMap['card'];
    final placements = previewMap['placements'];
    return PrintTemplatePreview(
      template: CardPrintTemplate.fromJson(
        template is Map
            ? template.map((key, value) => MapEntry(key.toString(), value))
            : const {},
      ),
      cardsPerPage: _asInt(previewMap['cards_per_page']),
      renderer: (previewMap['renderer'] ?? '').toString(),
      qrSupported: _asBool(previewMap['qr_supported']),
      card: card is Map
          ? card.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      placements: placements is Map
          ? placements.map((key, value) => MapEntry(key.toString(), value))
          : const {},
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

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
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
