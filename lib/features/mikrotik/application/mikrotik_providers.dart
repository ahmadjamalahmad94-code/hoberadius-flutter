import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nas/data/nas_repository.dart';
import '../../nas/domain/nas_model.dart';
import '../data/mikrotik_repository.dart';
import '../domain/mikrotik_model.dart';

final mikrotikConfigsProvider =
    FutureProvider.autoDispose<List<MikrotikConfig>>((ref) {
  return ref.watch(mikrotikRepositoryProvider).list();
});

final mikrotikRoutersProvider =
    FutureProvider.autoDispose<List<NasDevice>>((ref) {
  return ref.watch(nasRepositoryProvider).list();
});

final mikrotikRouterOverviewProvider =
    FutureProvider.autoDispose.family<MikrotikRouterOverview, int>((ref, id) {
  return ref.watch(mikrotikRepositoryProvider).routerOverview(id);
});

typedef MikrotikGuidedAssistantRequest = ({int routerId, String operation});

final mikrotikGuidedAssistantProvider = FutureProvider.autoDispose
    .family<MikrotikGuidedChecklist, MikrotikGuidedAssistantRequest>(
  (ref, request) {
    return ref.watch(mikrotikRepositoryProvider).guidedAssistant(
          request.routerId,
          operation: request.operation,
        );
  },
);

final mikrotikLiveSnapshotProvider =
    FutureProvider.autoDispose.family<MikrotikLiveSnapshot, int>((ref, id) {
  return ref.watch(mikrotikRepositoryProvider).liveSnapshot(id);
});

final mikrotikRouterBackupsProvider =
    FutureProvider.autoDispose.family<MikrotikRouterBackupsPage, int>(
  (ref, id) {
    return ref.watch(mikrotikRepositoryProvider).routerBackups(id);
  },
);

class RouterOperationState {
  const RouterOperationState({
    this.busyAction = '',
    this.notice = '',
    this.error = '',
    this.lastResult,
  });

  final String busyAction;
  final String notice;
  final String error;
  final MikrotikActionResult? lastResult;

  bool get isBusy => busyAction.isNotEmpty;

  RouterOperationState copyWith({
    String? busyAction,
    String? notice,
    String? error,
    MikrotikActionResult? lastResult,
    bool clearResult = false,
  }) {
    return RouterOperationState(
      busyAction: busyAction ?? this.busyAction,
      notice: notice ?? this.notice,
      error: error ?? this.error,
      lastResult: clearResult ? null : lastResult ?? this.lastResult,
    );
  }
}

final routerOperationControllerProvider = StateNotifierProvider.autoDispose<
    RouterOperationController, RouterOperationState>((ref) {
  return RouterOperationController(ref);
});

class RouterOperationController extends StateNotifier<RouterOperationState> {
  RouterOperationController(this._ref) : super(const RouterOperationState());

  final Ref _ref;

  MikrotikRepository get _repo => _ref.read(mikrotikRepositoryProvider);

  Future<void> saveBackup(
    int routerId, {
    String name = '',
    String notes = '',
  }) {
    return _run(
      routerId,
      'backup_save',
      () => _repo.saveRouterBackup(routerId, name: name, notes: notes),
    );
  }

  Future<void> reboot(
    int routerId, {
    String reason = '',
  }) {
    return _run(
      routerId,
      'reboot',
      () => _repo.rebootRouter(routerId, reason: reason),
    );
  }

  Future<void> setIdentity(
    int routerId, {
    required String name,
    String reason = '',
  }) {
    return _run(
      routerId,
      'identity',
      () => _repo.setRouterIdentity(routerId, name: name, reason: reason),
    );
  }

  Future<void> syncNtp(int routerId) {
    return _run(routerId, 'ntp', () => _repo.syncRouterNtp(routerId));
  }

  Future<void> flushDns(int routerId) {
    return _run(routerId, 'dns', () => _repo.flushRouterDnsCache(routerId));
  }

  Future<void> restoreBackup(
    int routerId,
    int backupId, {
    String notes = '',
  }) {
    return _run(
      routerId,
      'restore_$backupId',
      () => _repo.restoreRouterBackup(routerId, backupId, notes: notes),
    );
  }

  Future<void> deleteBackup(int routerId, int backupId) {
    return _run(
      routerId,
      'delete_$backupId',
      () => _repo.deleteRouterBackup(routerId, backupId),
    );
  }

  void clearMessage() {
    state = state.copyWith(notice: '', error: '', clearResult: true);
  }

  Future<void> _run(
    int routerId,
    String action,
    Future<MikrotikActionResult> Function() task,
  ) async {
    state = RouterOperationState(busyAction: action);
    try {
      final result = await task();
      state = RouterOperationState(
        notice: result.visibleMessage,
        lastResult: result,
      );
      _refreshRouter(routerId);
    } catch (error) {
      state = RouterOperationState(error: error.toString());
    }
  }

  void _refreshRouter(int routerId) {
    _ref.invalidate(mikrotikRouterOverviewProvider(routerId));
    _ref.invalidate(mikrotikLiveSnapshotProvider(routerId));
    _ref.invalidate(mikrotikRouterBackupsProvider(routerId));
  }
}
