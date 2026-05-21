import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_control_repository.dart';
import '../domain/admin_control_model.dart';
import 'admin_control_providers.dart';

/// Result of an action: `error == null` means success.
class AdminActionResult {
  const AdminActionResult({this.error});
  final String? error;
  bool get ok => error == null;
}

/// Result of token creation — includes the one-shot token text the
/// caller should immediately surface to the operator.
class CreateTokenResult {
  const CreateTokenResult({this.token, this.error});
  final ApiTokenRecord? token;
  final String? error;
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

  Future<CreateTokenResult> createToken(String name) async {
    state = state.copyWith(busy: true);
    try {
      final token = await ref
          .read(adminControlRepositoryProvider)
          .createToken(name);
      ref.invalidate(apiTokensProvider);
      return CreateTokenResult(token: token);
    } catch (e) {
      return CreateTokenResult(error: '$e');
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<AdminActionResult> revokeToken(int tokenId) async {
    return _run(() async {
      await ref.read(adminControlRepositoryProvider).revokeToken(tokenId);
      ref.invalidate(apiTokensProvider);
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

  Future<AdminActionResult> saveWebhookConfig({
    required String targetUrl,
    required String secret,
    required List<String> events,
  }) async {
    return _run(() async {
      await ref.read(adminControlRepositoryProvider).updateWebhookConfig(
            targetUrl: targetUrl,
            secret: secret,
            enabledEvents: events,
          );
      ref.invalidate(webhookConfigProvider);
    });
  }

  Future<AdminActionResult> testWebhook(String currentStatus) async {
    return _run(() async {
      await ref.read(adminControlRepositoryProvider).testWebhook();
      ref.invalidate(webhookConfigProvider);
      ref.invalidate(webhookDeliveriesProvider(currentStatus));
    });
  }

  void refreshAll(String currentStatus) {
    ref.invalidate(settingsProvider);
    ref.invalidate(apiTokensProvider);
    ref.invalidate(tenantsProvider);
    ref.invalidate(webhookConfigProvider);
    ref.invalidate(webhookDeliveriesProvider(currentStatus));
  }

  Future<AdminActionResult> _run(Future<void> Function() action) async {
    state = state.copyWith(busy: true);
    try {
      await action();
      return const AdminActionResult();
    } catch (e) {
      return AdminActionResult(error: '$e');
    } finally {
      state = state.copyWith(busy: false);
    }
  }
}

final adminControlControllerProvider =
    NotifierProvider<AdminControlController, AdminControlState>(
  AdminControlController.new,
);
