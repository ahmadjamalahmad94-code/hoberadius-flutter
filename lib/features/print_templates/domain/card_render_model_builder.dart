/// Dart mirror of `build_card_render_model` in card_renderer.py.
///
/// Given a template + optional card + optional override map, returns
/// a fully-resolved [CardRenderModel]. The output is byte-identical
/// (modulo `dart`-vs-`python` float printing) to what the web admin's
/// `render_card_svg(build_card_render_model(...))` produces.
library;

import 'card_render_model.dart';

/// Public entry point — same signature as the Python function.
CardRenderModel buildCardRenderModel(
  Map<String, dynamic> template, {
  Map<String, dynamic>? card,
  Map<String, String>? overrides,
}) {
  final layout = _hydrateLayout(template);
  final ov = overrides ?? const <String, String>{};

  final orient = CardOrientationParse.fromString(
    layout['card_orientation'] as String?,
  );
  final canvas = orient == CardOrientation.vertical
      ? CardCanvas.portrait
      : CardCanvas.landscape;
  final canvasW = canvas.width.toDouble();
  final canvasH = canvas.height.toDouble();

  final positions = _resolvePositions(template, layout, canvas);
  final show = _resolveShowFlags(layout);

  final brandText = _override(ov, 'brand_name', layout, 'HobeRadius');
  final titleText = _override(ov, 'card_title', layout, 'Internet Card');
  final footerText = _override(ov, 'footer_text', layout, '');
  final hotspotText = _override(ov, 'hotspot_address', layout, '');
  final priceText = _override(ov, 'price_text', layout, '');
  final validityTxt = _override(ov, 'validity_text', layout, '');

  final textColor = _safeHex(layout['text_color'], '#ffffff');
  final accentColor = _safeHex(layout['accent_color'], '#f59e0b');
  final surfaceColor = _safeHex(layout['surface_color'], '#e8f7fb');

  final extracted = _extractCardFields(card);
  final username = extracted.username;
  final password = extracted.password;
  final cardId = extracted.cardId;

  final elements = <CardElement>[];

  // ── Accent bar ────────────────────────────────────────────────
  final acc = positions['accent']!;
  elements.add(CardRect(
    id: 'accent',
    x: acc['x']! * canvasW,
    y: acc['y']! * canvasH,
    width: acc['width']! * canvasW,
    height: acc['height']! * canvasH,
    fill: accentColor,
    cornerRadius: acc['height']! * canvasH / 2,
  ),
  );

  // ── Brand ─────────────────────────────────────────────────────
  if (show['brand']! && brandText.isNotEmpty) {
    elements.add(_textElement(
      id: 'brand',
      text: brandText,
      pos: positions['brand']!,
      canvasW: canvasW,
      canvasH: canvasH,
      color: textColor,
      weight: 900,
      maxWidthFrac: 0.55,
    ),
  );
  }

  // ── Title ─────────────────────────────────────────────────────
  if (titleText.isNotEmpty) {
    elements.add(_textElement(
      id: 'title',
      text: titleText,
      pos: positions['title']!,
      canvasW: canvasW,
      canvasH: canvasH,
      color: textColor,
      weight: 950,
      maxWidthFrac: 0.55,
    ),
  );
  }

  // ── USER pill ─────────────────────────────────────────────────
  if (show['username']! && username.isNotEmpty) {
    elements.add(_pillElement(
      id: 'user',
      label: 'USER',
      value: username,
      pos: positions['user']!,
      canvasW: canvasW,
      canvasH: canvasH,
      surfaceColor: surfaceColor,
      isPassword: false,
    ),
  );
  }

  // ── PASS pill ─────────────────────────────────────────────────
  if (show['password']! && password.isNotEmpty) {
    elements.add(_pillElement(
      id: 'pass',
      label: 'PASS',
      value: password,
      pos: positions['pass']!,
      canvasW: canvasW,
      canvasH: canvasH,
      surfaceColor: surfaceColor,
      isPassword: true,
    ),
  );
  }

  // ── QR ────────────────────────────────────────────────────────
  if (show['qr']!) {
    final qr = positions['qr']!;
    final payload = username.isNotEmpty
        ? username
        : (cardId.isNotEmpty ? cardId : 'SAMPLE');
    elements.add(CardQr(
      id: 'qr',
      payload: payload,
      x: qr['x']! * canvasW,
      y: qr['y']! * canvasH,
      size: qr['size']! * canvasW,
      background: '#ffffff',
      foreground: '#0f172a',
    ),
  );
  }

  // ── Meta line ─────────────────────────────────────────────────
  final metaParts = <String>[];
  if (show['hotspot']! && hotspotText.isNotEmpty) metaParts.add(hotspotText);
  if (show['price']! && priceText.isNotEmpty) metaParts.add(priceText);
  if (show['validity']! && validityTxt.isNotEmpty) metaParts.add(validityTxt);
  if (show['serial']! && cardId.isNotEmpty) metaParts.add('#$cardId');
  if (metaParts.isNotEmpty) {
    final meta = positions['meta']!;
    elements.add(CardText(
      id: 'meta',
      text: metaParts.join('  ·  '),
      x: meta['x']! * canvasW,
      y: meta['y']! * canvasH,
      size: meta['size']! * canvasH,
      color: textColor,
      weight: 800,
      maxWidth: canvasW * 0.88,
    ),
  );
  }

  // ── Footer ────────────────────────────────────────────────────
  if (footerText.isNotEmpty) {
    final footer = positions['footer']!;
    elements.add(CardText(
      id: 'footer',
      text: footerText,
      x: footer['x']! * canvasW,
      y: footer['y']! * canvasH,
      size: footer['size']! * canvasH,
      color: textColor,
      weight: 800,
      opacity: 0.82,
      maxWidth: canvasW * 0.88,
    ),
  );
  }

  return CardRenderModel(
    canvas: canvas,
    orientation: orient,
    background: _background(layout),
    elements: elements,
    cardId: cardId,
    username: username,
    password: password,
  );
}

// ───────────────────────────────────────────────────────────────────
// Internal helpers — direct ports of the Python utilities
// ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _hydrateLayout(Map<String, dynamic> template) {
  final layout = template['layout_json'];
  if (layout is Map<String, dynamic>) return layout;
  final altLayout = template['layout'];
  if (altLayout is Map<String, dynamic>) return altLayout;
  return const <String, dynamic>{};
}

Map<String, Map<String, double>> _resolvePositions(
  Map<String, dynamic> template,
  Map<String, dynamic> layout,
  CardCanvasSize canvas,
) {
  final cardWMm = _doubleClamp(layout['card_width_mm'], 85, 1.0);
  final cardHMm = _doubleClamp(layout['card_height_mm'], 54, 1.0);

  // Deep-copy the defaults so callers don't observe shared state.
  final positions = <String, Map<String, double>>{
    for (final entry in CardDefaultPositions.table.entries)
      entry.key: Map<String, double>.from(entry.value),
  };

  const legacyKeys = [
    ['username', 'user'],
    ['password', 'pass'],
    ['qr', 'qr'],
  ];
  for (final pair in legacyKeys) {
    final legacy = pair[0];
    final target = pair[1];
    final rawX = _double(template['${legacy}_x'], 0);
    final rawY = _double(template['${legacy}_y'], 0);
    if (rawX == 0 && rawY == 0) continue; // keep defaults
    final fx = (rawX / cardWMm).clamp(0.0, 1.0);
    final fy = (rawY / cardHMm).clamp(0.0, 1.0);
    positions[target]!['x'] = fx;
    positions[target]!['y'] = fy;
  }
  return positions;
}

Map<String, bool> _resolveShowFlags(Map<String, dynamic> layout) {
  return {
    for (final entry in CardDefaultPositions.showFlags.entries)
      entry.key: _boolish(layout['show_${entry.key}'], entry.value),
  };
}

CardBackground _background(Map<String, dynamic> layout) {
  final image = (layout['background_image_data_url'] as String?) ?? '';
  return CardBackground(
    gradientStart: _safeHex(layout['gradient_start'], '#0f172a'),
    gradientEnd: _safeHex(layout['gradient_end'], '#22a7bd'),
    pattern:
        (layout['pattern_style'] as String?)?.trim().toLowerCase() ?? 'signal',
    imageDataUrl: image.startsWith('data:image/') ? image : '',
    imageOpacity:
        _double(layout['image_opacity'], 0.82).clamp(0.0, 1.0).toDouble(),
  );
}

String _override(
  Map<String, String> overrides,
  String key,
  Map<String, dynamic> layout,
  String fallback,
) {
  final candidate = overrides[key];
  if (candidate != null && candidate.trim().isNotEmpty) return candidate.trim();
  final layoutValue = layout[key];
  if (layoutValue == null) return fallback;
  final text = layoutValue.toString().trim();
  return text.isEmpty ? fallback : text;
}

class _CardFields {
  const _CardFields(this.username, this.password, this.cardId);
  final String username;
  final String password;
  final String cardId;
}

_CardFields _extractCardFields(Map<String, dynamic>? card) {
  if (card == null) return const _CardFields('SAMPLE', '********', '');
  String pick(String key) => (card[key] ?? '').toString().trim();
  final username = pick('username');
  final password = pick('password');
  final id = card['id']?.toString().trim() ?? '';
  final serial = card['serial']?.toString().trim() ?? '';
  return _CardFields(
    username.isEmpty ? 'SAMPLE' : username,
    password.isEmpty ? '********' : password,
    id.isNotEmpty ? id : serial,
  );
}

CardText _textElement({
  required String id,
  required String text,
  required Map<String, double> pos,
  required double canvasW,
  required double canvasH,
  required String color,
  required int weight,
  required double maxWidthFrac,
}) {
  return CardText(
    id: id,
    text: text,
    x: pos['x']! * canvasW,
    y: pos['y']! * canvasH,
    size: pos['size']! * canvasH,
    color: color,
    weight: weight,
    maxWidth: canvasW * maxWidthFrac,
  );
}

CardPill _pillElement({
  required String id,
  required String label,
  required String value,
  required Map<String, double> pos,
  required double canvasW,
  required double canvasH,
  required String surfaceColor,
  required bool isPassword,
}) {
  final width = (pos['width'] ?? 0.46) * canvasW;
  final height = (pos['height'] ?? 0.13) * canvasH;
  return CardPill(
    id: id,
    label: label,
    value: value,
    x: pos['x']! * canvasW,
    y: pos['y']! * canvasH,
    width: width,
    height: height,
    surface: surfaceColor,
    ink: '#0f172a',
    labelColor: '#64748b',
    isPassword: isPassword,
    valueFontSize: height * 0.52,
    labelFontSize: height * 0.30,
    paddingX: height * 0.32,
  );
}

// ── tiny utilities ────────────────────────────────────────────────

final _hexRe = RegExp(r'^#?[0-9a-fA-F]{3,8}$');

String _safeHex(Object? value, String fallback) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return fallback;
  final withHash = raw.startsWith('#') ? raw : '#$raw';
  return _hexRe.hasMatch(withHash) ? withHash : fallback;
}

double _double(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback;
}

double _doubleClamp(Object? value, double fallback, double minimum) {
  final v = _double(value, fallback);
  return v < minimum ? minimum : v;
}

bool _boolish(Object? value, bool fallback) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return const {'1', 'true', 'yes', 'on', 'y', 't'}
      .contains(value.toString().trim().toLowerCase());
}
