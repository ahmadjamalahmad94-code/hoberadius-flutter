/// State container for the Windows export room (3-column page).
///
/// Holds the user's selections (template / batch / override fields)
/// so the three columns share state without prop-drilling. Pure
/// Riverpod, no UI imports.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/print_templates_repository.dart';
import '../../domain/card_render_model.dart';
import '../../domain/card_render_model_builder.dart';
import '../../domain/print_template_model.dart';

@immutable
class ExportRoomState {
  const ExportRoomState({
    this.selectedTemplateId,
    this.selectedBatchId,
    this.overrides = const {},
    this.defaultTemplateId,
    this.busy = false,
    this.error,
    this.lastPdfFileName,
  });

  final int? selectedTemplateId;
  final int? selectedBatchId;
  final Map<String, String> overrides;
  final int? defaultTemplateId;
  final bool busy;
  final String? error;
  final String? lastPdfFileName;

  ExportRoomState copyWith({
    int? selectedTemplateId,
    int? selectedBatchId,
    Map<String, String>? overrides,
    int? defaultTemplateId,
    bool? busy,
    String? error,
    String? lastPdfFileName,
    bool clearTemplate = false,
    bool clearBatch = false,
    bool clearError = false,
  }) {
    return ExportRoomState(
      selectedTemplateId: clearTemplate
          ? null
          : (selectedTemplateId ?? this.selectedTemplateId),
      selectedBatchId:
          clearBatch ? null : (selectedBatchId ?? this.selectedBatchId),
      overrides: overrides ?? this.overrides,
      defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      lastPdfFileName: lastPdfFileName ?? this.lastPdfFileName,
    );
  }
}

class ExportRoomController extends StateNotifier<ExportRoomState> {
  ExportRoomController(this._repo) : super(const ExportRoomState());

  final PrintTemplatesRepository _repo;

  void selectTemplate(int templateId) {
    state = state.copyWith(selectedTemplateId: templateId, clearError: true);
  }

  void selectBatch(int? batchId) {
    state = state.copyWith(
      selectedBatchId: batchId,
      clearBatch: batchId == null,
      clearError: true,
    );
  }

  void setOverride(String key, String value) {
    final next = Map<String, String>.from(state.overrides);
    if (value.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value.trim();
    }
    state = state.copyWith(overrides: next);
  }

  /// Pre-select the tenant's default template on first paint — same
  /// behaviour as the web export center.
  void rememberDefault(int? defaultId) {
    if (defaultId == null) return;
    final shouldSelect = state.selectedTemplateId == null;
    state = state.copyWith(
      defaultTemplateId: defaultId,
      selectedTemplateId: shouldSelect ? defaultId : state.selectedTemplateId,
    );
  }

  Future<int?> cleanupFixtures() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final count = await _repo.cleanupFixtures();
      state = state.copyWith(busy: false);
      return count;
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
      return null;
    }
  }

  Future<bool> setDefault(int templateId) async {
    final previous = state.defaultTemplateId;
    // Optimistic flip — rollback on failure.
    state = state.copyWith(defaultTemplateId: templateId, clearError: true);
    try {
      await _repo.setDefault(templateId);
      return true;
    } catch (e) {
      state = state.copyWith(defaultTemplateId: previous, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTemplate(int templateId) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _repo.delete(templateId);
      final clearSelected = state.selectedTemplateId == templateId;
      state = state.copyWith(
        busy: false,
        clearTemplate: clearSelected,
      );
      return true;
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
      return false;
    }
  }
}

/// Provider for the room's state. Scoped to the screen so a fresh
/// instance starts every time the user navigates back to the page.
final exportRoomControllerProvider =
    StateNotifierProvider.autoDispose<ExportRoomController, ExportRoomState>(
  (ref) => ExportRoomController(ref.watch(printTemplatesRepositoryProvider)),
);

/// Helper: build a render model for the currently-selected template,
/// honouring the room's override map.
CardRenderModel buildModelFor(
  CardPrintTemplate template,
  ExportRoomState state, {
  Map<String, dynamic>? sampleCard,
}) {
  return buildCardRenderModel(
    {
      'id': template.id,
      'username_x': template.usernameX,
      'username_y': template.usernameY,
      'password_x': template.passwordX,
      'password_y': template.passwordY,
      'qr_x': template.qrX,
      'qr_y': template.qrY,
      'layout_json': template.layout,
    },
    card: sampleCard,
    overrides: state.overrides,
  );
}
