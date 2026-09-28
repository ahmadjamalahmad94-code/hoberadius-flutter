import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/ota/ota_updater.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Owner request 2026-09-28: the update is a pop-up «يوجد تحديث جديد»
/// (تثبيت / لاحقًا); nothing downloads before «تثبيت»; after the download
/// the pop-up offers «إعادة التشغيل». An «app_update» push forces a check.
class _FakeUpdater implements ShorebirdUpdater {
  _FakeUpdater(this.status);
  UpdateStatus status;
  int updates = 0;
  int checks = 0;
  bool failUpdate = false;

  @override
  bool get isAvailable => true;

  @override
  Future<Patch?> readCurrentPatch() async => const Patch(number: 4);

  @override
  Future<Patch?> readNextPatch() async => null;

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async {
    checks++;
    return status;
  }

  @override
  Future<void> update({UpdateTrack? track}) async {
    updates++;
    if (failUpdate) {
      throw const UpdateException(
        message: 'offline',
        reason: UpdateFailureReason.downloadFailed,
      );
    }
    status = UpdateStatus.restartRequired;
  }
}

void main() {
  test('new patch → available, no download until install', () async {
    final u = _FakeUpdater(UpdateStatus.outdated);
    final c = OtaController(updater: u, enabled: true);
    await c.check();
    expect(c.state.phase, OtaPhase.available);
    expect(c.state.currentPatch, 4);
    expect(u.updates, 0);

    await c.install();
    expect(u.updates, 1);
    expect(c.state.phase, OtaPhase.readyToRestart);
    expect(c.state.snoozed, isFalse);
  });

  test('already downloaded patch → straight to restart prompt', () async {
    final c = OtaController(
      updater: _FakeUpdater(UpdateStatus.restartRequired),
      enabled: true,
    );
    await c.check();
    expect(c.state.phase, OtaPhase.readyToRestart);
  });

  test('later snoozes; a push (force) brings the prompt back', () async {
    final u = _FakeUpdater(UpdateStatus.outdated);
    final c = OtaController(updater: u, enabled: true);
    await c.check();
    c.later();
    expect(c.state.snoozed, isTrue);

    // Throttled resume check does nothing…
    await c.check();
    expect(u.checks, 1);
    // …an update push forces a fresh check and un-snoozes.
    await c.check(force: true);
    expect(u.checks, 2);
    expect(c.state.snoozed, isFalse);
    expect(c.state.phase, OtaPhase.available);
  });

  test('download failure → failed with retry, no crash', () async {
    final u = _FakeUpdater(UpdateStatus.outdated)..failUpdate = true;
    final c = OtaController(updater: u, enabled: true);
    await c.check();
    await c.install();
    expect(c.state.phase, OtaPhase.failed);
    expect(c.state.error, 'offline');
  });

  test('disabled (web / plain build) is a no-op', () async {
    final u = _FakeUpdater(UpdateStatus.outdated);
    final c = OtaController(updater: u, enabled: false);
    await c.check(force: true);
    await c.install();
    expect(u.checks, 0);
    expect(u.updates, 0);
    expect(c.state.phase, OtaPhase.idle);
  });

  test('update push is recognised by data.type', () {
    expect(isAppUpdatePush({'type': 'app_update'}), isTrue);
    expect(isAppUpdatePush({'type': 'notification'}), isFalse);
    expect(isAppUpdatePush(const {}), isFalse);
    expect(kAppUpdatesTopic, 'app-updates');
  });
}
