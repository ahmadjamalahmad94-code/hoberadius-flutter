import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';

import '../data/admin_control_repository.dart';
import '../domain/admin_control_model.dart';
import 'admin_control_providers.dart';

/// Result of an action: `error == null` means success.
class AdminActionResult {
  const AdminActionResult({this.error});
  final String? error;
  bool get ok => error == null;
}

class AdminControlState {
  const AdminControlState({this.busy = false});
  final bool busy;
  AdminControlState copyWith({bool? busy}) =>
      AdminControlState(busy: busy ?? this.busy);
}

class AdminControlController extends Notifier<AdminControlState> {
  @override
  AdminControlState build() => const AdminControlState();

  Future<AdminActionResult> updateSetting(String key, String value) async {
    return _run(() async {
      await ref.read(adminControlRepositoryProvider).updateSetting(key, value);
      ref.invalidate(settingsProvider);
    });
  }

  Future<AdminActionResult> createTenant(TenantRecord tenant) async {
    return _run(() async {
      await ref.read(adminControlRepositoryProvider).createTenant(tenant);
      ref.invalidate(tenantsProvider);
    });
  }

  Future<AdminActionResult> updateTenant(TenantRecord tenant) async {
    return _run(() async {
      await ref.read(adminControlRepositoryProvider).updateTenant(tenant);
      ref.invalidate(tenantsProvider);
    });
  }

  void refreshAll() {
    ref.invalidate(settingsProvider);
    ref.invalidate(tenantsProvider);
  }

  Future<AdminActionResult> _run(Future<void> Function() action) async {
    state = state.copyWith(busy: true);
    try {
      await action();
      return const AdminActionResult();
    } catch (e) {
      return AdminActionResult(error: visibleErrorMessage(e));
    } finally {
      state = state.copyWith(busy: false);
    }
  }
}

final adminControlControllerProvider =
    NotifierProvider<AdminControlController, AdminControlState>(
  AdminControlController.new,
);
