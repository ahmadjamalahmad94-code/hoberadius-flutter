/// Dart mirror of `render_card_svg` in card_renderer.py.
///
/// Takes a [CardRenderModel] and returns an SVG string that
/// `flutter_svg` can render. The XML output matches the web's
/// adapter byte-for-byte (modulo float-printing differences), so a
/// preview captured in the Flutter Windows build looks identical to
/// the one captured in Chrome.
///
/// Critically:
///   - `direction="ltr"` is pinned on the root <svg> AND every
///     <text> — Material/Flutter inherits document direction the
///     same way the browser does, and English card labels would
///     otherwise walk off the left edge inside a `MaterialApp(rtl)`.
///   - QR matrix is generated via the `qr` package using the same
///     ISO/IEC 18004 algorithm the web's QrCodeWidget uses, so the
///     scanned symbol resolves to the same payload on both sides.
library;

import 'package:qr/qr.dart';

import '../domain/card_render_model.dart';

/// Entry point. `maskPassword=true` (default) replaces password
/// pill values with bullets — the live preview NEVER reveals the
/// real password. The PDF (backend) carries the real value.
String renderCardSvg(CardRenderModel model, {bool maskPassword = true}) {
  final w = model.canvas.width;
  final h = model.canvas.height;
  final bg = model.background;

  final buf = StringBuffer()
    // The `direction="ltr"` attribute + the same inline style is
    // the three-layer defence we ported from the web. Without it,
    // English text inside <html dir="rtl"> renders off-canvas.
    ..write(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'viewBox="0 0 $w $h" preserveAspectRatio="xMidYMid meet" '
      'role="img" class="card-svg" '
      'direction="ltr" '
      'style="width:100%;height:auto;display:block;direction:ltr">',
    )
    ..write('<defs>');

  for (final part in _svgDefs(bg, w, h)) {
    buf.write(part);
  }
  final clipRadius = (w * 0.025).round();
  buf.write(
    '<clipPath id="card-clip">'
    '<rect x="0" y="0" width="$w" height="$h" '
    'rx="$clipRadius" ry="$clipRadius"/>'
    '</clipPath>',
  );
  buf.write('</defs>');

  buf.write('<g clip-path="url(#card-clip)">');
  for (final part in _svgBackground(bg, w, h)) {
    buf.write(part);
  }

  for (final el in model.elements) {
    switch (el) {
      case CardRect():
        buf.write(_svgRect(el));
      case CardText():
        buf.write(_svgText(el));
      case CardPill():
        buf.write(_svgPill(el, maskPassword: maskPassword));
      case CardQr():
        buf.write(_svgQr(el));
    }
  }

  buf
    ..write('</g>')
    ..write('</svg>');
  return buf.toString();
}

// ───────────────────────────────────────────────────────────────────
// SVG helpers — mirror of the Python emitters
// ───────────────────────────────────────────────────────────────────

Iterable<String> _svgDefs(CardBackground bg, int w, int h) sync* {
  yield '<linearGradient id="card-bg" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0%" stop-color="${_xml(bg.gradientStart)}"/>'
      '<stop offset="100%" stop-color="${_xml(bg.gradientEnd)}"/>'
      '</linearGradient>';

  switch (bg.pattern) {
    case 'grid':
      final step = (w * 0.045).clamp(8, double.infinity).round();
      yield '<pattern id="card-pattern" patternUnits="userSpaceOnUse" '
          'width="$step" height="$step">'
          '<path d="M$step 0 L0 0 0 $step" fill="none" '
          'stroke="rgba(255,255,255,.45)" stroke-width="1"/>'
          '</pattern>';
    case 'wave':
      yield '<radialGradient id="card-pattern" cx="20%" cy="30%" r="55%">'
          '<stop offset="0%"  stop-color="rgba(255,255,255,.30)"/>'
          '<stop offset="60%" stop-color="rgba(255,255,255,0)"/>'
          '</radialGradient>';
    case 'signal':
      final barStep = (w * 0.025).clamp(6, double.infinity).round();
      final barWidth = (w * 0.005).clamp(2, double.infinity).round();
      final patternH = h;
      final barY = (h * 0.7).round();
      final barH = (h * 0.3).round();
      yield '<pattern id="card-pattern" patternUnits="userSpaceOnUse" '
          'width="$barStep" height="$patternH">'
          '<rect x="0" y="$barY" width="$barWidth" '
          'height="$barH" fill="rgba(255,255,255,.40)"/>'
          '</pattern>';
    default:
      // 'clean' emits no overlay.
      break;
  }
}

Iterable<String> _svgBackground(CardBackground bg, int w, int h) sync* {
  yield '<rect x="0" y="0" width="$w" height="$h" fill="url(#card-bg)"/>';

  if (bg.hasImage) {
    yield '<image href="${_xml(bg.imageDataUrl)}" x="0" y="0" '
        'width="$w" height="$h" '
        'preserveAspectRatio="xMidYMid slice" '
        'opacity="${bg.imageOpacity.toStringAsFixed(2)}"/>';
    yield '<rect x="0" y="0" width="$w" height="$h" '
        'fill="rgba(15,23,42,0.32)"/>';
  }

  if (bg.pattern == 'grid' || bg.pattern == 'signal') {
    yield '<rect x="0" y="0" width="$w" height="$h" '
        'fill="url(#card-pattern)" opacity="0.45"/>';
  } else if (bg.pattern == 'wave') {
    yield '<rect x="0" y="0" width="$w" height="$h" '
        'fill="url(#card-pattern)"/>';
  }
}

String _svgRect(CardRect el) {
  return '<rect x="${el.x.toStringAsFixed(1)}" y="${el.y.toStringAsFixed(1)}" '
      'width="${el.width.toStringAsFixed(1)}" height="${el.height.toStringAsFixed(1)}" '
      'rx="${el.cornerRadius.toStringAsFixed(1)}" '
      'ry="${el.cornerRadius.toStringAsFixed(1)}" '
      'fill="${_xml(el.fill)}"/>';
}

String _svgText(CardText el) {
  // direction="ltr" + text-anchor="start" duplicated here in
  // addition to the root SVG to defend against renderers that
  // ignore the SVG-level direction attribute. See the Python
  // file's `_svg_text` comment for the underlying bug.
  return '<text x="${el.x.toStringAsFixed(1)}" '
      'y="${el.y.toStringAsFixed(1)}" '
      'direction="ltr" '
      'font-family="\'Almarai\', \'Cairo\', \'Helvetica Neue\', Arial, sans-serif" '
      'font-size="${el.size.toStringAsFixed(1)}" '
      'font-weight="${el.weight}" '
      'fill="${_xml(el.color)}" '
      'opacity="${el.opacity.toStringAsFixed(2)}" '
      'dominant-baseline="hanging" text-anchor="start" xml:space="preserve">'
      '${_xml(el.text)}'
      '</text>';
}

String _svgPill(CardPill el, {required bool maskPassword}) {
  var value = el.value;
  if (maskPassword && el.isPassword) {
    final len = value.length.clamp(6, 10);
    value = '•' * len;
  }
  final labelY = el.y + el.height * 0.36;
  final valueY = el.y + el.height * 0.72;
  final rx = (el.height * 0.20).toStringAsFixed(1);
  final pad = el.paddingX;
  return '<g class="card-pill">'
      '<rect x="${el.x.toStringAsFixed(1)}" y="${el.y.toStringAsFixed(1)}" '
      'width="${el.width.toStringAsFixed(1)}" '
      'height="${el.height.toStringAsFixed(1)}" '
      'rx="$rx" ry="$rx" '
      'fill="${_xml(el.surface)}" opacity="0.95"/>'
      '<text x="${(el.x + pad).toStringAsFixed(1)}" '
      'y="${labelY.toStringAsFixed(1)}" '
      'direction="ltr" '
      'font-family="\'Almarai\', \'Cairo\', \'Helvetica Neue\', Arial, sans-serif" '
      'font-size="${el.labelFontSize.toStringAsFixed(1)}" '
      'font-weight="900" fill="${_xml(el.labelColor)}" '
      'dominant-baseline="middle" text-anchor="start" '
      'xml:space="preserve">${_xml(el.label)}</text>'
      '<text x="${(el.x + pad).toStringAsFixed(1)}" '
      'y="${valueY.toStringAsFixed(1)}" '
      'direction="ltr" '
      'font-family="\'Menlo\', \'Consolas\', monospace" '
      'font-size="${el.valueFontSize.toStringAsFixed(1)}" '
      'font-weight="900" fill="${_xml(el.ink)}" '
      'dominant-baseline="middle" text-anchor="start" '
      'xml:space="preserve">${_xml(value)}</text>'
      '</g>';
}

String _svgQr(CardQr el) {
  final size = el.size < 16 ? 16.0 : el.size;
  final x = el.x;
  final y = el.y;
  // 4 % inner padding — same as the web after the P1 polish.
  final pad = size * 0.04;
  final inner = _qrInlineSvg(
    payload: el.payload,
    x: x + pad,
    y: y + pad,
    size: size - 2 * pad,
    fg: el.foreground,
  );
  return '<g class="card-qr">'
      '<rect x="${x.toStringAsFixed(1)}" y="${y.toStringAsFixed(1)}" '
      'width="${size.toStringAsFixed(1)}" height="${size.toStringAsFixed(1)}" '
      'rx="${(size * 0.10).toStringAsFixed(1)}" '
      'ry="${(size * 0.10).toStringAsFixed(1)}" '
      'fill="${_xml(el.background)}"/>'
      '$inner'
      '</g>';
}

String _qrInlineSvg({
  required String payload,
  required double x,
  required double y,
  required double size,
  required String fg,
}) {
  try {
    // QrCode.fromData uses the same ISO/IEC 18004 algorithm the
    // web's reportlab.QrCodeWidget uses. We pick error-correction
    // level L for the smallest matrix that still scans reliably at
    // print size, then walk the bit matrix once and emit one
    // <rect> per dark module — same shape the web SVG outputs.
    final qrCode = QrCode.fromData(
      data: payload,
      errorCorrectLevel: QrErrorCorrectLevel.L,
    );
    final image = QrImage(qrCode);
    final n = image.moduleCount;
    if (n == 0) return _placeholderGrid(x, y, size, fg);
    final cell = size / n;
    final buf = StringBuffer();
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        if (!image.isDark(row, col)) continue;
        final rx = (x + col * cell).toStringAsFixed(2);
        final ry = (y + row * cell).toStringAsFixed(2);
        // 1.02 overlap prevents thin white hairlines at fractional
        // zoom levels (same trick the Python adapter uses).
        final cellW = (cell * 1.02).toStringAsFixed(2);
        buf.write('<rect x="$rx" y="$ry" '
            'width="$cellW" height="$cellW" '
            'fill="${_xml(fg)}"/>');
      }
    }
    return buf.toString();
  } catch (_) {
    return _placeholderGrid(x, y, size, fg);
  }
}

String _placeholderGrid(double x, double y, double size, String fg) {
  final cell = size / 7;
  final buf = StringBuffer();
  for (var r = 0; r < 7; r++) {
    for (var c = 0; c < 7; c++) {
      if ((r + c) % 2 != 0) continue;
      final rx = (x + c * cell).toStringAsFixed(2);
      final ry = (y + r * cell).toStringAsFixed(2);
      final cs = cell.toStringAsFixed(2);
      buf.write('<rect x="$rx" y="$ry" '
          'width="$cs" height="$cs" '
          'fill="${_xml(fg)}" opacity="0.35"/>');
    }
  }
  return buf.toString();
}

// ── tiny utilities ────────────────────────────────────────────────

const _xmlEscapes = [
  ['&', '&amp;'],
  ['<', '&lt;'],
  ['>', '&gt;'],
  ['"', '&quot;'],
  ["'", '&#39;'],
];

String _xml(Object? value) {
  var text = (value ?? '').toString();
  for (final pair in _xmlEscapes) {
    text = text.replaceAll(pair[0], pair[1]);
  }
  return text;
}
