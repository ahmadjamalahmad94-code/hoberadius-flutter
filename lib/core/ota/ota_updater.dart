import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'release_notes.dart';

/// Over-the-air (Shorebird) update flow, surfaced as pop-up dialogs
/// (see `ota_dialogs.dart`):
///
///   check → [available] «يوجد تحديث جديد» تثبيت / لاحقًا
///         → تثبيت → [downloading] progress dialog
///         → [readyToRestart] «إعادة التشغيل» → the app restarts on the patch.
///
/// Nothing downloads without the operator's «تثبيت». A patch that was already
/// downloaded earlier (e.g. by Shorebird itself) goes straight to
/// [OtaPhase.readyToRestart]. Checks run on launch, on resume (throttled) and
/// when an «app_update» push arrives. In a plain `flutter build` (web, tests,
/// a non-Shorebird APK) the updater is unavailable and all of this is a no-op.
/// FCM topic every install subscribes to; `.github/workflows/shorebird.yml`
/// pushes to it after publishing a patch.
const kAppUpdatesTopic = 'app-updates';

/// An update announcement carries `data.type == 'app_update'`.
bool isAppUpdatePush(Map<String, dynamic> data) =>
    (data['type'] ?? '').toString() == 'app_update';

enum OtaPhase {
  idle,
  checking,
  available,
  downloading,
  readyToRestart,
  upToDate,
  failed,
}

class OtaState {
  const OtaState({
    this.phase = OtaPhase.idle,
    this.currentPatch,
    this.error = '',
    this.snoozed = false,
    this.notes = const [],
    this.whatsNew = const [],
  });
  final OtaPhase phase;
  final int? currentPatch;
  final String error;

  /// «لاحقًا» pressed: don't pop the dialog again this session unless a push
  /// or an explicit check asks for it.
  final bool snoozed;

  /// «الجديد في هذا التحديث» — items of the patches waiting to install.
  final List<String> notes;

  /// Shown once after an update was applied (items of the patch now running).
  final List<String> whatsNew;

  OtaState copyWith({
    OtaPhase? phase,
    int? currentPatch,
    String? error,
    bool? snoozed,
    List<String>? notes,
    List<String>? whatsNew,
  }) =>
      OtaState(
        phase: phase ?? this.phase,
        currentPatch: currentPatch ?? this.currentPatch,
        error: error ?? this.error,
        snoozed: snoozed ?? this.snoozed,
        notes: notes ?? this.notes,
        whatsNew: whatsNew ?? this.whatsNew,
      );
}

class OtaController extends StateNotifier<OtaState> {
  OtaController({
    ShorebirdUpdater? updater,
    bool? enabled,
    Future<List<ReleaseNote>> Function()? notesLoader,
    Future<int?> Function()? readLastSeenPatch,
    Future<void> Function(int patch)? writeLastSeenPatch,
  })  : _updater = updater ?? ShorebirdUpdater(),
        _enabled = enabled ?? !kIsWeb,
        _loadNotes = notesLoader ?? fetchReleaseNotes,
        _readSeen = readLastSeenPatch ?? _prefsReadSeen,
        _writeSeen = writeLastSeenPatch ?? _prefsWriteSeen,
        super(const OtaState());

  final Future<List<ReleaseNote>> Function() _loadNotes;
  final Future<int?> Function() _readSeen;
  final Future<void> Function(int patch) _writeSeen;
  bool _whatsNewChecked = false;

  static const _seenKey = 'ota.last_seen_patch.$kAppRelease';

  static Future<int?> _prefsReadSeen() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_seenKey);
  }

  static Future<void> _prefsWriteSeen(int patch) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_seenKey, patch);
  }

  Future<List<ReleaseNote>> _safeNotes() async {
    try {
      return await _loadNotes();
    } catch (_) {
      return const [];
    }
  }

  /// After an update was applied: the notes of the patch(es) now running,
  /// once (from the last patch this device saw).
  Future<void> _checkWhatsNew(int? current) async {
    if (_whatsNewChecked || current == null || current <= 0) return;
    _whatsNewChecked = true;
    final seen = await _readSeen();
    await _writeSeen(current);
    if (seen != null && seen >= current) return;
    // No record yet (first run with this feature, or first patch after an
    // install): show just the patch now running.
    final items = noteItems(
      notesBetween(
        await _safeNotes(),
        after: seen ?? current - 1,
        upTo: current,
      ),
    );
    if (items.isNotEmpty) state = state.copyWith(whatsNew: items);
  }

  /// «تم» on the what's-new dialog.
  void dismissWhatsNew() => state = state.copyWith(whatsNew: const []);

  final ShorebirdUpdater _updater;
  final bool _enabled;
  DateTime? _lastCheck;
  bool _busy = false;

  bool get isAvailable => _enabled && _updater.isAvailable;

  /// Look for a new patch. [force] ignores the resume throttle and a previous
  /// «لاحقًا» (used when an update push arrives).
  Future<void> check({bool force = false}) async {
    if (!isAvailable || _busy) return;
    final phase = state.phase;
    if (phase == OtaPhase.downloading) return;
    if (phase == OtaPhase.readyToRestart) {
      // Already downloaded: just re-show the restart prompt when forced.
      if (force) state = state.copyWith(snoozed: false);
      return;
    }
    final now = DateTime.now();
    if (!force &&
        _lastCheck != null &&
        now.difference(_lastCheck!) < const Duration(minutes: 10)) {
      return;
    }
    _lastCheck = now;
    _busy = true;
    try {
      final current = await _updater.readCurrentPatch();
      state = state.copyWith(
        phase: OtaPhase.checking,
        currentPatch: current?.number,
        snoozed: force ? false : state.snoozed,
      );
      final status = await _updater.checkForUpdate();
      await _checkWhatsNew(current?.number);
      final pending = status == UpdateStatus.outdated ||
              status == UpdateStatus.restartRequired
          ? noteItems(
              notesBetween(
                await _safeNotes(),
                after: current?.number ?? 0,
              ),
            )
          : const <String>[];
      state = switch (status) {
        UpdateStatus.outdated =>
          state.copyWith(phase: OtaPhase.available, notes: pending),
        UpdateStatus.restartRequired =>
          state.copyWith(phase: OtaPhase.readyToRestart, notes: pending),
        UpdateStatus.upToDate ||
        UpdateStatus.unavailable =>
          state.copyWith(phase: OtaPhase.upToDate),
      };
    } catch (e) {
      // A failed background check stays silent (no dialog for «no network»).
      state = state.copyWith(phase: OtaPhase.idle, error: _message(e));
    } finally {
      _busy = false;
    }
  }

  /// «تثبيت»: download the patch; the dialog shows progress, then restart.
  Future<void> install() async {
    if (!isAvailable || _busy) return;
    _busy = true;
    state = state.copyWith(phase: OtaPhase.downloading, error: '');
    try {
      await _updater.update();
      state = state.copyWith(phase: OtaPhase.readyToRestart, snoozed: false);
    } catch (e) {
      state = state.copyWith(phase: OtaPhase.failed, error: _message(e));
    } finally {
      _busy = false;
    }
  }

  /// Open the update pop-up again (from the dashboard / notifications bar
  /// after «لاحقًا»).
  void reopen() {
    // Two emissions so the host's listener fires even if not snoozed.
    state = state.copyWith(snoozed: true);
    state = state.copyWith(snoozed: false);
  }

  /// «لاحقًا» / close: hide the dialog; the patch (if downloaded) still
  /// applies on the next cold start.
  void later() => state = state.copyWith(snoozed: true);

  String _message(Object e) => e is UpdateException ? e.message : '$e';
}

final otaControllerProvider =
    StateNotifierProvider<OtaController, OtaState>((ref) => OtaController());
