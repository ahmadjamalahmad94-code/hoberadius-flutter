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

  // Resolve the render engine (orientation + direction + label language),
  // mirroring normalize_render_engine + _ENGINE_PROFILES in card_renderer.py.
  final engine = _resolveEngine(layout);
  final orient = engine.orientation;
  final canvas = orient == CardOrientation.vertical
      ? CardCanvas.portrait
      : CardCanvas.landscape;
  final canvasW = canvas.width.toDouble();
  final canvasH = canvas.height.toDouble();

  final positions = _resolvePositions(template, layout, canvas, engine);
  final show = _resolveShowFlags(layout);

  final brandText = _override(ov, 'brand_name', layout, 'HobeRadius');
  final titleText = _override(ov, 'card_title', layout, 'بطاقة إنترنت');
  final footerText = _override(ov, 'footer_text', layout, '');
  final hotspotText = _override(ov, 'hotspot_address', layout, '');
  final priceText = _override(ov, 'price_text', layout, '');
  final validityTxt = _override(ov, 'validity_text', layout, '');

  final textColor = _safeHex(layout['text_color'], '#ffffff');
  final accentColor = _safeHex(layout['accent_color'], '#f59e0b');
  final surfaceColor = _safeHex(layout['surface_color'], '#e8f7fb');

  // Designer styling keys (mirror card_renderer.py). Per-credential surface
  // colours fall back to the shared surface; QR colours/size honour the
  // designer so saved web templates render the same here.
  final credInk = _safeHex(layout['credential_text_color'], '#0f172a');
  final credLabelColor = _safeHex(layout['credential_label_color'], '#64748b');
  final userSurface = _safeHex(layout['username_surface_color'], surfaceColor);
  final passSurface = _safeHex(layout['password_surface_color'], surfaceColor);
  final qrColor = _safeHex(layout['qr_color'], '#0f172a');
  final qrBg = _safeHex(layout['qr_background_color'], '#ffffff');
  final qrSizePct = _double(layout['qr_size_pct'], 0).clamp(0.0, 0.48);
  // Credential label language: arabic engines use اسم المستخدم/كلمة المرور,
  // latin engines use USER/PASS (matches _credential_label in the web).
  final labels = engine.labelLanguage == 'arabic'
      ? const _CredentialLabels('اسم المستخدم', 'كلمة المرور')
      : const _CredentialLabels('USER', 'PASS');

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

  // ── Logo (opt-in) ─────────────────────────────────────────────
  final logo = _logoElement(layout, canvasW, canvasH);
  if (logo != null) elements.add(logo);

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

  // ── Username pill ─────────────────────────────────────────────
  if (show['username']! && username.isNotEmpty) {
    elements.add(_pillElement(
      id: 'user',
      label: labels.user,
      value: username,
      pos: positions['user']!,
      canvasW: canvasW,
      canvasH: canvasH,
      surfaceColor: userSurface,
      ink: credInk,
      labelColor: credLabelColor,
      isPassword: false,
    ),
  );
  }

  // ── Password pill ─────────────────────────────────────────────
  if (show['password']! && password.isNotEmpty) {
    elements.add(_pillElement(
      id: 'pass',
      label: labels.pass,
      value: password,
      pos: positions['pass']!,
      canvasW: canvasW,
      canvasH: canvasH,
      surfaceColor: passSurface,
      ink: credInk,
      labelColor: credLabelColor,
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
    final qrSize = (qrSizePct > 0 ? qrSizePct : qr['size']!) * canvasW;
    elements.add(CardQr(
      id: 'qr',
      payload: payload,
      x: qr['x']! * canvasW,
      y: qr['y']! * canvasH,
      size: qrSize,
      background: qrBg,
      foreground: qrColor,
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
  _RenderEngine engine,
) {
  final cardWMm = _doubleClamp(layout['card_width_mm'], 85, 1.0);
  final cardHMm = _doubleClamp(layout['card_height_mm'], 54, 1.0);
  final vertical = engine.orientation == CardOrientation.vertical;

  // Engine default positions: portrait substitution + RTL composition flip
  // (mirror of _engine_default_positions in card_renderer.py).
  final base = vertical
      ? CardDefaultPositions.portraitTable
      : CardDefaultPositions.table;
  final positions = <String, Map<String, double>>{
    for (final entry in base.entries)
      entry.key: Map<String, double>.from(entry.value),
  };

  if (engine.direction == 'rtl') {
    final widthByKey = <String, double>{
      'brand': vertical ? 0.78 : 0.55,
      'title': vertical ? 0.78 : 0.55,
      'meta': vertical ? 0.80 : 0.88,
      'footer': vertical ? 0.80 : 0.88,
    };
    positions.forEach((key, pos) {
      final span =
          widthByKey[key] ?? pos['width'] ?? pos['size'] ?? 0.0;
      if (span > 0) {
        pos['x'] = (1.0 - (pos['x'] ?? 0.0) - span).clamp(0.0, 1.0);
      }
    });
  }

  // Custom dragged mm coordinates are absolute in the active engine,
  // applied after the engine defaults (so dragging never mirrors twice).
  const legacyKeys = [
    ['username', 'user'],
    ['password', 'pass'],
    ['qr', 'qr'],
  ];
  for (final pair in legacyKeys) {
    final rawX = _double(template['${pair[0]}_x'], 0);
    final rawY = _double(template['${pair[0]}_y'], 0);
    if (rawX == 0 && rawY == 0) continue; // keep defaults
    positions[pair[1]]!['x'] = (rawX / cardWMm).clamp(0.0, 1.0);
    positions[pair[1]]!['y'] = (rawY / cardHMm).clamp(0.0, 1.0);
  }

  // qr_size_pct overrides the QR slot size (clamp 0.08..0.48).
  final qrSizePct = _double(layout['qr_size_pct'], 0);
  if (qrSizePct > 0) {
    positions['qr']!['size'] = (qrSizePct / 100.0).clamp(0.08, 0.48);
  }
  return positions;
}

/// Resolved render engine — orientation + direction + credential label
/// language. Mirror of normalize_render_engine + _ENGINE_PROFILES.
class _RenderEngine {
  const _RenderEngine(this.orientation, this.direction, this.labelLanguage);
  final CardOrientation orientation;
  final String direction; // 'ltr' | 'rtl'
  final String labelLanguage; // 'arabic' | 'english'
}

_RenderEngine _resolveEngine(Map<String, dynamic> layout) {
  const profiles = {
    'en_horizontal': (CardOrientation.horizontal, 'ltr', 'english'),
    'en_vertical': (CardOrientation.vertical, 'ltr', 'english'),
    'ar_horizontal': (CardOrientation.horizontal, 'rtl', 'arabic'),
    'ar_vertical': (CardOrientation.vertical, 'rtl', 'arabic'),
  };
  final raw = (layout['render_engine'] ?? '').toString().trim().toLowerCase();
  final profile = profiles[raw];
  if (profile != null) {
    return _RenderEngine(profile.$1, profile.$2, profile.$3);
  }
  // Derive from legacy keys (card_orientation + text_direction + lang).
  final orient = CardOrientationParse.fromString(
    layout['card_orientation'] as String?,
  );
  final dirRaw = (layout['text_direction'] ?? '').toString().trim().toLowerCase();
  final langRaw =
      (layout['credential_label_language'] ?? '').toString().trim().toLowerCase();
  // Web rule: language = "ar" if direction=="rtl" OR label_language=="arabic",
  // else "en". So the default (both empty) is the LTR/english engine.
  final isArabic = dirRaw == 'rtl' || langRaw == 'arabic';
  return _RenderEngine(
    orient,
    isArabic ? 'rtl' : 'ltr',
    isArabic ? 'arabic' : 'english',
  );
}

Map<String, bool> _resolveShowFlags(Map<String, dynamic> layout) {
  return {
    for (final entry in CardDefaultPositions.showFlags.entries)
      entry.key: _boolish(layout['show_${entry.key}'], entry.value),
  };
}

/// Optional logo image element — mirror of `_logo_element` in
/// card_renderer.py. Position is mm in logo_x/logo_y; logo_size_pct is the
/// box width as % of card width (fallback 18%); (0,0) → top-left inset.
CardImage? _logoElement(
  Map<String, dynamic> layout,
  double canvasW,
  double canvasH,
) {
  final href = (layout['logo_image_data_url'] ?? '').toString();
  if (!href.startsWith('data:image/')) return null;
  final cardWMm = _doubleClamp(layout['card_width_mm'], 85, 1.0);
  final cardHMm = _doubleClamp(layout['card_height_mm'], 54, 1.0);
  final sizePct = _double(layout['logo_size_pct'], 0);
  final sizeFrac = sizePct > 0 ? (sizePct / 100.0).clamp(0.05, 0.6) : 0.18;
  final box = sizeFrac * canvasW;
  final rawX = _double(layout['logo_x'], 0);
  final rawY = _double(layout['logo_y'], 0);
  double x, y;
  if (rawX == 0 && rawY == 0) {
    x = canvasW * 0.06;
    y = canvasH * 0.06;
  } else {
    x = (rawX / cardWMm).clamp(0.0, 1.0) * canvasW;
    y = (rawY / cardHMm).clamp(0.0, 1.0) * canvasH;
  }
  return CardImage(
    id: 'logo',
    href: href,
    x: x,
    y: y,
    width: box,
    height: box,
  );
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
  String ink = '#0f172a',
  String labelColor = '#64748b',
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
    ink: ink,
    labelColor: labelColor,
    isPassword: isPassword,
    valueFontSize: height * 0.52,
    labelFontSize: height * 0.30,
    paddingX: height * 0.32,
  );
}

/// Credential pill labels resolved from the render engine / language, mirroring
/// `_credential_label` in card_renderer.py.
class _CredentialLabels {
  const _CredentialLabels(this.user, this.pass);
  final String user;
  final String pass;
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
