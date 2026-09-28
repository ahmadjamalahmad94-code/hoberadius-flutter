import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/api/api_exception.dart';
import '../data/quick_print_repository.dart';
import '../domain/quick_print_form.dart';

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
      );
}

class QuickPrintController extends StateNotifier<QuickPrintState> {
  QuickPrintController(this._repo, this.batchId)
      : super(const QuickPrintState()) {
    _load();
  }

  final QuickPrintRepository _repo;
  final int batchId;
  Timer? _debounce;
  CancelToken? _inflight;
  int _seq = 0;

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.templates(),
        _repo.lastSettings().catchError((_) => <String, String>{}),
        _repo.batch(batchId),
      ]);
      final templates = results[0] as List<Map<String, dynamic>>;
      final lps = results[1] as Map<String, String>;
      final batch = results[2] as Map<String, dynamic>;
      // Web: no argument → the default template, else the newest.
      Map<String, dynamic>? tpl;
      for (final t in templates) {
        final l = t['layout_json'];
        if (l is Map && l['is_default'] == true) tpl = t;
      }
      tpl ??= templates.isEmpty ? null : templates.first;
      tpl = await _repo.fullTemplate(tpl);
      state = state.copyWith(
        loading: false,
        templates: templates,
        templateId: _id(tpl),
        form: QuickPrintForm.fromTemplate(
          tpl,
          fallbackLoginUrl: _anyLoginUrl(templates),
        ),
        sheet: QuickSheet.fromLastSettings(lps),
        batchCode: '${batch['batch_code'] ?? batch['package_name'] ?? batchId}',
        batchCards: _int(batch['total_cards'] ?? batch['generated']),
        noPassword: batch['login_without_password'] == true ||
            batch['login_without_password'] == 1,
      );
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
    state = state.copyWith(
      templateId: tpl == null ? 0 : id,
      form: QuickPrintForm.fromTemplate(
        tpl,
        fallbackLoginUrl: _anyLoginUrl(state.templates),
      ),
      dirty: false,
    );
    refreshPreview(immediate: true);
  }

  void updateForm(QuickPrintForm Function(QuickPrintForm f) edit) {
    state = state.copyWith(form: edit(state.form), dirty: true);
    refreshPreview();
  }

  void updateSheet(QuickSheet Function(QuickSheet s) edit) {
    state = state.copyWith(sheet: edit(state.sheet));
    if (state.mode == PreviewMode.page) refreshPreview();
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
      final fields = state.form.toFields(passwordShown: !state.noPassword);
      final elementsFuture = _repo
          .elements(
            form: fields,
            templateId: state.templateId,
            batchId: batchId,
            cancel: cancel,
          )
          .then<CardElements?>((e) => e)
          .catchError((_) => null);
      final pdf = await _repo.preview(
        form: fields,
        templateId: state.templateId,
        batchId: batchId,
        printSettings: state.sheet.toSettings(),
        mode: card ? 'card' : 'page',
        cancel: cancel,
      );
      // The platform's PDF engine rasterizes the server's PDF (Android:
      // PdfRenderer) — no Flutter redraw, so the preview is the print.
      final raster = await Printing.raster(
        pdf,
        pages: const [0],
        dpi: card ? 300 : 120,
      ).first;
      final png = await raster.toPng();
      final elements = await elementsFuture;
      if (seq != _seq || !mounted) return;
      state = state.copyWith(
        previewPng: png,
        previewBusy: false,
        elements: elements,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || seq != _seq || !mounted) return;
      state = state.copyWith(previewBusy: false, previewError: _message(e));
    } catch (e) {
      if (seq != _seq || !mounted) return;
      state = state.copyWith(previewBusy: false, previewError: _message(e));
    }
  }

  /// Save (create or update) through the web's builder. Returns the id.
  Future<int> save() async {
    state = state.copyWith(saving: true);
    try {
      final saved = await _repo.quickSave(
        form: state.form.toFields(),
        templateId: state.templateId,
        printSettings: state.sheet.toSettings(),
      );
      final id = _id(saved);
      final templates = await _repo.templates();
      state = state.copyWith(
        saving: false,
        templateId: id,
        templates: templates,
        dirty: false,
      );
      return id;
    } catch (e) {
      state = state.copyWith(saving: false);
      rethrow;
    }
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
  (ref, batchId) =>
      QuickPrintController(ref.watch(quickPrintRepositoryProvider), batchId),
);
