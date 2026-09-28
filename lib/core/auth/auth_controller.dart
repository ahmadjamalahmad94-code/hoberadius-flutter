import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/push/push_service.dart';
import '../api/api_client.dart';
import '../api/api_endpoint_storage.dart';
import '../api/api_exception.dart';
import '../format/currency.dart';
import 'security_key_storage.dart';
import 'token_storage.dart';

class AuthAdmin {
  AuthAdmin({
    required this.id,
    required this.username,
    this.fullName = '',
    this.email = '',
    this.isSuperAdmin = false,
    this.avatarUrl = '',
  });

  final int id;
  final String username;
  final String fullName;
  final String email;
  final bool isSuperAdmin;
  final String avatarUrl;

  factory AuthAdmin.fromJson(Map<String, dynamic> j) => AuthAdmin(
        id: (j['id'] as int?) ?? 0,
        username: (j['username'] ?? '').toString(),
        fullName: (j['full_name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        isSuperAdmin: j['is_super_admin'] == true,
        avatarUrl: (j['avatar_url'] ?? '').toString(),
      );
}

class AuthState {
  const AuthState({
    this.token,
    this.admin,
    this.tenantId,
    this.permissions = const [],
    this.serverBaseUrl,
    this.loading = false,
    this.error,
    this.systemCurrency = '',
  });

  /// `data.system.currency` of /api/admin/me or the login answer — the
  /// tenant's effective currency (empty on older servers).
  final String systemCurrency;

  final String? token;
  final AuthAdmin? admin;
  final int? tenantId;
  final List<String> permissions;
  final String? serverBaseUrl;
  final bool loading;
  final String? error;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    AuthAdmin? admin,
    int? tenantId,
    List<String>? permissions,
    String? serverBaseUrl,
    bool? loading,
    String? error,
    bool clear = false,
    bool clearError = false,
    String? systemCurrency,
  }) =>
      clear
          ? const AuthState()
          : AuthState(
              token: token ?? this.token,
              admin: admin ?? this.admin,
              tenantId: tenantId ?? this.tenantId,
              permissions: permissions ?? this.permissions,
              serverBaseUrl: serverBaseUrl ?? this.serverBaseUrl,
              loading: loading ?? this.loading,
              error: clearError ? null : (error ?? this.error),
              systemCurrency: systemCurrency ?? this.systemCurrency,
            );
}

/// `system.currency` of an /api/admin/me or login payload ('' if absent).
String systemCurrencyOf(Map<String, dynamic> data) {
  final system = data['system'];
  if (system is! Map) return '';
  return '${system['currency'] ?? ''}'.trim().toUpperCase();
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _ref.listen<ApiClient>(
      apiClientProvider,
      (_, client) => client.onUnauthorized = _onUnauthorized,
      fireImmediately: true,
    );
    _restore();
  }

  /// A 401 on any authenticated call: the token is dead (revoked by a
  /// password change elsewhere, admin disabled, expired). Sign out cleanly —
  /// the router sends the user to the login screen, which shows why.
  Future<void> _onUnauthorized(ApiException e) async {
    if (!state.isAuthenticated || state.loading) return;
    final serverBaseUrl = state.serverBaseUrl;
    await _ref.read(tokenStorageProvider).clear();
    final msg = e.message.trim();
    state = AuthState(
      serverBaseUrl: serverBaseUrl,
      error: msg.isEmpty
          ? 'انتهت الجلسة. سجّل الدخول مرة أخرى.'
          : '$msg${msg.contains('سجّل الدخول') ? '' : ' سجّل الدخول مرة أخرى.'}',
    );
  }

  final Ref _ref;

  void _publishCurrency(String code) {
    try {
      _ref.read(sessionCurrencyProvider.notifier).state = code;
    } catch (_) {/* container disposed */}
  }

  Future<void> _restore() async {
    final stored = await _ref.read(tokenStorageProvider).read();
    final serverBaseUrl =
        await _ref.read(apiEndpointStorageProvider).readBaseUrl();
    if (stored == null || stored.isEmpty) {
      state = AuthState(serverBaseUrl: serverBaseUrl);
      return;
    }
    state = state.copyWith(
      token: stored,
      serverBaseUrl: serverBaseUrl,
      loading: true,
    );
    try {
      final res = await _ref.read(apiClientProvider).get('/api/admin/me');
      final d = (res['data'] ?? {}) as Map<String, dynamic>;
      state = AuthState(
        token: stored,
        admin: d['admin'] is Map<String, dynamic>
            ? AuthAdmin.fromJson(d['admin'] as Map<String, dynamic>)
            : null,
        tenantId: d['tenant_id'] as int?,
        permissions: ((d['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        serverBaseUrl: serverBaseUrl,
        systemCurrency: systemCurrencyOf(d),
      );
      _publishCurrency(state.systemCurrency);
    } on ApiException {
      await _ref.read(tokenStorageProvider).clear();
      state = AuthState(serverBaseUrl: serverBaseUrl);
    } catch (_) {
      // Network glitch: keep the token so the next refresh can recover.
      state = state.copyWith(loading: false);
    }
  }

  Future<void> login({
    required String baseUrl,
    required String username,
    required String password,
    String securityKey = '',
  }) async {
    state = state.copyWith(
      loading: true,
      serverBaseUrl: baseUrl,
      clearError: true,
    );
    try {
      await _ref.read(tokenStorageProvider).clear();
      await _ref.read(apiEndpointStorageProvider).writeBaseUrl(baseUrl);
      // Persist the per-deployment security key BEFORE the login call so the
      // request itself carries `X-API-Key` (a gateway in front of Flask may
      // require it even on the public login route). Empty clears any stale key.
      final secStore = _ref.read(securityKeyStorageProvider);
      final trimmedKey = securityKey.trim();
      if (trimmedKey.isEmpty) {
        await secStore.clear();
      } else {
        await secStore.write(trimmedKey);
      }
      final res = await _ref.read(apiClientProvider).post(
        '/api/admin/login',
        body: {'username': username, 'password': password},
      );
      final d = (res['data'] ?? {}) as Map<String, dynamic>;
      final token = (d['token'] ?? '').toString();
      if (token.isEmpty) {
        throw ApiException(
          code: 'empty_token',
          message: 'استجابة تسجيل الدخول غير مكتملة.',
        );
      }
      await _ref.read(tokenStorageProvider).write(token);
      state = AuthState(
        token: token,
        admin: d['admin'] is Map<String, dynamic>
            ? AuthAdmin.fromJson(d['admin'] as Map<String, dynamic>)
            : null,
        tenantId: d['tenant_id'] as int?,
        permissions: ((d['permissions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        serverBaseUrl: baseUrl,
        systemCurrency: systemCurrencyOf(d),
      );
      _publishCurrency(state.systemCurrency);
    } on ApiException catch (e) {
      state = AuthState(serverBaseUrl: baseUrl, error: e.message);
    } catch (_) {
      state = AuthState(
        serverBaseUrl: baseUrl,
        error: 'تعذّر الاتصال بالخادم. تأكد من العنوان والبروتوكول.',
      );
    }
  }

  Future<void> logout() async {
    // Unregister this device's push token before clearing the session so the
    // signed-out device stops receiving pushes (no-op off mobile).
    try {
      await _ref.read(pushServiceProvider).onLogout(_ref);
    } catch (_) {/* best-effort */}
    try {
      await _ref.read(apiClientProvider).post('/api/admin/logout');
    } catch (_) {/* best-effort */}
    await _ref.read(tokenStorageProvider).clear();
    final serverBaseUrl =
        await _ref.read(apiEndpointStorageProvider).readBaseUrl();
    state = AuthState(serverBaseUrl: serverBaseUrl);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
