/// The web «منشئ كروت PDF» form, field for field (cards_print_quick.html).
///
/// The app sends exactly these fields and the server runs the web designer's
/// own builder on them, so defaults and prefill MUST match the web template:
/// every `?? default` below mirrors a `{{ fl.x or default }}` there.
class QuickPrintForm {
  const QuickPrintForm({
    this.name = 'قالب سريع',
    this.imageFit = 'stretch',
    this.backgroundStyle = 'image',
    this.renderEngine = 'ar_vertical',
    this.cardWidthMm = 54,
    this.cardHeightMm = 85.6,
    this.designPreset = 'modern',
    this.hotspotAddress = 'hotspot.local',
    this.backgroundDataUrl = '',
    this.backgroundName = '',
    this.backgroundOptimized = false,
    this.usernameFontSize = 0,
    this.passwordFontSize = 0,
    this.showQr = false,
    this.showPrice = false,
    this.hotspotLoginUrl = '',
    this.surfaceOn = true,
    this.usernameSurfaceColor = '#e8f7fb',
    this.passwordSurfaceColor = '#e8f7fb',
    this.surfaceColor = '#e8f7fb',
    this.usernameX = 0,
    this.usernameY = 0,
    this.passwordX = 0,
    this.passwordY = 0,
    this.qrX = 0,
    this.qrY = 0,
    this.qrSizePct = 0,
  });

  final String name;
  final String imageFit;
  final String backgroundStyle;
  final String renderEngine;
  final double cardWidthMm;
  final double cardHeightMm;
  final String designPreset;
  final String hotspotAddress;
  final String backgroundDataUrl;
  final String backgroundName;

  /// True when [backgroundDataUrl] already went through the server's
  /// optimizer (stored template, or a picked image sent to /background).
  final bool backgroundOptimized;

  /// 0 = «تلقائي».
  final double usernameFontSize;
  final double passwordFontSize;
  final bool showQr;
  final bool showPrice;
  final String hotspotLoginUrl;
  final bool surfaceOn;
  final String usernameSurfaceColor;
  final String passwordSurfaceColor;
  final String surfaceColor;

  /// Positions in mm; 0 = automatic.
  final double usernameX;
  final double usernameY;
  final double passwordX;
  final double passwordY;
  final double qrX;
  final double qrY;
  final double qrSizePct;

  bool get vertical => renderEngine != 'ar_horizontal';
  bool get hasImage => backgroundDataUrl.startsWith('data:image/');

  /// Web prefill for a saved template (`tpl` row: columns + `layout_json`).
  /// [fallbackLoginUrl]: the first non-empty login URL of any template (the
  /// web route suggests it so the URL is typed once, not per template).
  factory QuickPrintForm.fromTemplate(
    Map<String, dynamic>? tpl, {
    String fallbackLoginUrl = '',
  }) {
    if (tpl == null) {
      return QuickPrintForm(hotspotLoginUrl: fallbackLoginUrl);
    }
    final raw = tpl['layout_json'] ?? tpl['layout'];
    final fl =
        raw is Map ? raw.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};
    String str(String k, String d) {
      final v = fl[k];
      final s = v == null ? '' : '$v';
      return s.isEmpty ? d : s;
    }

    double numOf(Object? v, double d) {
      final n = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
      return (n == null || n == 0) ? d : n;
    }

    bool truthy(Object? v) =>
        v == true || v == 1 || '$v'.toLowerCase() == 'true' || '$v' == '1';

    final surfOn = fl.containsKey('username_surface_enabled')
        ? truthy(fl['username_surface_enabled'])
        : fl.containsKey('credential_background_enabled')
            ? truthy(fl['credential_background_enabled'])
            : true;
    final surface = str('surface_color', '#e8f7fb');
    final ownLogin = '${fl['hotspot_login_url'] ?? ''}'.trim();
    return QuickPrintForm(
      name: '${tpl['name'] ?? ''}'.trim().isEmpty
          ? 'قالب سريع'
          : '${tpl['name']}',
      imageFit: str('image_fit', 'stretch'),
      backgroundStyle: str('background_style', 'image'),
      renderEngine: str('render_engine', 'ar_vertical'),
      cardWidthMm: numOf(fl['card_width_mm'], 54),
      cardHeightMm: numOf(fl['card_height_mm'], 85.6),
      designPreset: str('design_preset', 'modern'),
      hotspotAddress: str('hotspot_address', 'hotspot.local'),
      backgroundDataUrl: str('background_image_data_url', ''),
      backgroundName: str('background_image_name', ''),
      backgroundOptimized: true,
      usernameFontSize: numOf(fl['username_font_size'], 0),
      passwordFontSize: numOf(fl['password_font_size'], 0),
      showQr: truthy(fl['show_qr']),
      showPrice: truthy(fl['show_price']),
      // Web: `qr_login_url or fl.hotspot_login_url` — own URL first.
      hotspotLoginUrl: ownLogin.isNotEmpty ? ownLogin : fallbackLoginUrl,
      surfaceOn: surfOn,
      usernameSurfaceColor: str(
        'username_surface_color',
        str('surface_color', '#e8f7fb'),
      ),
      passwordSurfaceColor: str(
        'password_surface_color',
        str('surface_color', '#e8f7fb'),
      ),
      surfaceColor: surface,
      usernameX: numOf(tpl['username_x'], 0),
      usernameY: numOf(tpl['username_y'], 0),
      passwordX: numOf(tpl['password_x'], 0),
      passwordY: numOf(tpl['password_y'], 0),
      qrX: numOf(tpl['qr_x'], 0),
      qrY: numOf(tpl['qr_y'], 0),
      qrSizePct: numOf(fl['qr_size_pct'], 0),
    );
  }

  /// «عمودي/أفقي»: switch the engine and swap W/H so the longer side follows
  /// the orientation (web JS 442-459).
  QuickPrintForm withOrientation(bool toVertical) {
    final longSide = cardWidthMm > cardHeightMm ? cardWidthMm : cardHeightMm;
    final shortSide = cardWidthMm > cardHeightMm ? cardHeightMm : cardWidthMm;
    return copyWith(
      renderEngine: toVertical ? 'ar_vertical' : 'ar_horizontal',
      cardWidthMm: toVertical ? shortSide : longSide,
      cardHeightMm: toVertical ? longSide : shortSide,
    );
  }

  /// A new card image (web JS 496-516): image mode, stretched.
  QuickPrintForm withImage(String dataUrl, String name,
          {bool optimized = false,}) =>
      copyWith(
        backgroundDataUrl: dataUrl,
        backgroundName: name,
        backgroundOptimized: optimized,
        backgroundStyle: 'image',
        imageFit: 'stretch',
      );

  /// «لون الخلفية» sets all three surface colours together.
  QuickPrintForm withSurfaceColor(String hex) => copyWith(
        usernameSurfaceColor: hex,
        passwordSurfaceColor: hex,
        surfaceColor: hex,
      );

  /// The exact fields the web form posts. [passwordShown] false for a
  /// «بلا كلمة مرور» batch in the live preview (the web does the same).
  Map<String, String> toFields({bool passwordShown = true}) {
    String n(double v) => v == 0 ? '' : _fmt(v);
    String b(bool v) => v ? '1' : '0';
    return {
      'name': name,
      'font_size_unit': 'pt',
      'image_fit': imageFit,
      'background_style': backgroundStyle,
      'render_engine': renderEngine,
      'card_width_mm': _fmt(cardWidthMm),
      'card_height_mm': _fmt(cardHeightMm),
      'design_preset': designPreset,
      'hotspot_address': hotspotAddress,
      'background_image_data_url': backgroundDataUrl,
      'background_image_name': backgroundName,
      'show_username': '1',
      'show_password': passwordShown ? '1' : '0',
      'username_font_size': n(usernameFontSize),
      'password_font_size': n(passwordFontSize),
      'show_qr': b(showQr),
      'show_price': b(showPrice),
      'hotspot_login_url': hotspotLoginUrl.trim(),
      'credential_background_enabled': b(surfaceOn),
      'username_surface_enabled': b(surfaceOn),
      'password_surface_enabled': b(surfaceOn),
      'username_surface_color': usernameSurfaceColor,
      'password_surface_color': passwordSurfaceColor,
      'surface_color': surfaceColor,
      'username_x': _fmt(usernameX),
      'username_y': _fmt(usernameY),
      'password_x': _fmt(passwordX),
      'password_y': _fmt(passwordY),
      'qr_x': _fmt(qrX),
      'qr_y': _fmt(qrY),
      'qr_size_pct': _fmt(qrSizePct),
    };
  }

  QuickPrintForm copyWith({
    String? name,
    String? imageFit,
    String? backgroundStyle,
    String? renderEngine,
    double? cardWidthMm,
    double? cardHeightMm,
    String? designPreset,
    String? hotspotAddress,
    String? backgroundDataUrl,
    String? backgroundName,
    bool? backgroundOptimized,
    double? usernameFontSize,
    double? passwordFontSize,
    bool? showQr,
    bool? showPrice,
    String? hotspotLoginUrl,
    bool? surfaceOn,
    String? usernameSurfaceColor,
    String? passwordSurfaceColor,
    String? surfaceColor,
    double? usernameX,
    double? usernameY,
    double? passwordX,
    double? passwordY,
    double? qrX,
    double? qrY,
    double? qrSizePct,
  }) =>
      QuickPrintForm(
        name: name ?? this.name,
        imageFit: imageFit ?? this.imageFit,
        backgroundStyle: backgroundStyle ?? this.backgroundStyle,
        renderEngine: renderEngine ?? this.renderEngine,
        cardWidthMm: cardWidthMm ?? this.cardWidthMm,
        cardHeightMm: cardHeightMm ?? this.cardHeightMm,
        designPreset: designPreset ?? this.designPreset,
        hotspotAddress: hotspotAddress ?? this.hotspotAddress,
        backgroundDataUrl: backgroundDataUrl ?? this.backgroundDataUrl,
        backgroundName: backgroundName ?? this.backgroundName,
        backgroundOptimized: backgroundOptimized ?? this.backgroundOptimized,
        usernameFontSize: usernameFontSize ?? this.usernameFontSize,
        passwordFontSize: passwordFontSize ?? this.passwordFontSize,
        showQr: showQr ?? this.showQr,
        showPrice: showPrice ?? this.showPrice,
        hotspotLoginUrl: hotspotLoginUrl ?? this.hotspotLoginUrl,
        surfaceOn: surfaceOn ?? this.surfaceOn,
        usernameSurfaceColor: usernameSurfaceColor ?? this.usernameSurfaceColor,
        passwordSurfaceColor: passwordSurfaceColor ?? this.passwordSurfaceColor,
        surfaceColor: surfaceColor ?? this.surfaceColor,
        usernameX: usernameX ?? this.usernameX,
        usernameY: usernameY ?? this.usernameY,
        passwordX: passwordX ?? this.passwordX,
        passwordY: passwordY ?? this.passwordY,
        qrX: qrX ?? this.qrX,
        qrY: qrY ?? this.qrY,
        qrSizePct: qrSizePct ?? this.qrSizePct,
      );
}

/// «توزيع الورقة (A4)» — web defaults: 6×9, gap 2 mm, margin 4 mm, portrait,
/// cut lines on; page A4 and stretch fit are fixed on the quick screen.
class QuickSheet {
  const QuickSheet({
    this.columns = 6,
    this.rows = 9,
    this.gapMm = 2,
    this.marginMm = 4,
    this.landscape = false,
    this.cutLines = true,
  });

  final int columns;
  final int rows;
  final double gapMm;
  final double marginMm;
  final bool landscape;
  final bool cutLines;

  int get perPage => columns * rows;

  factory QuickSheet.fromLastSettings(Map<String, String> lps) {
    int i(String k, int d) => int.tryParse(lps[k] ?? '') ?? d;
    double f(String k, double d) => double.tryParse(lps[k] ?? '') ?? d;
    final cut = (lps['print_cut_lines'] ?? '1').toLowerCase();
    return QuickSheet(
      columns: i('print_columns', 6).clamp(1, 8),
      rows: i('print_rows', 9).clamp(1, 12),
      gapMm: f('print_column_gap_mm', 2),
      marginMm: f('print_margin_mm', 4),
      landscape: lps['print_orientation'] == 'landscape',
      cutLines: {'1', 'true', 'yes', 'on'}.contains(cut),
    );
  }

  Map<String, String> toSettings() => {
        'print_page_size': 'A4',
        'print_orientation': landscape ? 'landscape' : 'portrait',
        'print_columns': '$columns',
        'print_rows': '$rows',
        // One «المسافة بين البطاقات» value drives both gaps (web JS 433-439).
        'print_column_gap_mm': _fmt(gapMm),
        'print_row_gap_mm': _fmt(gapMm),
        'print_margin_mm': _fmt(marginMm),
        'print_fit_mode': 'stretch',
        'print_cut_lines': cutLines ? '1' : '0',
      };

  QuickSheet copyWith({
    int? columns,
    int? rows,
    double? gapMm,
    double? marginMm,
    bool? landscape,
    bool? cutLines,
  }) =>
      QuickSheet(
        columns: columns ?? this.columns,
        rows: rows ?? this.rows,
        gapMm: gapMm ?? this.gapMm,
        marginMm: marginMm ?? this.marginMm,
        landscape: landscape ?? this.landscape,
        cutLines: cutLines ?? this.cutLines,
      );
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
