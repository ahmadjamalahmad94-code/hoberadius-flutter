import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/api/api_exception.dart';
import '../../../admin_control/application/admin_control_providers.dart';
import '../data/quick_print_repository.dart';
import '../domain/quick_print_form.dart';
import 'package:hoberadius_app/core/format/currency.dart';

enum PreviewMode { card, page }

class QuickPrintState {
  const QuickPrintState({
    this.loading = true,
    this.error = '',
    this.templates = const [],
    this.templateId = 0,
    this.form = const QuickPrintForm(),
    this.sheet = const QuickSheet(),
    this.batchCode = '',
    this.batchCards = 0,
    this.noPassword = false,
    this.mode = PreviewMode.card,
    this.previewPng,
    this.previewBusy = false,
    this.previewError = '',
    this.saving = false,
    this.dirty = false,
    this.elements,
    this.elementWarnings = const [],
  });

  final bool loading;
  final String error;
  final List<Map<String, dynamic>> templates;

  /// 0 = «تصميم جديد» (not saved yet).
  final int templateId;
  final QuickPrintForm form;
  final QuickSheet sheet;
  final String batchCode;
  final int batchCards;
  final bool noPassword;
  final PreviewMode mode;

  /// The server's PDF rasterized by the platform's PDF renderer.
  final Uint8List? previewPng;
  final bool previewBusy;
  final String previewError;
  final bool saving;

  /// Unsaved design changes (the sheet is remembered on print, not a design).
  final bool dirty;

  /// Real element places (mm) for the current design — sliders + drag.
  final CardElements? elements;

  /// What the renderer changed on its own (Arabic, from the server): e.g.
  /// the QR was moved so it does not cover the username / password.
  final List<String> elementWarnings;

  QuickPrintState copyWith({
    bool? loading,
    String? error,
    List<Map<String, dynamic>>? templates,
    int? templateId,
    QuickPrintForm? form,
    QuickSheet? sheet,
    String? batchCode,
    int? batchCards,
    bool? noPassword,
    PreviewMode? mode,
    Uint8List? previewPng,
    bool? previewBusy,
    String? previewError,
    bool? saving,
    bool? dirty,
    CardElements? elements,
    List<String>? elementWarnings,
  }) =>
      QuickPrintState(
        loading: loading ?? this.loading,
        error: error ?? this.error,
        templates: templates ?? this.templates,
        templateId: templateId ?? this.templateId,
        form: form ?? this.form,
        sheet: sheet ?? this.sheet,
        batchCode: batchCode ?? this.batchCode,
        batchCards: batchCards ?? this.batchCards,
        noPassword: noPassword ?? this.noPassword,
        mode: mode ?? this.mode,
        previewPng: previewPng ?? this.previewPng,
        previewBusy: previewBusy ?? this.previewBusy,
        previewError: previewError ?? this.previewError,
        saving: saving ?? this.saving,
        dirty: dirty ?? this.dirty,
        elements: elements ?? this.elements,
        elementWarnings: elementWarnings ?? this.elementWarnings,
      );
}

class QuickPrintController extends StateNotifier<QuickPrintState> {
  QuickPrintController(
    this._repo,
    this.batchId, {
    String Function()? tenantCurrency,
  })  : _tenantCurrency = tenantCurrency,
        super(const QuickPrintState()) {
    _load();
  }

  final QuickPrintRepository _repo;
  final int batchId;

  /// The panel currency, for batches whose payload has no `currency` (old
  /// servers): «5» alone was printed on the card (R06 N5).
  final String Function()? _tenantCurrency;
  Map<String, dynamic> _batch = const {};

  /// The batch's card price («5 ₪»), offered as the price text.
  String get batchPriceText {
    var fallback = '';
    try {
      fallback = _tenantCurrency?.call() ?? '';
    } catch (_) {}
    return batchPriceLabel(_batch, fallbackCurrency: fallback);
  }

  /// `preview.pdf` already carries the element places (`X-Print-Elements`):
  /// no separate `quick-elements` request once that is known.
  bool _headerElements = false;
  Timer? _debounce;
  CancelToken? _inflight;
  int _seq = 0;

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.templates(),
        _repo
            .lastSettings()
            .catchError((_) => const LastPrintSettings(<String, String>{})),
        _repo.batch(batchId),
      ]);
      final templates = results[0] as List<Map<String, dynamic>>;
      final last = results[1] as LastPrintSettings;
      final lps = last.settings;
      final batch = results[2] as Map<String, dynamic>;
      // Updated servers: THIS admin's last template, else the tenant
      // default. Older: the default flag in the list, else the newest.
      Map<String, dynamic>? tpl;
      for (final want in [last.lastTemplateId, last.defaultTemplateId]) {
        if (tpl != null || want <= 0) continue;
        for (final t in templates) {
          if (_id(t) == want) tpl = t;
        }
      }
      if (tpl == null) {
        for (final t in templates) {
          final l = t['layout_json'];
          if (l is Map && l['is_default'] == true) tpl = t;
        }
      }
      tpl ??= templates.isEmpty ? null : templates.first;
      tpl = await _repo.fullTemplate(tpl);
      var form = QuickPrintForm.fromTemplate(
        tpl,
        fallbackLoginUrl: _anyLoginUrl(templates),
      );
      if (tpl == null) {
        form = form.copyWith(name: uniqueTemplateName(templates));
      }
      state = state.copyWith(
        loading: false,
        templates: templates,
        templateId: _id(tpl),
        form: form,
        sheet: QuickSheet.fromLastSettings(lps),
        batchCode: '${batch['batch_code'] ?? batch['package_name'] ?? batchId}',
        batchCards: _int(batch['total_cards'] ?? batch['generated']),
        noPassword: batch['login_without_password'] == true ||
            batch['login_without_password'] == 1,
      );
      _batch = batch;
      refreshPreview(immediate: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: _message(e));
    }
  }

  Future<void> selectTemplate(int id) async {
    Map<String, dynamic>? tpl;
    for (final t in state.templates) {
      if (_id(t) == id) tpl = t;
    }
    // Light template list (updated servers): fetch the full row so the
    // stored background image/design come with it.
    tpl = await _repo.fullTemplate(tpl);
    if (!mounted) return;
    var form = QuickPrintForm.fromTemplate(
      tpl,
      fallbackLoginUrl: _anyLoginUrl(state.templates),
    );
    // «تصميم جديد»: a name no saved template has («قالب سريع 2»…) — the
    // default «قالب سريع» usually exists already and the save/print failed
    // with «يوجد قالب طباعة بهذا الاسم» (R11 M-4).
    if (tpl == null) {
      form = form.copyWith(name: uniqueTemplateName(state.templates));
    }
    state = state.copyWith(
      templateId: tpl == null ? 0 : id,
      form: form,
      dirty: false,
      elementWarnings: const [],
    );
    refreshPreview(immediate: true);
  }

  void updateForm(QuickPrintForm Function(QuickPrintForm f) edit) {
    state = state.copyWith(form: edit(state.form), dirty: true);
    refreshPreview();
  }

  /// «إظهار السعر»: switching it on with no price text fills the batch's
  /// card price, so something is actually printed.
  void setShowPrice(bool on) {
    updateForm((f) {
      var next = f.copyWith(showPrice: on);
      if (on && next.priceText.isEmpty && batchPriceText.isNotEmpty) {
        next = next.withPriceText(batchPriceText);
      }
      return next;
    });
  }

  void setPriceText(String text) => updateForm((f) => f.withPriceText(text));

  /// Page-layout controls only change the «الصفحة» preview: switch to it so
  /// the change is visible (they looked like they did nothing on «الكرت»).
  void updateSheet(QuickSheet Function(QuickSheet s) edit) {
    state = state.copyWith(sheet: edit(state.sheet));
    if (state.mode == PreviewMode.page) {
      refreshPreview();
    } else {
      state = state.copyWith(mode: PreviewMode.page);
      refreshPreview(immediate: true);
    }
  }

  void setMode(PreviewMode mode) {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    refreshPreview(immediate: true);
  }

  /// Place an element at (x, y) mm — from a slider or a drag. Both
  /// coordinates become explicit (the web drag writes both too).
  void moveElement(String name, double x, double y) {
    // Kept inside the card (elements could be dragged off it — A13 L5).
    final f0 = state.form;
    final maxX = (f0.cardWidthMm - 1).clamp(1.0, 200.0);
    final maxY = (f0.cardHeightMm - 1).clamp(1.0, 200.0);
    double r(double v, double max) =>
        double.parse(v.clamp(0.5, max).toStringAsFixed(1));
    updateForm(
      (f) => switch (name) {
        'username' => f.copyWith(usernameX: r(x, maxX), usernameY: r(y, maxY)),
        'password' => f.copyWith(passwordX: r(x, maxX), passwordY: r(y, maxY)),
        _ => f.copyWith(qrX: r(x, maxX), qrY: r(y, maxY)),
      },
    );
  }

  /// Back to the automatic place.
  void resetElement(String name) {
    updateForm(
      (f) => switch (name) {
        'username' => f.copyWith(usernameX: 0, usernameY: 0),
        'password' => f.copyWith(passwordX: 0, passwordY: 0),
        _ => f.copyWith(qrX: 0, qrY: 0),
      },
    );
  }

  /// A picked image goes once through the web's optimizer; the optimized
  /// bitmap is what the previews and the save carry from then on.
  Future<String?> setImage(Uint8List bytes, String name, String mime) async {
    if (bytes.length > 8 * 1024 * 1024) {
      return 'الصورة أكبر من 8MB — اختر صورة أصغر.';
    }
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    try {
      final bg = await _repo.optimizeBackground(dataUrl, name);
      final url = '${bg['background_image_data_url'] ?? ''}';
      if (!url.startsWith('data:image/')) return 'تعذّر تجهيز الصورة.';
      updateForm((f) => f.withImage(url, name, optimized: true));
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  void refreshPreview({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      _renderPreview();
    } else {
      _debounce = Timer(const Duration(milliseconds: 450), _renderPreview);
    }
  }

  Future<void> _renderPreview() async {
    final seq = ++_seq;
    _inflight?.cancel();
    final cancel = _inflight = CancelToken();
    state = state.copyWith(previewBusy: true, previewError: '');
    try {
      final card = state.mode == PreviewMode.card;
      final formAtStart = state.form;
      final fields = formAtStart.toFields(passwordShown: !state.noPassword);
      final elementsFuture = _headerElements
          ? Future<CardElements?>.value()
          : _repo
              .elements(
                form: fields,
                templateId: state.templateId,
                batchId: batchId,
                cancel: cancel,
              )
              .then<CardElements?>((e) => e)
              .catchError((_) => null);
      final preview = await _repo.preview(
        form: fields,
        templateId: state.templateId,
        batchId: batchId,
        printSettings: state.sheet.toSettings(),
        mode: card ? 'card' : 'page',
        cancel: cancel,
      );
      // The platform's PDF engine rasterizes the server's PDF (Android:
      // PdfRenderer) — no Flutter redraw, so the preview is the print.
      if (preview.elements != null) _headerElements = true;
      final raster = await Printing.raster(
        preview.pdf,
        pages: const [0],
        dpi: card ? 300 : 120,
      ).first;
      final png = await raster.toPng();
      final elements = preview.elements ?? await elementsFuture;
      if (seq != _seq || !mounted) return;
      state = state.copyWith(previewPng: png, previewBusy: false);
      if (elements != null) applyElements(elements, formAtStart);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || seq != _seq || !mounted) return;
      state = state.copyWith(previewBusy: false, previewError: _message(e));
    } catch (e) {
      if (seq != _seq || !mounted) return;
      state = state.copyWith(previewBusy: false, previewError: _message(e));
    }
  }

  /// The server's real element places for [renderedForm]. An element the
  /// renderer moved (`adjusted`: kept inside the card, off the credentials…)
  /// moves the slider and the drag handle to where it is REALLY drawn — the
  /// slider used to keep the dropped 16.1 mm while the card used 29.96 mm
  /// (R06 N7). Only when the design did not change meanwhile (a stale answer
  /// must not undo a newer move); no new preview (it already shows this).
  void applyElements(CardElements els, QuickPrintForm renderedForm) {
    var form = state.form;
    if (identical(form, renderedForm)) {
      double r(double v) => double.parse(v.toStringAsFixed(1));
      bool moved(ElementBox b) =>
          b.adjusted && b.requestedX != null && b.requestedY != null;
      final u = els.boxes['username'];
      if (u != null && moved(u) && (form.usernameX > 0 || form.usernameY > 0)) {
        form = form.copyWith(usernameX: r(u.x), usernameY: r(u.y));
      }
      final p = els.boxes['password'];
      if (p != null && moved(p) && (form.passwordX > 0 || form.passwordY > 0)) {
        form = form.copyWith(passwordX: r(p.x), passwordY: r(p.y));
      }
      final q = els.boxes['qr'];
      if (q != null && form.showQr && q.adjusted) {
        if (moved(q) && (form.qrX > 0 || form.qrY > 0)) {
          form = form.copyWith(qrX: r(q.x), qrY: r(q.y));
        }
        final pct = q.sizePct;
        if (pct != null &&
            form.qrSizePct > 0 &&
            (pct - form.qrSizePct).abs() > 0.5) {
          form = form.copyWith(qrSizePct: r(pct));
        }
      }
    }
    state = state.copyWith(
      elements: els,
      form: form,
      elementWarnings: els.warnings,
    );
  }

  /// Save (create or update) through the web's builder. Returns the id.
  ///
  /// [name]: save under this name (the «اسم آخر» answer to a name clash).
  /// [targetTemplateId]: write into that template (the «استبدال» answer).
  /// Throws [TemplateNameRequired] for an empty name and
  /// [TemplateNameTaken] when another template has the name (updated
  /// servers: 409 `duplicate_name`; older: 422 with the Arabic message).
  Future<int> save({String? name, int? targetTemplateId}) async {
    if (name != null) {
      state = state.copyWith(form: state.form.copyWith(name: name.trim()));
    }
    final form = state.form;
    final nameError = templateNameError(form.name);
    if (nameError != null) throw TemplateNameRequired(nameError);
    state = state.copyWith(saving: true);
    try {
      final saved = await _repo.quickSave(
        form: form.toFields(),
        templateId: targetTemplateId ?? state.templateId,
        printSettings: state.sheet.toSettings(),
      );
      final id = _id(saved.template);
      final templates = await _repo.templates();
      state = state.copyWith(
        saving: false,
        templateId: id,
        templates: templates,
        dirty: false,
      );
      final els = saved.elements;
      if (els != null && els.boxes.isNotEmpty) applyElements(els, form);
      return id;
    } catch (e) {
      state = state.copyWith(saving: false);
      if (isTemplateNameClash(e)) {
        throw await _nameTaken(e, form.name.trim());
      }
      rethrow;
    }
  }

  Future<TemplateNameTaken> _nameTaken(Object e, String name) async {
    var templates = state.templates;
    try {
      templates = await _repo.templates();
      if (mounted) state = state.copyWith(templates: templates);
    } catch (_) {}
    var existing = 0;
    for (final t in templates) {
      if (_sameName('${t['name'] ?? ''}', name)) existing = _id(t);
    }
    return TemplateNameTaken(
      message: e is ApiException && e.message.trim().isNotEmpty
          ? e.message
          : 'يوجد قالب طباعة بهذا الاسم — اختر اسمًا آخر.',
      name: name,
      existingId: existing == state.templateId ? 0 : existing,
      suggestion: uniqueTemplateName(templates, base: name),
    );
  }

  /// Web export overrides: the hotspot address + login URL for the QR.
  Map<String, String> get exportOverrides => {
        if (state.form.hotspotAddress.isNotEmpty)
          'hotspot_address': state.form.hotspotAddress,
        if (state.form.hotspotLoginUrl.trim().isNotEmpty)
          'hotspot_login_url': state.form.hotspotLoginUrl.trim(),
      };

  @override
  void dispose() {
    _debounce?.cancel();
    _inflight?.cancel();
    super.dispose();
  }

  static int _id(Map<String, dynamic>? t) => _int(t?['id']);
  static int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static String _anyLoginUrl(List<Map<String, dynamic>> templates) {
    for (final t in templates) {
      final l = t['layout_json'];
      if (l is Map) {
        final u = '${l['hotspot_login_url'] ?? ''}'.trim();
        if (u.isNotEmpty) return u;
      }
    }
    return '';
  }

  static String _message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final m = '${(data['error'] as Map)['message'] ?? ''}';
        if (m.isNotEmpty) return m;
      }
      if (e.response?.statusCode == 404) {
        return 'هذا الخادم لم يُحدَّث بعد لطباعة الكروت من التطبيق.';
      }
      return 'تعذّر الاتصال بالخادم.';
    }
    if (e is ApiException) {
      // An older server without the app print endpoints answers 404.
      if (e.status == 404 && e.code != 'not_found') {
        return 'هذا الخادم لم يُحدَّث بعد لطباعة الكروت من التطبيق.';
      }
      return e.message;
    }
    final s = '$e';
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}

final quickPrintControllerProvider = StateNotifierProvider.autoDispose
    .family<QuickPrintController, QuickPrintState, int>(
  (ref, batchId) => QuickPrintController(
    ref.watch(quickPrintRepositoryProvider),
    batchId,
    tenantCurrency: () => ref.read(tenantCurrencyProvider),
  ),
);

/// The server's cap on a template name (a 10,004-character name broke the
/// web quick screen — R06 N4).
const kTemplateNameMax = 120;

/// The name field's error (the server's own wording), null when valid.
String? templateNameError(String name) {
  final v = name.trim();
  if (v.isEmpty) return 'اسم القالب مطلوب';
  if (v.length > kTemplateNameMax) {
    return 'اسم القالب طويل جدًّا — $kTemplateNameMax حرفًا على الأكثر.';
  }
  return null;
}

/// An empty or too long name — nothing is sent (the field shows the text).
class TemplateNameRequired implements Exception {
  const TemplateNameRequired([this.message = 'اسم القالب مطلوب']);
  final String message;
  @override
  String toString() => message;
}

/// Another print template already has [name]. [existingId] > 0: it is in the
/// list and can be overwritten; [suggestion]: a free name to offer instead.
class TemplateNameTaken implements Exception {
  const TemplateNameTaken({
    required this.message,
    required this.name,
    required this.existingId,
    required this.suggestion,
  });
  final String message;
  final String name;
  final int existingId;
  final String suggestion;
  @override
  String toString() => message;
}

/// The server refused a template name that is taken: 409 `duplicate_name`
/// (updated servers) or 422 «يوجد قالب طباعة بهذا الاسم» (older servers).
bool isTemplateNameClash(Object e) {
  if (e is! ApiException) return false;
  final clashText = e.message.contains('يوجد قالب طباعة بهذا الاسم');
  if (e.status == 409) return e.code == 'duplicate_name' || clashText;
  return e.status == 422 && clashText;
}

bool _sameName(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

/// [base] when no template has it, else «base 2», «base 3»… (a trailing
/// number of [base] is continued: «قالب سريع 2» → «قالب سريع 3»).
String uniqueTemplateName(
  List<Map<String, dynamic>> templates, {
  String base = 'قالب سريع',
}) {
  final names = {
    for (final t in templates) '${t['name'] ?? ''}'.trim().toLowerCase(),
  };
  var stem = base.trim().isEmpty ? 'قالب سريع' : base.trim();
  if (!names.contains(stem.toLowerCase())) return stem;
  var n = 2;
  final m = RegExp(r'^(.*\S)\s+(\d+)$').firstMatch(stem);
  if (m != null) {
    stem = m.group(1)!;
    n = (int.tryParse(m.group(2)!) ?? 1) + 1;
  }
  while (names.contains('$stem $n'.toLowerCase())) {
    n++;
  }
  return '$stem $n';
}

/// «5 ₪» from a batch row (`price_per_card` + `currency`), '' when free.
/// Old servers send no `currency` → [fallbackCurrency] (the panel's).
String batchPriceLabel(
  Map<String, dynamic> batch, {
  String fallbackCurrency = '',
}) {
  final raw = batch['price_per_card'] ?? batch['card_price'] ?? batch['price'];
  final n = raw is num ? raw : num.tryParse('${raw ?? ''}');
  if (n == null || n <= 0) return '';
  final v = n.toDouble();
  final text =
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  var cur = '${batch['currency'] ?? ''}'.trim();
  if (cur.isEmpty) cur = fallbackCurrency.trim();
  // Printed by the server (not Flutter): no bidi isolate marks.
  return amountWithCurrencyCode(text, cur, isolate: false);
}
