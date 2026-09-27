import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Over-the-air (Shorebird) update state for the shell banner.
///
/// Shorebird itself downloads patches in the background on launch and boots
/// from them on the *next* launch. This layer only makes that visible: it
/// asks once per session whether a newer patch exists, downloads it if so,
/// and tells the UI «تحديث جاهز — أعد فتح التطبيق». In a plain `flutter build`
/// (web, tests, a non-Shorebird APK) the updater reports `isAvailable == false`
/// and everything here is a no-op.
enum OtaPhase { idle, checking, downloading, restartRequired, upToDate, failed }

class OtaState {
  const OtaState({
    this.phase = OtaPhase.idle,
    this.currentPatch,
    this.error = '',
  });
  final OtaPhase phase;
  final int? currentPatch;
  final String error;

  OtaState copyWith({OtaPhase? phase, int? currentPatch, String? error}) =>
      OtaState(
        phase: phase ?? this.phase,
        currentPatch: currentPatch ?? this.currentPatch,
        error: error ?? this.error,
      );
}

class OtaController extends StateNotifier<OtaState> {
  OtaController({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater(),
        super(const OtaState());

  final ShorebirdUpdater _updater;
  bool _ran = false;

  bool get isAvailable => _updater.isAvailable;

  /// Check once per app session. Safe to call from a post-frame callback.
  Future<void> checkOnce() async {
    if (_ran || kIsWeb || !_updater.isAvailable) return;
    _ran = true;
    try {
      final current = await _updater.readCurrentPatch();
      state = state.copyWith(
        phase: OtaPhase.checking,
        currentPatch: current?.number,
      );
      final status = await _updater.checkForUpdate();
      switch (status) {
        case UpdateStatus.outdated:
          state = state.copyWith(phase: OtaPhase.downloading);
          await _updater.update();
          state = state.copyWith(phase: OtaPhase.restartRequired);
        case UpdateStatus.restartRequired:
          state = state.copyWith(phase: OtaPhase.restartRequired);
        case UpdateStatus.upToDate:
        case UpdateStatus.unavailable:
          state = state.copyWith(phase: OtaPhase.upToDate);
      }
    } on UpdateException catch (e) {
      state = state.copyWith(phase: OtaPhase.failed, error: e.message);
    } catch (e) {
      state = state.copyWith(phase: OtaPhase.failed, error: e.toString());
    }
  }

  void dismiss() => state = state.copyWith(phase: OtaPhase.idle);
}

final otaControllerProvider =
    StateNotifierProvider<OtaController, OtaState>((ref) => OtaController());
