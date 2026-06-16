/// Unified card render model — Dart mirror of the web admin's
/// `app/radius/services/card_renderer.py` model.
///
/// One render model, two output adapters (SVG for preview,
/// backend-fetched PDF for export). The Dart adapter consumes the
/// SAME canvas-pinned coordinates so the Flutter Windows preview and
/// the server-side PDF never drift.
///
/// Canvas constants intentionally match the Python file byte-for-byte
/// (1000×600 landscape, 600×1000 portrait). Any change must land in
/// both languages in the same session — otherwise the screenshot diff
/// in Phase E will catch it immediately.
library;

import 'package:flutter/foundation.dart' show immutable;

/// Pinned canvas dimensions — mirror of
/// `CANVAS_LANDSCAPE = (1000, 600)` /
/// `CANVAS_PORTRAIT = (600, 1000)` in card_renderer.py.
class CardCanvas {
  const CardCanvas._();

  /// Landscape canvas (5:3 — same ratio as the designer preview CSS).
  static const landscape = CardCanvasSize(1000, 600);

  /// Portrait canvas (3:5).
  static const portrait = CardCanvasSize(600, 1000);
}

/// Two-dimensional canvas size in renderer units.
@immutable
class CardCanvasSize {
  const CardCanvasSize(this.width, this.height);
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardCanvasSize &&
          other.width == width &&
          other.height == height);

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'CardCanvasSize($width, $height)';
}

/// Card orientation. Matches the layout key in the Python builder.
enum CardOrientation { horizontal, vertical }

extension CardOrientationParse on CardOrientation {
  static CardOrientation fromString(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    return value == 'vertical'
        ? CardOrientation.vertical
        : CardOrientation.horizontal;
  }
}

/// Background description — gradient + optional bitmap + decorative
/// pattern. Mirrors `_background()` in card_renderer.py.
@immutable
class CardBackground {
  const CardBackground({
    required this.gradientStart,
    required this.gradientEnd,
    required this.pattern,
    required this.imageDataUrl,
    required this.imageOpacity,
  });

  /// Top-left gradient stop (web `gradient_start`).
  final String gradientStart;

  /// Bottom-right gradient stop (`gradient_end`).
  final String gradientEnd;

  /// One of `signal | wave | grid | clean`. Renderer skips overlay
  /// entirely on `clean`.
  final String pattern;

  /// Empty string if no image; otherwise a `data:image/png;base64,…`
  /// URL. The SVG adapter renders it as `<image>` with the same dim
  /// overlay the web uses.
  final String imageDataUrl;

  /// `0..1`. Same clamp the Python version applies.
  final double imageOpacity;

  bool get hasImage => imageDataUrl.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardBackground &&
          other.gradientStart == gradientStart &&
          other.gradientEnd == gradientEnd &&
          other.pattern == pattern &&
          other.imageDataUrl == imageDataUrl &&
          other.imageOpacity == imageOpacity);

  @override
  int get hashCode => Object.hash(
        gradientStart,
        gradientEnd,
        pattern,
        imageDataUrl,
        imageOpacity,
      );
}

/// Sealed hierarchy of drawable card elements. Mirror of the four
/// `kind` values the Python model emits.
sealed class CardElement {
  const CardElement({required this.id});

  /// Stable identifier (`accent` / `brand` / `title` / `user` /
  /// `pass` / `qr` / `meta` / `footer`). Both adapters can address
  /// individual elements by id for testing.
  final String id;
}

/// Solid filled rectangle (today only used for the accent bar).
class CardRect extends CardElement {
  const CardRect({
    required super.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fill,
    required this.cornerRadius,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final String fill;
  final double cornerRadius;
}

/// Drawn-on-canvas text run. Coordinates are canvas-unit top-left;
/// the SVG adapter uses `dominant-baseline="hanging"` and the PDF
/// adapter drops cap-height (~0.78 × size) to match visually.
class CardText extends CardElement {
  const CardText({
    required super.id,
    required this.text,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.weight,
    this.opacity = 1.0,
    this.maxWidth,
  });

  final String text;
  final double x;
  final double y;

  /// Font size in canvas units (1 unit ≈ 1 px in the SVG).
  final double size;
  final String color;

  /// 100-950, follows web fontWeight scale (mapped to bold/regular
  /// for the PDF adapter).
  final int weight;
  final double opacity;
  final double? maxWidth;
}

/// Credential pill: rounded surface + label + value (monospace).
class CardPill extends CardElement {
  const CardPill({
    required super.id,
    required this.label,
    required this.value,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.surface,
    required this.ink,
    required this.labelColor,
    required this.isPassword,
    required this.valueFontSize,
    required this.labelFontSize,
    required this.paddingX,
  });

  final String label;
  final String value;
  final double x;
  final double y;
  final double width;
  final double height;
  final String surface;
  final String ink;
  final String labelColor;
  final bool isPassword;
  final double valueFontSize;
  final double labelFontSize;
  final double paddingX;
}

/// Optional logo bitmap (`data:image/…` URL). Mirror of `_logo_element`
/// in card_renderer.py — opt-in, only emitted when a logo URL is present.
class CardImage extends CardElement {
  const CardImage({
    required super.id,
    required this.href,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String href;
  final double x;
  final double y;
  final double width;
  final double height;
}

/// QR symbol slot — the dark-module matrix is generated by the
/// adapter from `payload`; the model only carries position + size.
class CardQr extends CardElement {
  const CardQr({
    required super.id,
    required this.payload,
    required this.x,
    required this.y,
    required this.size,
    required this.background,
    required this.foreground,
  });

  final String payload;
  final double x;
  final double y;

  /// Total slot size (the white panel size). The actual QR symbol
  /// fills `size * 0.92` after the 4 % inner padding shared with the
  /// web adapter.
  final double size;
  final String background;
  final String foreground;
}

/// Final render model. Both adapters consume this immutable bundle.
@immutable
class CardRenderModel {
  const CardRenderModel({
    required this.canvas,
    required this.orientation,
    required this.background,
    required this.elements,
    required this.cardId,
    required this.username,
    required this.password,
  });

  final CardCanvasSize canvas;
  final CardOrientation orientation;
  final CardBackground background;

  /// Drawing order = list order, exactly like the Python builder.
  final List<CardElement> elements;

  final String cardId;
  final String username;

  /// Real password is kept on the model so the PDF adapter (backend)
  /// can render it. The SVG adapter MUST mask it.
  final String password;

  /// Convenience for tests + debug surfaces.
  Map<String, dynamic> toMap() => {
        'canvas': {'width': canvas.width, 'height': canvas.height},
        'orientation': orientation.name,
        'elements_count': elements.length,
        'card_id': cardId,
        'username': username,
        // Intentionally omit password from the map — never log it.
      };
}

/// Default element placements as fractions of the canvas — mirrors
/// `_DEFAULT_POSITIONS` byte-for-byte in card_renderer.py.
///
/// Keys deliberately match the Python dict keys (`accent` / `brand` /
/// `title` / `user` / `pass` / `qr` / `meta` / `footer`).
class CardDefaultPositions {
  const CardDefaultPositions._();

  static const Map<String, Map<String, double>> table = {
    'accent': {'x': 0.05, 'y': 0.07, 'width': 0.90, 'height': 0.018},
    'brand':  {'x': 0.06, 'y': 0.20, 'size': 0.075},
    'title':  {'x': 0.06, 'y': 0.33, 'size': 0.105},
    'user':   {'x': 0.06, 'y': 0.50, 'width': 0.46, 'height': 0.13},
    'pass':   {'x': 0.06, 'y': 0.66, 'width': 0.46, 'height': 0.13},
    'qr':     {'x': 0.66, 'y': 0.36, 'size': 0.27},
    'meta':   {'x': 0.06, 'y': 0.84, 'size': 0.05},
    'footer': {'x': 0.06, 'y': 0.95, 'size': 0.045},
  };

  /// Portrait-specific defaults — mirror of the `vertical` branch of
  /// `_engine_default_positions` in card_renderer.py. Without these,
  /// vertical cards stacked USER/PASS/QR in the top-left corner.
  static const Map<String, Map<String, double>> portraitTable = {
    'accent': {'x': 0.06, 'y': 0.045, 'width': 0.88, 'height': 0.012},
    'brand':  {'x': 0.07, 'y': 0.12, 'size': 0.046},
    'title':  {'x': 0.07, 'y': 0.20, 'size': 0.056},
    'qr':     {'x': 0.62, 'y': 0.30, 'size': 0.24},
    'user':   {'x': 0.07, 'y': 0.50, 'width': 0.56, 'height': 0.078},
    'pass':   {'x': 0.07, 'y': 0.61, 'width': 0.56, 'height': 0.078},
    'meta':   {'x': 0.07, 'y': 0.80, 'size': 0.028},
    'footer': {'x': 0.07, 'y': 0.88, 'size': 0.027},
  };

  /// Default show-flags — mirror of `_DEFAULT_SHOW`.
  static const Map<String, bool> showFlags = {
    'brand': true,
    'username': true,
    'password': true,
    'qr': true,
    'price': false,
    'hotspot': true,
    'validity': true,
    'serial': true,
  };
}
