import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoint_storage.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/visible_error_message.dart';
import '../data/subscriber_portal_repository.dart';
import '../domain/subscriber_portal_model.dart';

class SubscriberPortalState {
  const SubscriberPortalState({
    this.token = '',
    this.tenantId = 1,
    this.subscriber,
    this.capabilities = SubscriberPortalCapabilities.empty,
    this.dashboard,
    this.requests = const [],
    this.loading = false,
    this.refreshing = false,
    this.sendingLoan = false,
    this.sendingRenewal = false,
    this.error = '',
    this.notice = '',
  });

  final String token;
  final int tenantId;
  final SubscriberPortalSubscriber? subscriber;
  final SubscriberPortalCapabilities capabilities;
  final SubscriberPortalDashboard? dashboard;
  final List<SubscriberPortalRequest> requests;
  final bool loading;
  final bool refreshing;
  final bool sendingLoan;
  final bool sendingRenewal;
  final String error;
  final String notice;

  bool get isAuthenticated => token.trim().isNotEmpty && subscriber != null;

  SubscriberPortalState copyWith({
    String? token,
    int? tenantId,
    SubscriberPortalSubscriber? subscriber,
    bool clearSubscriber = false,
    SubscriberPortalCapabilities? capabilities,
    SubscriberPortalDashboard? dashboard,
    bool clearDashboard = false,
    List<SubscriberPortalRequest>? requests,
    bool? loading,
    bool? refreshing,
    bool? sendingLoan,
    bool? sendingRenewal,
    String? error,
    String? notice,
  }) {
    return SubscriberPortalState(
      token: token ?? this.token,
      tenantId: tenantId ?? this.tenantId,
      subscriber: clearSubscriber ? null : (subscriber ?? this.subscriber),
      capabilities: capabilities ?? this.capabilities,
      dashboard: clearDashboard ? null : (dashboard ?? this.dashboard),
      requests: requests ?? this.requests,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      sendingLoan: sendingLoan ?? this.sendingLoan,
      sendingRenewal: sendingRenewal ?? this.sendingRenewal,
      error: error ?? this.error,
      notice: notice ?? this.notice,
    );
  }
}

class SubscriberPortalController extends StateNotifier<SubscriberPortalState> {
  SubscriberPortalController(this._repo) : super(const SubscriberPortalState());

  final SubscriberPortalRepository _repo;

  Future<void> login({
    required String scheme,
    required String host,
    required String username,
    required String password,
    int tenantId = 1,
  }) async {
    state = state.copyWith(
      loading: true,
      tenantId: tenantId,
      error: '',
      notice: '',
      clearDashboard: true,
    );
    try {
      final baseUrl = normalizeApiBaseUrl(scheme: scheme, host: host);
      final result = await _repo.login(
        baseUrl: baseUrl,
        username: username,
        password: password,
        tenantId: tenantId,
      );
      if (result.token.isEmpty) {
        throw ApiException(
          code: 'token_required',
          message: 'تعذر فتح جلسة بوابة المشترك. حاول مرة أخرى.',
        );
      }
      state = state.copyWith(
        token: result.token,
        subscriber: result.subscriber,
        capabilities: result.capabilities,
        loading: false,
        notice: 'تم تسجيل الدخول إلى بوابة المشترك.',
      );
      await refresh(silent: true);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: visibleErrorMessage(error),
      );
    }
  }

  Future<void> refresh({bool silent = false}) async {
    final token = state.token;
    if (token.isEmpty) return;
    state = state.copyWith(
      refreshing: !silent,
      error: '',
      notice: silent ? state.notice : '',
    );
    try {
      final profile = await _repo.me(token: token, tenantId: state.tenantId);
      final dashboard = profile.capabilities.dashboard
          ? await _repo.dashboard(token: token, tenantId: state.tenantId)
          : null;
      final requests = profile.capabilities.requests
          ? await _repo.requests(token: token, tenantId: state.tenantId)
          : const <SubscriberPortalRequest>[];
      state = state.copyWith(
        subscriber: profile.subscriber,
        capabilities: profile.capabilities,
        dashboard: dashboard,
        requests: requests,
        refreshing: false,
      );
    } catch (error) {
      state = state.copyWith(
        refreshing: false,
        error: visibleErrorMessage(error),
      );
    }
  }

  Future<void> submitLoan({
    required int requestedMinutes,
    required String reason,
  }) async {
    if (state.token.isEmpty || state.sendingLoan) return;
    state = state.copyWith(sendingLoan: true, error: '', notice: '');
    try {
      final request = await _repo.loanRequest(
        token: state.token,
        tenantId: state.tenantId,
        requestedMinutes: requestedMinutes,
        reason: reason,
      );
      state = state.copyWith(
        sendingLoan: false,
        notice: 'تم تسجيل طلب السلفة: ${request.statusLabel}.',
      );
      await refresh(silent: true);
    } catch (error) {
      state = state.copyWith(
        sendingLoan: false,
        error: visibleErrorMessage(error),
      );
    }
  }

  Future<void> submitRenewal({required String reason}) async {
    if (state.token.isEmpty || state.sendingRenewal) return;
    state = state.copyWith(sendingRenewal: true, error: '', notice: '');
    try {
      final request = await _repo.renewalRequest(
        token: state.token,
        tenantId: state.tenantId,
        reason: reason,
      );
      state = state.copyWith(
        sendingRenewal: false,
        notice: 'تم تسجيل الطلب: ${request.statusLabel}.',
      );
      await refresh(silent: true);
    } catch (error) {
      state = state.copyWith(
        sendingRenewal: false,
        error: visibleErrorMessage(error),
      );
    }
  }

  Future<void> logout() async {
    final token = state.token;
    final tenantId = state.tenantId;
    state = const SubscriberPortalState();
    if (token.isEmpty) return;
    try {
      await _repo.logout(token: token, tenantId: tenantId);
    } catch (_) {
      // The local portal session is already cleared. Server-side revocation
      // will expire automatically if the network is unavailable.
    }
  }

  void clearMessages() {
    state = state.copyWith(error: '', notice: '');
  }
}

final subscriberPortalControllerProvider = StateNotifierProvider<
    SubscriberPortalController, SubscriberPortalState>((ref) {
  return SubscriberPortalController(
    ref.watch(subscriberPortalRepositoryProvider),
  );
});
